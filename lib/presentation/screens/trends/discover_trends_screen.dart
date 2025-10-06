import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/data/models/designers/designer_model.dart';
import 'package:fashionista/data/models/trends/bloc/trend_bloc.dart';
import 'package:fashionista/data/models/trends/bloc/trend_bloc_event.dart';
import 'package:fashionista/data/models/trends/bloc/trend_bloc_state.dart';
import 'package:fashionista/data/services/firebase/firebase_designers_service.dart';
import 'package:fashionista/presentation/screens/designers/widgets/designer_info_card_widget_discover_page.dart';
import 'package:fashionista/presentation/screens/trends/widgets/trend_info_card_widget.dart';
import 'package:fashionista/presentation/screens/trends/widgets/trend_info_card_widget_discover_page.dart';
import 'package:fashionista/presentation/screens/trends/widgets/trends_staggered_view.dart';
import 'package:fashionista/presentation/widgets/page_empty_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DiscoverTrendsScreen extends StatefulWidget {
  const DiscoverTrendsScreen({super.key});

  @override
  State<DiscoverTrendsScreen> createState() => _DiscoverTrendsScreenState();
}

class _DiscoverTrendsScreenState extends State<DiscoverTrendsScreen> {
  final ValueNotifier<List<String>> selectedInterestsNotifier =
      ValueNotifier<List<String>>([]);
  bool loadingFashionInterests = true;

  final ValueNotifier<List<Designer>> designersNotifier =
      ValueNotifier<List<Designer>>([]);
  bool loadingFashionDesigners = true;

  @override
  void initState() {
    _loadFashionInterests();
    _loadFashionDesigners();
    _loadFashionTrends();
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
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
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

            const SizedBox(height: 2),

            // 👇 This part now uses ValueListenableBuilder
            ValueListenableBuilder<List<Designer>>(
              valueListenable: designersNotifier,
              builder: (context, designers, _) {
                if (loadingFashionDesigners) {
                  return const Center(
                    child: SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                }

                if (designers.isEmpty) {
                  return Text(
                    "No designers found",
                    style: textTheme.bodyMedium,
                  );
                }

                return SizedBox(
                  height: 240,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    scrollDirection: Axis.horizontal,
                    itemCount: designers.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final item = designers[index];
                      return DesignerInfoCardWidgetDiscoverPage(
                        designerInfo: item,
                      );
                    },
                  ),
                );
              },
            ),

            const SizedBox(height: 2),

            Container(
              //padding: const EdgeInsets.only(left: 16, right: 16),
              //color: colorScheme.onPrimary,
              child: BlocBuilder<TrendBloc, TrendBlocState>(
                builder: (context, state) {
                  switch (state) {
                    case TrendLoading():
                      return const Center(
                        child: SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    case TrendsLoaded(:final trends, :final fromCache):
                      return ListView.separated(
                        padding: const EdgeInsets.all(0),
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: trends.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 2),
                        itemBuilder: (context, index) {
                          final item = trends[index];
                          return TrendInfoCardWidgetDiscoverPage(
                            trendInfo: item,
                          );
                        },
                      );
                    case TrendError(:final message):
                      debugPrint("Error: $message");
                      return SizedBox(
                        height: 400,
                        child: Center(child: Text("Error: $message")),
                      );
                    default:
                      return SizedBox(
                        height: 400,
                        child: Center(
                          child: PageEmptyWidget(
                            title: "No Trends Found",
                            subtitle: "Add new trend to see them here.",
                            icon: Icons.newspaper_outlined,
                          ),
                        ),
                      );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadFashionInterests() async {
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

  Future<void> _loadFashionDesigners() async {
    final result = await sl<FirebaseDesignersService>().findDesignersWithFilter(
      4,
      'created_date',
    );

    await result.fold((failure) async {}, (designers) {
      designersNotifier.value = designers;
      loadingFashionDesigners = false;
    });
  }

  void _loadFashionTrends() {
    context.read<TrendBloc>().add(
      const LoadTrendsCacheForDiscoverPage('discover'),
    );
  }
}
