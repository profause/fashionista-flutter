import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/core/theme/app.theme.dart';
import 'package:fashionista/core/widgets/bloc/getstarted_stats_cubit.dart';
import 'package:fashionista/data/models/designers/designer_model.dart';
import 'package:fashionista/data/models/trends/bloc/trend_bloc.dart';
import 'package:fashionista/data/models/trends/bloc/trend_bloc_event.dart';
import 'package:fashionista/data/models/trends/bloc/trend_bloc_state.dart';
import 'package:fashionista/data/services/firebase/firebase_designers_service.dart';
import 'package:fashionista/presentation/screens/designers/widgets/designer_info_card_widget_discover_page.dart';
import 'package:fashionista/presentation/screens/trends/widgets/designer_shimmer_widget.dart';
import 'package:fashionista/presentation/screens/trends/widgets/interest_shimmer_widget.dart';
import 'package:fashionista/presentation/screens/trends/widgets/trend_info_card_widget_discover_page.dart';
import 'package:fashionista/presentation/widgets/page_empty_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class ForYouPage extends StatefulWidget {
  const ForYouPage({super.key});

  @override
  State<ForYouPage> createState() => _ForYouPageState();
}

class _ForYouPageState extends State<ForYouPage> {
  final ValueNotifier<List<String>> selectedInterestsNotifier =
      ValueNotifier<List<String>>([]);
  bool loadingFashionInterests = true;

  final ValueNotifier<List<Designer>> designersNotifier =
      ValueNotifier<List<Designer>>([]);
  bool loadingFashionDesigners = true;
  late GetstartedStatsCubit _getstartedStatsCubit;

  final ValueNotifier<int> getStartedLikesNotifier = ValueNotifier<int>(0);

  late int getStartedLikes = 0;
  late int getStartedFollowings = 0;
  late int getStartedInterests = 0;
  Timer? _debounce;
  Timer? _loadInterestsDebounce; // 👈 debounce timer

