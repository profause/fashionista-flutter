import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fashionista/core/service_locator/service_locator.dart';
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        foregroundColor: colorScheme.primary,
        backgroundColor: colorScheme.onPrimary,
        title: Text(
          'Select Your Fashion Interests',
          style: textTheme.titleLarge!.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
      body: FutureBuilder<Map<String, List<String>>>(
        future: fetchInterests(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No interests available"));
          }

          final interestsByCategory = snapshot.data!;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: interestsByCategory.entries.map((entry) {
              final category = entry.key;
              final interests = entry.value;

              return Column(
                key: ValueKey(category),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: interests.map((interest) {
                      return ValueListenableBuilder<Set<String>>(
                        valueListenable: selectedInterestsNotifier,
                        builder: (context, selectedInterests, _) {
                          final isSelected = selectedInterests.contains(
                            interest,
                          );
                          return ChoiceChip(
                            key: ValueKey(interest),
                            label: Text(interest),
                            selected: isSelected,
                            onSelected: (selected) =>
                                _toggleInterest(interest, selected),
                          );
                        },
                      );
                    }).toList(),
                  ),
                  Divider(
                    height: 32,
                    thickness: 1,
                    color: Colors.grey[300]!.withValues(alpha: 0.5),
                  ),
                ],
              );
            }).toList(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saveInterests,
        icon: const Icon(Icons.check),
        label: const Text("Done"),
      ),
    );
  }

  Future<void> _saveInterests() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("You must be logged in to save interests."),
        ),
      );
      return;
    }

    // await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
    //   {
    //     'interests': selectedInterests.toList(),
    //     //'updated_at': FieldValue.serverTimestamp(),
    //   },
    //   SetOptions(merge: true), // keep other user data
    // );

    final currentUser = context.read<UserBloc>().state;
    final selected = Set<String>.from(selectedInterestsNotifier.value);

    final updatedUser = currentUser.copyWith(interests: selected.toList());

    context.read<UserBloc>().add(UpdateUser(updatedUser));

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
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("✅ Interests saved successfully")),
          );

          if (widget.fromWhere!.contains('UserProfilePage')) {
            context.pop();
          } else {
            context.go('/home');
          }
        }
      },
    );

    //Navigator.pop(context); // close the screen
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
    //setState(() => _loadingUserInterests = false);
  }

  @override
  void initState() {
    super.initState();
    _loadUserInterests();
  }
}
