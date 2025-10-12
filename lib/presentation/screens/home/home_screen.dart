import 'package:fashionista/core/theme/app.theme.dart';
import 'package:fashionista/data/models/profile/bloc/user_bloc.dart';
import 'package:fashionista/presentation/screens/trends/discover_trends_screen.dart';
import 'package:fashionista/presentation/screens/trends/trends_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? navigationCallback;
  const HomeScreen({super.key, this.navigationCallback});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  TabController? _tabController;
  ScrollController? _scrollController;
  late UserBloc userBloc;
  static const double expandedHeight = 84;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(initialIndex: 0, length: 2, vsync: this);
    _scrollController = ScrollController();
    userBloc = context.read<UserBloc>();

    // Auto-collapse the SliverAppBar after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController!.hasClients) {
        // _scrollController!.animateTo(
        //   120.0, // The expandedHeight of the collapsible SliverAppBar
        //   duration: const Duration(milliseconds: 300),
        //   curve: Curves.easeInOut,
        // );
      }
    });
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

    //UserBloc userBloc = context.read<UserBloc>();
    //final user = userBloc.state;

    return Scaffold(
      body: NestedScrollView(
        //controller: _scrollController,
        physics: const ClampingScrollPhysics(),
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[
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
                flexibleSpace: LayoutBuilder(
                  builder: (context, constraints) {
                    final percent =
                        ((constraints.maxHeight - kToolbarHeight) /
                                (expandedHeight - kToolbarHeight))
                            .clamp(0.0, 1.0); // scroll progress 0..1
                    return FlexibleSpaceBar(
                      collapseMode: CollapseMode.parallax,
                      background: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 16, right: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Opacity(
                                opacity:
                                    percent, // ✅ fade name out as it collapses
                                child: IconButton(
                                  icon: const Icon(Icons.notifications),
                                  color: colorScheme.primary,
                                  onPressed: () {},
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                bottom: TabBar(
                  labelColor: colorScheme.primary,
                  unselectedLabelColor: AppTheme.darkGrey,
                  indicatorColor: colorScheme.primary,
                  dividerHeight: 0.0,
                  indicatorWeight: 2,
                  tabAlignment: TabAlignment.center,
                  labelPadding: const EdgeInsets.all(0),
                  indicator: UnderlineTabIndicator(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      width: 4,
                      color: colorScheme.primary,
                    ),
                  ),
                  dividerColor: colorScheme.primary.withValues(alpha: 0.2),
                  controller: _tabController,
                  tabs: <Widget>[
                    // Container(
                    //   margin: const EdgeInsets.symmetric(
                    //     vertical: 8,
                    //     horizontal: 8,
                    //   ),
                    //   child: Text(
                    //     "For You",
                    //     style: textTheme.bodyMedium!.copyWith(
                    //       fontWeight: FontWeight.bold,
                    //       color: colorScheme.primary,
                    //     ),
                    //   ),
                    // ),
                    Container(
                      margin: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 8,
                      ),
                      child: Text(
                        "Trends",
                        style: textTheme.bodyMedium!.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 8,
                      ),
                      child: Text(
                        "Discover",
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

            // Separate pinned SliverAppBar for tabs
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: <Widget>[
            // user.accountType == 'Designer'
            //     ? DesignerHomePage(
            //         navigationCallback: widget.navigationCallback?.call,
            //       )
            //     : UserHomePage(),
            //TrendsScreen(),
            //DiscoverTrendsScreen(),
            Builder(
              builder: (context) {
                return CustomScrollView(
                  // Let this scroll work with NestedScrollView
                  key: PageStorageKey("trends"),
                  slivers: [
                    SliverOverlapInjector(
                      handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
                        context,
                      ),
                    ),
                    TrendsScreen(),
                  ],
                );
              },
            ),
            Builder(
              builder: (context) {
                return CustomScrollView(
                  // Let this scroll work with NestedScrollView
                  key: PageStorageKey("discover"),
                  slivers: [
                    SliverOverlapInjector(
                      handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
                        context,
                      ),
                    ),
                    DiscoverTrendsScreen(),
                  ],
                );
              },
            ),
          ],
        ),
      ),
      // floatingActionButton: Hero(
      //   tag: 'add-trend-button',
      //   child: Material(
      //     color: Theme.of(context).colorScheme.primary.withValues(alpha: 1),
      //     elevation: 6,
      //     shape: const CircleBorder(),
      //     child: InkWell(
      //       onTap: () async {
      //         final result = await Navigator.push(
      //           context,
      //           MaterialPageRoute(builder: (_) => const AddTrendScreen()),
      //         );

      //         // if AddClientScreen popped with "true", reload
      //         if (result == true && mounted) {
      //           context.read<TrendBloc>().add(
      //             const LoadTrendsCacheFirstThenNetwork(''),
      //           );
      //         }
      //       },
      //       customBorder: const CircleBorder(),
      //       child: SizedBox(
      //         width: 56,
      //         height: 56,
      //         child: Icon(Icons.add, color: colorScheme.onPrimary),
      //       ),
      //     ),
      //   ),
      // ),
    );
  }
}
