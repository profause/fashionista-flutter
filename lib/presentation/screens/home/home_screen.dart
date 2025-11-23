import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fashionista/core/theme/app.theme.dart';
import 'package:fashionista/data/models/profile/bloc/user_bloc.dart';
import 'package:fashionista/presentation/screens/trends/discover_trends_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatefulWidget {
  final String? route;
  const HomeScreen({super.key, this.route});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  TabController? _tabController;
  ScrollController? _scrollController;
  late UserBloc userBloc;

  @override
  void initState() {
    super.initState();
    int tabIndex = 0;
    if (widget.route != null) {
      if (widget.route == '/trends') {
        tabIndex = 0;
      } else if (widget.route == '/discover-trends') {
        tabIndex = 1;
      }
    }
    _tabController = TabController(
      initialIndex: tabIndex,
      length: 2,
      vsync: this,
    );
    _scrollController = ScrollController();
    userBloc = context.read<UserBloc>();
  }

  @override
  void dispose() {
    _scrollController?.dispose();
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: NestedScrollView(
        floatHeaderSlivers: true,
        headerSliverBuilder: (_, _) => [
          // -------------------------------
          // 1. Twitter/X-style fixed app bar
          // -------------------------------
          SliverAppBar(
            backgroundColor: colorScheme.onPrimary,
            foregroundColor: colorScheme.primary,
            pinned: false, // ← stays fixed ALWAYS
            floating: true,
            snap: false,
            title: Text(
              "Fashionista",
              style: textTheme.titleMedium!.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: colorScheme.primary,
              ),
            ),
            actions: [
              Hero(
                tag: 'add-post',
                child: IconButton(
                  icon: Icon(
                    Icons.add_a_photo_rounded,
                    color: colorScheme.primary,
                  ),
                  onPressed: () {
                    context.push('/trends-new');
                  },
                ),
              ),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('notifications')
                    .where(
                      'to',
                      isEqualTo: userBloc.state.uid,
                    ) // optional if user-based
                    .where('status', isEqualTo: 'new')
                    .limit(1)
                    .snapshots(), // 🔥 live updates
                builder: (context, snapshot) {
                  final hasNew =
                      snapshot.hasData && snapshot.data!.docs.isNotEmpty;

                  return IconButton(
                    icon: Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Icon(
                            Icons.notifications,
                            color: colorScheme.primary,
                          ),
                        ),
                        if (hasNew) // ✅ only show dot when there are new notifications
                          Positioned(
                            top: 8,
                            right: 10,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: AppTheme.appIconColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),

                    onPressed: () {
                      context.push('/notifications');
                    },
                  );
                },
              ),
            ],
          ),

          // -------------------------------
          // 2. Twitter/X-style pinned TabBar
          // -------------------------------
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabBarDelegate(
              TabBar(
                controller: _tabController,
                indicatorColor: colorScheme.primary,
                labelColor: colorScheme.primary,
                unselectedLabelColor: AppTheme.darkGrey,
                dividerHeight: 0.5,
                indicatorWeight: 2,
                dividerColor: colorScheme.primary.withValues(alpha: 0.2),
                indicator: UnderlineTabIndicator(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    width: 4,
                    color: AppTheme.appIconColor.withValues(alpha: 1),
                  ),
                ),
                tabs: [
                  Tab(
                    child: Text(
                      "Discover",
                      style: textTheme.bodyMedium!.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                    //text: "Discover"
                  ),
                  Tab(
                    //text: "Following",
                    child: Text(
                      "For You",
                      style: textTheme.bodyMedium!.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],

        // -------------------------------
        // 3. Scrollable content only
        // -------------------------------
        body: TabBarView(
          controller: _tabController,
          children: [DiscoverTrendsPage(), Placeholder()],
        ),
      ),
    );
  }
}

// --- Helper for the pinned TabBar ---
class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;
  _TabBarDelegate(this._tabBar);

  /// Minimum height (when collapsed)
  @override
  double get minExtent => _tabBar.preferredSize.height;

  /// Maximum height (when expanded)
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final totalScrollRange = maxExtent - minExtent;

    // progress goes from 0 (expanded) → 1 (collapsed)
    final progress = shrinkOffset / totalScrollRange;

    // Smooth padding animation: more padding when collapsed
    //final dynamicPadding = 24 - (24 * (1 - progress)); // 24 → 12

    // Smooth opacity animation
    final opacity = (1.0 - progress).clamp(0.0, 1.0);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 100),
      curve: Curves.fastOutSlowIn,
      //padding: EdgeInsets.only(bottom: 12),
      alignment: Alignment.center,
      color: Theme.of(context).colorScheme.onPrimary,
      child: Opacity(opacity: opacity, child: _tabBar),
    );
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) =>
      true;
}