  @override
  void initState() {
    _loadGetStartedStats();
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
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(16),
              color: colorScheme.onPrimary,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text("Get started", style: textTheme.labelLarge),
                      const Spacer(),
                      TextButton(
                        onPressed: () {},
                        child: Text('Skip', style: textTheme.bodyMedium),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: SizedBox(
                      width: 18,
                      height: 18,
                      child: ValueListenableBuilder<int>(
                        valueListenable: getStartedLikesNotifier,
                        builder: (context, likes, _) {
                          return CircularProgressIndicator(
                            value: (likes / 10),
                            strokeWidth: 3,
                            backgroundColor: AppTheme.appIconColor.withValues(
                              alpha: .1,
                            ),
                            valueColor: AlwaysStoppedAnimation(
                              AppTheme.appIconColor.withValues(alpha: 1),
                            ),
                          );
                        },
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
                      child:
                          BlocSelector<
                            GetstartedStatsCubit,
                            Map<String, int>,
                            int
                          >(
                            selector: (state) => state['followings'] ?? 0,
                            builder: (context, followings) {
                              return CircularProgressIndicator(
                                value: (followings / 10),
                                strokeWidth: 3,
                                backgroundColor: AppTheme.appIconColor
                                    .withValues(alpha: .1),
                                valueColor: AlwaysStoppedAnimation(
                                  AppTheme.appIconColor.withValues(alpha: 1),
                                ),
                              );
                            },
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
          ),
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(16),
              //color: colorScheme.onPrimary,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Interests', style: textTheme.labelLarge),
                      TextButton(
                        onPressed: () {
                          final uri = Uri(
                            path: '/user-interests',
                            queryParameters: {'fromwhere': 'ForYouPage'},
                          );
                          context.push(uri.toString());
                        },
                        child: Text('More', style: textTheme.bodyMedium),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ValueListenableBuilder<List<String>>(
                    valueListenable: selectedInterestsNotifier,
                    builder: (context, selectedInterests, _) {
                      if (loadingFashionInterests) {
                        return SizedBox(
                          height: 40,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: 6, // number of shimmer placeholders
                            separatorBuilder: (_, _) =>
                                const SizedBox(width: 8),
                            itemBuilder: (_, __) {
                              final randomWidth =
                                  70 + (30 * (__ % 3)); // variable chip widths
                              return InterestShimmerWidget(
                                width: randomWidth.toDouble(),
                              );
                            },
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
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Designers', style: textTheme.labelLarge),
                      TextButton(
                        onPressed: () {
                          final uri = Uri(path: '/designers');
                          context.push(uri.toString());
                        },
                        child: Text('More', style: textTheme.bodyMedium),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // 👇 This part now uses ValueListenableBuilder
                  ValueListenableBuilder<List<Designer>>(
                    valueListenable: designersNotifier,
                    builder: (context, designers, _) {
                      if (loadingFashionDesigners) {
                        return SizedBox(
                          height: 240,
                          child: ListView.separated(
                            //padding: const EdgeInsets.all(16),
                            scrollDirection: Axis.horizontal,
                            itemCount: 6, // number of shimmer placeholders
                            separatorBuilder: (_, _) =>
                                const SizedBox(width: 8),
                            itemBuilder: (_, _) {
                              // variable chip widths
                              return DesignerShimmerWidget();
                            },
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
                        height: 220,
                        child: ListView.separated(
                          padding: const EdgeInsets.only(bottom: 8),
                          scrollDirection: Axis.horizontal,
                          itemCount: designers.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final item = designers[index];
                            return DesignerInfoCardWidgetDiscoverPage(
                              key: ValueKey(index),
                              designerInfo: item,
                              onFollowTap: (bool isFollowing) {
                                //here
                                final cubit = context
                                    .read<GetstartedStatsCubit>();
                                final currentFollowings =
                                    cubit.state['followings'] ?? 0;
                                final newFollowings = isFollowing
                                    ? currentFollowings + 1
                                    : (currentFollowings > 0
                                          ? currentFollowings - 1
                                          : 0);

                                cubit.updateFollowings(newFollowings);
                              },
                            );
                          },
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 16.0, bottom: 8),
                  child: Text('My Posts', style: textTheme.labelLarge),
                ),
                const SizedBox(height: 4),
                BlocBuilder<TrendBloc, TrendBlocState>(
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
                      case TrendsLoaded(:final trends):
                        return ListView.separated(
                          padding: const EdgeInsets.all(0),
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: trends.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 2),
                          itemBuilder: (context, index) {
                            final item = trends[index];
                            return TrendInfoCardWidgetDiscoverPage(
                              trendInfo: item,
                              onLikeTap: (bool isLiked) {},
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadFashionInterests() async {
    _loadInterestsDebounce?.cancel(); // cancel previous timer
    _loadInterestsDebounce = Timer(
      const Duration(milliseconds: 1500),
      () async {
        final querySnapshot = await FirebaseFirestore.instance
            .collection('fashion_interests')
            .orderBy('category')
            .get();

        final interests = querySnapshot.docs
            .map((item) => item.data()['name'] as String)
            .toList();

        selectedInterestsNotifier.value = interests;
        loadingFashionInterests = false;
      },
    );
  }

  Future<void> _loadFashionDesigners() async {
    _debounce?.cancel(); // cancel previous timer
    _debounce = Timer(const Duration(milliseconds: 1500), () async {
      final result = await sl<FirebaseDesignersService>()
          .findDesignersWithFilter(4, 'created_date');

      await result.fold((failure) async {}, (designers) {
        designersNotifier.value = designers;
        final following = designers
            .where((d) => d.isFavourite!)
            .toList()
            .length;
        final cubit = context.read<GetstartedStatsCubit>();
        cubit.updateFollowings(following);
        loadingFashionDesigners = false;
      });
    });
  }

  void _loadFashionTrends() {
    context.read<TrendBloc>().add(const LoadTrendsCacheFirst(limit: 10));
    // context.read<TrendBloc>().add(
    //   const LoadTrendsCacheForDiscoverPage('discover'),
    // );
  }

  void _loadGetStartedStats() {
    _getstartedStatsCubit = context.read<GetstartedStatsCubit>();
    final likes = _getstartedStatsCubit.state['likes'] ?? 0;
    final followings = _getstartedStatsCubit.state['followings'] ?? 0;
    final interests = _getstartedStatsCubit.state['interests'] ?? 0;

    getStartedLikesNotifier.value = likes;
    setState(() {
      getStartedLikes = likes;
      getStartedFollowings = followings;
      getStartedInterests = interests;
    });
  }
}
