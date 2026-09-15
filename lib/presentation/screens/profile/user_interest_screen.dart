import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/core/theme/app.theme.dart';
import 'package:fashionista/core/widgets/bloc/getstarted_stats_cubit.dart';
import 'package:fashionista/data/models/profile/bloc/user_bloc.dart';
import 'package:fashionista/domain/usecases/profile/update_user_profile_usecase.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class UserInterestScreen extends StatefulWidget {
  final String? fromWhere;
  const UserInterestScreen({super.key, this.fromWhere});

  @override
  State<UserInterestScreen> createState() => _UserInterestScreenState();
}

class _UserInterestScreenState extends State<UserInterestScreen> {
  final ValueNotifier<Set<String>> selectedInterestsNotifier = ValueNotifier(
    {},
  );
  final int maxSelection = 8;

  /// Fetch interests grouped by category
  Future<Map<String, List<String>>> fetchInterests() async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('fashion_interests')
        .orderBy('category')
        .get();

    final Map<String, List<String>> grouped = {};

    for (var doc in querySnapshot.docs) {
      final data = doc.data();
      final category = data['category'] as String;
      final name = data['name'] as String;

      grouped.putIfAbsent(category, () => []);
      grouped[category]!.add(name);
    }

    return grouped;
  }

  void _toggleInterest(String interest, bool isSelected) {
    final selected = Set<String>.from(selectedInterestsNotifier.value);

    if (isSelected) {
      if (selected.length < maxSelection) {
        selected.add(interest);
      } else {
        _showMaxSelectionWarning();
      }
    } else {
      selected.remove(interest);
    }

    selectedInterestsNotifier.value = selected;
  }

  void _showMaxSelectionWarning() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("You can only select up to $maxSelection interests."),
      ),
    );
  }

  void _exit() {
    if (widget.fromWhere?.contains('UserProfilePage') ?? false) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.canvasBackground,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: context.canvasBackground,
        foregroundColor: context.onCanvasText,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: const SizedBox(
          width: 40,
          height: 40,
          child: _BackButton(),
        ),
        title: Text(
          'Select Your Interests',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: context.onCanvasText,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          Center(
            child: TextButton(
              onPressed: _exit,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                foregroundColor: context.mutedText,
                textStyle: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: context.mutedText,
                ),
              ),
              child: const Text('Skip'),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: ColoredBox(color: context.hairline),
        ),
      ),
      body: FutureBuilder<Map<String, List<String>>>(
        future: fetchInterests(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No interests available'));
          }

          final interestsByCategory = snapshot.data!;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  'Choose at least 3 categories to personalize your fashion feed, designer drops, and outfit recommendations.',
                  style: TextStyle(
                    fontSize: 13,
                    color: context.mutedText,
                    height: 1.6,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              for (final item in interestsByCategory.entries.indexed) ...[
                _buildCategorySection(item.$1, item.$2.key, item.$2.value),
              ],
            ],
          );
        },
      ),
      bottomNavigationBar: _InterestCtaButton(
        onPressed: _saveInterests,
      ),
    );
  }

  Widget _buildCategorySection(
    int index,
    String category,
    List<String> interests,
  ) {
    return Column(
      key: ValueKey(category),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (index > 0) ...[
          const SizedBox(height: 20),
          const Divider(height: 1, thickness: 1),
          const SizedBox(height: 20),
        ],
        Text(
          category,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: context.onCanvasText,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: interests.map((interest) {
            return ValueListenableBuilder<Set<String>>(
              valueListenable: selectedInterestsNotifier,
              builder: (context, selectedInterests, _) {
                final isSelected = selectedInterests.contains(interest);
                return _InterestChip(
                  label: interest,
                  selected: isSelected,
                  onTap: () => _toggleInterest(interest, !isSelected),
                );
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Future<void> _saveInterests() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must be logged in to save interests.'),
        ),
      );
      return;
    }

    final currentUser = context.read<UserBloc>().state;
    final selected = Set<String>.from(selectedInterestsNotifier.value);

    final updatedUser = currentUser.copyWith(interests: selected.toList());

    context.read<UserBloc>().add(UpdateUser(updatedUser));

    final userInterestCount = selected.length;
    final cubit = context.read<GetstartedStatsCubit>();
    cubit.updateInterests(userInterestCount);

    //sync with firestore
    final updateUserResult = await sl<UpdateUserProfileUsecase>().call(
      updatedUser,
    );

    updateUserResult.fold(
      (ifLeft) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(ifLeft)));
        }
      },
      (ifRight) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Interests saved successfully')),
          );

          if (widget.fromWhere?.contains('UserProfilePage') ?? false) {
            context.pop();
          } else {
            context.go('/home');
          }
        }
      },
    );
  }

  /// Load previously saved interests from Firestore
  Future<void> _loadUserInterests() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (doc.exists) {
      final data = doc.data();
      final List<dynamic>? interests = data?['interests'];
      if (interests != null) {
        final selected = Set<String>.from(selectedInterestsNotifier.value);
        selected.addAll(interests.cast<String>());
        selectedInterestsNotifier.value = selected;
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _loadUserInterests();
  }
}

class _InterestChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _InterestChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: selected ? context.accent : context.cardSurface,
            borderRadius: BorderRadius.circular(18),
            border: selected
                ? null
                : Border.all(color: context.hairline),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                Icon(
                  Icons.check,
                  size: 14,
                  color: Colors.white,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: selected
                      ? Colors.white
                      : context.mutedText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InterestCtaButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _InterestCtaButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  context.canvasBackground.withValues(alpha: 0),
                  context.canvasBackground,
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: context.accent.withValues(alpha: 0.28),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: SizedBox(
                height: 54,
                width: double.infinity,
                child: FilledButton(
                  onPressed: onPressed,
                  style: FilledButton.styleFrom(
                    backgroundColor: context.accent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Done'),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward, size: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton();

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.chevron_left, size: 24, color: context.onCanvasText),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      onPressed: () {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      },
    );
  }
}