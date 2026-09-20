import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/core/theme/app.theme.dart';
import 'package:fashionista/core/widgets/bloc/getstarted_stats_cubit.dart';
import 'package:fashionista/data/models/designers/designer_model.dart';
import 'package:fashionista/data/models/profile/bloc/user_bloc.dart';
import 'package:fashionista/data/models/trends/bloc/trend_bloc.dart';
import 'package:fashionista/data/models/trends/bloc/trend_bloc_event.dart';
import 'package:fashionista/data/models/trends/bloc/trend_bloc_state.dart';
import 'package:fashionista/data/services/firebase/firebase_clients_service.dart';
import 'package:fashionista/data/services/firebase/firebase_designers_service.dart';
import 'package:fashionista/presentation/screens/trends/widgets/designer_compact_card_widget.dart';
import 'package:fashionista/presentation/screens/trends/widgets/designer_shimmer_widget.dart';
import 'package:fashionista/presentation/screens/trends/widgets/get_started_progress_card_widget.dart';
import 'package:fashionista/presentation/screens/trends/widgets/interest_shimmer_widget.dart';
import 'package:fashionista/presentation/screens/trends/widgets/my_post_feed_card_widget.dart';
import 'package:fashionista/presentation/screens/trends/widgets/quick_action_tile_widget.dart';
import 'package:fashionista/presentation/widgets/default_profile_avatar_widget.dart';
import 'package:fashionista/presentation/widgets/page_empty_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  final ValueNotifier<List<Designer>> myDesignersNotifier =
      ValueNotifier<List<Designer>>([]);

  bool loadingFashionDesigners = true;
  late GetstartedStatsCubit _getstartedStatsCubit;
  //late UserBloc _userBloc;

  final ValueNotifier<int> getStartedLikesNotifier = ValueNotifier<int>(0);
  final ValueNotifier<int> getStartedFollowingsNotifier = ValueNotifier<int>(0);
  final ValueNotifier<int> getStartedInterestsNotifier = ValueNotifier<int>(0);
  late UserBloc _userBloc;
  late int getStartedLikes = 0;
  late int getStartedFollowings = 0;
  late int getStartedInterests = 0;
  Timer? _debounce;
  Timer? _loadInterestsDebounce; // 👈 debounce timer

  @override
  void initState() {
    _userBloc = context.read<UserBloc>();
    _loadGetStartedStats();
    _loadFashionInterests();
    _loadFashionDesigners();
    _loadFashionTrends();
    super.initState();
  }

  @override
  void dispose() {
    selectedInterestsNotifier.dispose();
    getStartedLikesNotifier.dispose();
    getStartedFollowingsNotifier.dispose();
    getStartedInterestsNotifier.dispose();
    designersNotifier.dispose();
    myDesignersNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: context.canvasBackground,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _buildGetStartedSection(context, textTheme),
          ),
          SliverToBoxAdapter(child: _buildQuickActionsSection(context)),
          SliverToBoxAdapter(
            child: _buildInterestsSection(context, textTheme),
          ),
          SliverToBoxAdapter(
            child: _buildDesignersSection(context, textTheme),
          ),
          SliverToBoxAdapter(
            child: _buildMyPostsSection(context, textTheme),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/trends-new'),
        shape: const CircleBorder(),
        backgroundColor: context.accent,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  /// "Get started" onboarding tracker: horizontally scrollable progress cards.
  Widget _buildGetStartedSection(BuildContext context, TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  'Get started',
                  style: textTheme.titleSmall!.copyWith(fontSize: 15),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Skip',
                    style: textTheme.labelSmall!.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0,
                      color: context.mutedText,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 110,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                ValueListenableBuilder<int>(
                  valueListenable: getStartedLikesNotifier,
                  builder: (context, likes, _) {
                    return GetStartedProgressCardWidget(
                      title: 'Like 10 posts',
                      subtitle: 'Teach our algorithms what you like',
                      progress: likes / 10,
                    );
                  },
                ),
                const SizedBox(width: 12),
                BlocSelector<GetstartedStatsCubit, Map<String, int>, int>(
                  selector: (state) => state['followings'] ?? 0,
                  builder: (context, followings) {
                    return GetStartedProgressCardWidget(
                      title: 'Follow designers',
                      subtitle: 'Follow creators to view work',
                      progress: followings / 10,
                      onTap: () => context.push('/designers'),
                    );
                  },
                ),
                const SizedBox(width: 12),
                BlocSelector<GetstartedStatsCubit, Map<String, int>, int>(
                  selector: (state) => state['interests'] ?? 0,
                  builder: (context, interests) {
                    return GetStartedProgressCardWidget(
                      title: 'Show interests',
                      subtitle: 'Explore your fashion identity',
                      progress: interests / 5,
                      onTap: () => _openUserInterests(context),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Shortcut tiles for measurements and the user's designers.
  Widget _buildQuickActionsSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: QuickActionTileWidget(
              label: 'My Measurements',
              onTap: () => context.go('/profile'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ValueListenableBuilder<List<Designer>>(
              valueListenable: myDesignersNotifier,
              builder: (context, designers, _) {
                return QuickActionTileWidget(
                  label: 'My Designers',
                  onTap: () => context.push('/my-designers'),
                  trailing: designers.isEmpty
                      ? null
                      : _designerAvatarStack(context, designers),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Interest pills: the user's own interests render as active (brand) pills.
  Widget _buildInterestsSection(BuildContext context, TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Interests',
                style: textTheme.titleSmall!.copyWith(fontSize: 15),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => _openUserInterests(context),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'More',
                  style: textTheme.labelSmall!.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0,
                    color: context.accent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ValueListenableBuilder<List<String>>(
            valueListenable: selectedInterestsNotifier,
            builder: (context, selectedInterests, _) {
              if (loadingFashionInterests) {
                return SizedBox(
                  height: 34,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: 6, // number of shimmer placeholders
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (_, index) {
                      // variable chip widths
                      final randomWidth = 70 + (30 * (index % 3)).toDouble();
                      return InterestShimmerWidget(width: randomWidth);
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

              final List<String> userInterests =
                  _userBloc.state.interests ?? [];

              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: selectedInterests.map((item) {
                  final bool isSelected = userInterests.any(
                    (interest) =>
                        interest.toLowerCase() == item.toLowerCase(),
                  );
                  return _interestPill(context, textTheme, item, isSelected);
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _interestPill(
    BuildContext context,
    TextTheme textTheme,
    String label,
    bool isSelected,
  ) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: isSelected ? context.accent : context.secondaryButtonBg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isSelected ? Colors.transparent : context.hairline,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: textTheme.labelSmall!.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              letterSpacing: 0,
              color: isSelected ? Colors.white : context.onCanvasText,
            ),
          ),
        ],
      ),
    );
  }

  /// Compact, horizontally scrolling designer cards with a follow action.
  Widget _buildDesignersSection(BuildContext context, TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  'Designers',
                  style: textTheme.titleSmall!.copyWith(fontSize: 15),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => context.push('/designers'),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'More',
                    style: textTheme.labelSmall!.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0,
                      color: context.mutedText,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 170,
            child: ValueListenableBuilder<List<Designer>>(
              valueListenable: designersNotifier,
              builder: (context, designers, _) {
                if (loadingFashionDesigners) {
                  return ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: 4, // number of shimmer placeholders
                    separatorBuilder: (_, _) => const SizedBox(width: 12),
                    itemBuilder: (_, _) => const DesignerShimmerWidget(),
                  );
                }

                if (designers.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      "No designers found",
                      style: textTheme.bodyMedium,
                    ),
                  );
                }

                return ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: designers.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final item = designers[index];
                    return DesignerCompactCardWidget(
                      key: ValueKey(item.uid),
                      designerInfo: item,
                      onFollowTap: (bool isFollowing) {
                        final cubit = context.read<GetstartedStatsCubit>();
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Feed-style list of the trends created by the current user.
  Widget _buildMyPostsSection(BuildContext context, TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'My Posts',
            style: textTheme.titleSmall!.copyWith(fontSize: 15),
          ),
          const SizedBox(height: 12),
          BlocBuilder<TrendBloc, TrendBlocState>(
            buildWhen: (context, state) {
              return state is TrendsCreatedByLoaded;
            },
            builder: (context, state) {
              switch (state) {
                case TrendLoading():
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  );
                case TrendsCreatedByLoaded(:final trends):
                  if (trends.isEmpty) {
                    return _buildEmptyPosts();
                  }
                  return ListView.separated(
                    padding: EdgeInsets.zero,
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: trends.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final item = trends[index];
                      return MyPostFeedCardWidget(
                        trendInfo: item,
                        onLikeTap: (bool isLiked) {
                          final cubit = context.read<GetstartedStatsCubit>();
                          final currentLikes = cubit.state['likes'] ?? 0;
                          final newLike = isLiked
                              ? currentLikes + 1
                              : (currentLikes > 0 ? currentLikes - 1 : 0);

                          cubit.updateLikes(newLike);
                        },
                      );
                    },
                  );
                case TrendError(:final message):
                  debugPrint("Error: $message");
                  return SizedBox(
                    height: 240,
                    child: Center(child: Text("Error: $message")),
                  );
                default:
                  return _buildEmptyPosts();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyPosts() {
    return SizedBox(
      height: 240,
      child: Center(
        child: PageEmptyWidget(
          title: "No Trends Found",
          subtitle: "Add new trend to see them here.",
          icon: Icons.newspaper_outlined,
        ),
      ),
    );
  }

  void _openUserInterests(BuildContext context) {
    final uri = Uri(
      path: '/user-interests',
      queryParameters: {'fromwhere': 'ForYouPage'},
    );
    context.push(uri.toString());
  }

  /// Overlapping mini avatars shown on the "My Designers" shortcut tile.
  Widget _designerAvatarStack(BuildContext context, List<Designer> designers) {
    final List<Designer> visible = designers.take(3).toList();
    return SizedBox(
      height: 22,
      width: visible.length * 14.0 + 8,
      child: Stack(
        children: [
          for (int i = 0; i < visible.length; i++)
            Positioned(
              left: i * 14.0,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: context.canvasBackground,
                    width: 2,
                  ),
                ),
                child: ClipOval(
                  child: (visible[i].profileImage ?? '').isEmpty
                      ? DefaultProfileAvatar(
                          name: visible[i].name,
                          size: 18,
                          uid: visible[i].uid,
                        )
                      : CachedNetworkImage(
                          imageUrl: visible[i].profileImage!,
                          fit: BoxFit.cover,
                          errorListener: (value) {},
                          placeholder: (_, _) => DefaultProfileAvatar(
                            name: visible[i].name,
                            size: 18,
                            uid: visible[i].uid,
                          ),
                          errorWidget: (_, _, _) => DefaultProfileAvatar(
                            name: visible[i].name,
                            size: 18,
                            uid: visible[i].uid,
                          ),
                        ),
                ),
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
        final userInterests = _userBloc.state.interests;
        final userInterestCount = userInterests!.length;
        //here
        final cubit = context.read<GetstartedStatsCubit>();
        cubit.updateInterests(userInterestCount);

        final querySnapshot = await FirebaseFirestore.instance
            .collection('fashion_interests')
            .orderBy('category')
            .limit(5)
            .get();

        final interests = userInterestCount > 4
            ? userInterests
            : querySnapshot.docs
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
          .findDesignersWithFilter(6, 'created_date');

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

      final resultC = await sl<FirebaseClientsService>()
          .findClientByMobileNumber(_userBloc.state.mobileNumber);

      await resultC.fold(
        (failure) async {
          debugPrint("Client fetch failed: $failure");
          loadingFashionDesigners = false;
        },
        (clients) async {
          if (clients.isEmpty) {
            myDesignersNotifier.value = [];
            loadingFashionDesigners = false;
            return;
          }

          // Remove duplicate designer IDs
          final designerIds = clients.map((c) => c.createdBy).toSet().toList();

          final designerResults = await Future.wait(
            designerIds.map(
              (id) => sl<FirebaseDesignersService>().findDesignerById(id),
            ),
          );

          final designers = designerResults
              .where((r) => r.isRight())
              .map((r) => r.getOrElse(() => throw UnimplementedError()))
              .toList();

          myDesignersNotifier.value = designers;
          loadingFashionDesigners = false;
        },
      );
    });
  }

  void _loadFashionTrends() {
    String uid = FirebaseAuth.instance.currentUser!.uid;
    context.read<TrendBloc>().add(LoadTrendsCacheForYouPage(uid));
  }

  void _loadGetStartedStats() {
    _getstartedStatsCubit = context.read<GetstartedStatsCubit>();
    final likes = _getstartedStatsCubit.state['likes'] ?? 0;
    final followings = _getstartedStatsCubit.state['followings'] ?? 0;
    final interests = _getstartedStatsCubit.state['interests'] ?? 0;

    getStartedLikesNotifier.value = likes;
    getStartedFollowingsNotifier.value = followings;
    getStartedInterestsNotifier.value = interests;

    setState(() {
      getStartedLikes = likes;
      getStartedFollowings = followings;
      getStartedInterests = interests;
    });
  }
}
