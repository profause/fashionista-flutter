import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';

class DiscoverTrendsScreen extends StatefulWidget {
  const DiscoverTrendsScreen({super.key});

  @override
  State<DiscoverTrendsScreen> createState() => _DiscoverTrendsScreenState();
}

class _DiscoverTrendsScreenState extends State<DiscoverTrendsScreen> {
  final ValueNotifier<List<String>> selectedInterestsNotifier =
      ValueNotifier<List<String>>([]);
  bool loadingFashionInterests = true;

  @override
  void initState() {
    _loadFashionInterests();
    super.initState();
  }

  @override
  void dispose() {
    selectedInterestsNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(top: 2),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              color: colorScheme.onPrimary,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text("Get started", style: textTheme.labelLarge),
                      const Spacer(),
                      Text("Skip", style: textTheme.bodySmall),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        value: 0.4,
                        strokeWidth: 3,
                        backgroundColor: colorScheme.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation(colorScheme.primary),
                      ),
                    ),
                    title: Text('Like 10 posts', style: textTheme.labelLarge),
                    subtitle: Text(
                      'Teach our algorithms what you like',
                      style: textTheme.bodyMedium,
                    ),
                  ),
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        value: 0.6,
                        strokeWidth: 3,
                        backgroundColor: colorScheme.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation(colorScheme.primary),
                      ),
                    ),
                    title: Text(
                      'Follow designers',
                      style: textTheme.labelLarge,
                    ),
                    subtitle: Text(
                      'Follow designers to view their work',
                      style: textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 2),

            // 👇 This part now uses ValueListenableBuilder
            Container(
              padding: const EdgeInsets.all(16),
              color: colorScheme.onPrimary,
              child: ValueListenableBuilder<List<String>>(
                valueListenable: selectedInterestsNotifier,
                builder: (context, selectedInterests, _) {
                  if (loadingFashionInterests) {
                    return const Center(
                      child: SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  }

                  if (selectedInterests.isEmpty) {
                    return Text(
                      "No interests found",
                      style: textTheme.bodyMedium,
                    );
                  }

                  return SizedBox(
                    height: 40,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: selectedInterests.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final item = selectedInterests[index];
                        return ActionChip(
                          backgroundColor: Colors.transparent,
                          label: Text(item),
                          onPressed: () {
                            debugPrint("Selected: $item");
                          },
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadFashionInterests() async {
    final user = firebase_auth.FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final querySnapshot = await FirebaseFirestore.instance
        .collection('fashion_interests')
        .orderBy('category')
        .get();

    final interests = querySnapshot.docs
        .map((item) => item.data()['name'] as String)
        .toList();

    selectedInterestsNotifier.value = interests;
    loadingFashionInterests = false;
  }
}
