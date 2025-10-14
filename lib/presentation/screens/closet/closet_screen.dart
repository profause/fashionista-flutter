import 'package:cached_network_image/cached_network_image.dart';
import 'package:fashionista/core/theme/app.theme.dart';
import 'package:fashionista/data/models/closet/bloc/closet_item_bloc.dart';
import 'package:fashionista/data/models/closet/bloc/closet_item_bloc_state.dart';
import 'package:fashionista/data/models/closet/bloc/closet_outfit_bloc.dart';
import 'package:fashionista/data/models/closet/bloc/closet_outfit_bloc_event.dart';
import 'package:fashionista/data/models/closet/bloc/closet_outfit_bloc_state.dart';
import 'package:fashionista/data/models/closet/outfit_model.dart';
import 'package:fashionista/data/models/profile/bloc/user_bloc.dart';
import 'package:fashionista/data/models/profile/models/user.dart';
import 'package:fashionista/presentation/screens/closet/add_or_edit_closet_items_page.dart';
import 'package:fashionista/presentation/screens/closet/closet_items_page.dart';
import 'package:fashionista/presentation/screens/closet/outfit_planner_screen.dart';
import 'package:fashionista/presentation/screens/closet/outfits_page.dart';
import 'package:fashionista/presentation/widgets/default_profile_avatar_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ClosetScreen extends StatefulWidget {
  const ClosetScreen({super.key});

  @override
  State<ClosetScreen> createState() => _ClosetScreenState();
}

class _ClosetScreenState extends State<ClosetScreen>
    with SingleTickerProviderStateMixin {
  static const double expandedHeight = 168;
  late UserBloc userBloc;
  late final TabController _tabController;
  final GlobalKey<OutfitsPageState> outfitsKey = GlobalKey<OutfitsPageState>();

  @override
  void initState() {
    _tabController = TabController(length: 3, vsync: this);
    userBloc = context.read<UserBloc>();
    context.read<ClosetOutfitBloc>().add(const OutfitCounter(''));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: NestedScrollView(
        physics: const ClampingScrollPhysics(),
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[
            /// Profile AppBar
            SliverOverlapAbsorber(
              handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
              sliver: SliverAppBar(
                pinned: true,
                floating: true,
                toolbarHeight: 0,
                expandedHeight: expandedHeight,
                backgroundColor: colorScheme.onPrimary,
                foregroundColor: colorScheme.primary,
                elevation: 0,
                flexibleSpace: BlocBuilder<UserBloc, User>(
                  builder: (context, user) {
                    return LayoutBuilder(
                      builder: (context, constraints) {
                        final percent =
                            ((constraints.maxHeight - kToolbarHeight) /
                                    (expandedHeight - kToolbarHeight))
                                .clamp(0.0, 1.0); // scroll progress 0..1

                        final avatarSize = 56 + (68 - 56) * percent;
                        return FlexibleSpaceBar(
                          collapseMode: CollapseMode.parallax,
                          background: SafeArea(
                            child: Column(
                              children: [
                                const SizedBox(height: 8),
                                Center(
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Material(
                                        color: Colors.white,
                                        borderOnForeground: true,
                                        borderRadius: BorderRadius.circular(60),
                                        child: Padding(
                                          padding: const EdgeInsets.all(3.0),
                                          child: InkWell(
                                            borderRadius: BorderRadius.circular(
                                              18,
                                            ),
                                            onTap: () {},
                                            child: user.profileImage.isNotEmpty
                                                ? CircleAvatar(
                                                    radius:
                                                        avatarSize /
                                                        2, // ✅ shrink smoothly
                                                    backgroundColor:
                                                        AppTheme.lightGrey,
                                                    backgroundImage:
                                                        CachedNetworkImageProvider(
                                                          user.profileImage,
                                                          errorListener: (error) {},
                                                        ),
                                                  )
                                                : DefaultProfileAvatar(
                                                    name: null,
                                                    size: avatarSize,
                                                    uid: user.uid!,
                                                  ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Opacity(
                                  opacity:
                                      percent, // ✅ fade name out as it collapses
                                  child: Text(
                                    "My Closet",
                                    style: textTheme.titleMedium!.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                //
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),

                bottom: TabBar(
                  controller: _tabController,
                  labelColor: colorScheme.primary,
                  unselectedLabelColor: AppTheme.darkGrey,
                  indicatorColor: AppTheme.appIconColor.withValues(alpha: 1),
                  dividerColor: AppTheme.lightGrey,
                  physics: const BouncingScrollPhysics(),
                  dividerHeight: 0,
                  indicatorWeight: 2,
                  indicatorPadding: const EdgeInsets.only(left: 8, right: 8),
                  indicator: UnderlineTabIndicator(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      width: 4,
                      color: AppTheme.appIconColor.withValues(alpha: 1),
                    ),
                  ),
                  tabs: [
                    Container(
                      margin: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 8,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "Items",
                            style: textTheme.bodyMedium!.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          BlocSelector<
                            ClosetItemBloc,
                            ClosetItemBlocState,
                            int
                          >(
                            selector: (state) => state.itemCount,
                            builder: (context, count) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 0,
                                  horizontal: 4,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.grey[800] // dark mode background
                                      : Colors.grey[400],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  "$count",
                                  style: textTheme.labelSmall!.copyWith(
                                    color: colorScheme.primary,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 8,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "Outfits",
                            style: textTheme.bodyMedium!.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          BlocSelector<
                            ClosetOutfitBloc,
                            ClosetOutfitBlocState,
                            int
                          >(
                            selector: (state) => state.itemCount,
                            builder: (context, count) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 0,
                                  horizontal: 4,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.grey[800] // dark mode background
                                      : Colors.grey[400],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  "$count",
                                  style: textTheme.labelSmall!.copyWith(
                                    color: colorScheme.primary,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 8,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "Planner",
                            style: textTheme.bodyMedium!.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          // const SizedBox(width: 4),
                          // Container(
                          //   padding: const EdgeInsets.symmetric(
                          //     vertical: 0,
                          //     horizontal: 4,
                          //   ),
                          //   decoration: BoxDecoration(
                          //     color: Colors.grey[300],
                          //     borderRadius: BorderRadius.circular(8),
                          //   ),
                          //   child: Text("000", style: textTheme.labelSmall!),
                          // ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ];
        },

        /// TabBarView = main body
        body: TabBarView(
          controller: _tabController, // ✅ connect the same controller
          children: [
            Builder(
              builder: (context) {
                return CustomScrollView(
                  // Let this scroll work with NestedScrollView
                  key: PageStorageKey("items"),
                  slivers: [
                    SliverOverlapInjector(
                      handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
                        context,
                      ),
                    ),
                    ClosetItemsPage(),
                  ],
                );
              },
            ),
            Builder(
              builder: (context) {
                return CustomScrollView(
                  key: PageStorageKey("outfits"),
                  slivers: [
                    SliverOverlapInjector(
                      handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
                        context,
                      ),
                    ),
                    OutfitsPage(key: outfitsKey),
                  ],
                );
              },
            ),
            Builder(
              builder: (context) {
                return CustomScrollView(
                  key: PageStorageKey("planner"),
                  slivers: [
                    SliverOverlapInjector(
                      handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
                        context,
                      ),
                    ),
                    OutfitPlannerScreen(),
                  ],
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton:
          (_tabController.index == 0 || _tabController.index == 1)
          ? FloatingActionButton(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30), // 👈 adjust radius
              ),
              onPressed: () {
                if (_tabController.index == 0) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AddOrEditClosetItemsPage(),
                    ),
                  );
                } else if (_tabController.index == 1) {
                  outfitsKey.currentState?.showAddOutfitBottomSheet(
                    context,
                    OutfitModel.empty(),
                  );
                } else if (_tabController.index == 2) {
                  // open "Add Planner" page
                }
              },
              backgroundColor: colorScheme.primary,
              child: const Icon(Icons.add),
            )
          : SizedBox.shrink(), // 👈 FAB hidden when not tab 0 or 1
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
