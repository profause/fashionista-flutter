
import 'package:fashionista/core/theme/app.theme.dart';
import 'package:fashionista/data/models/profile/bloc/user_bloc.dart';
import 'package:fashionista/presentation/screens/home/designer_home_page.dart';
import 'package:fashionista/presentation/screens/home/user_home_page.dart';
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(initialIndex: 1, length: 3, vsync: this);
    _scrollController = ScrollController();

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

    UserBloc userBloc = context.read<UserBloc>();
    final user = userBloc.state;

    return Scaffold(
      body: NestedScrollView(
        controller: _scrollController,
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[
            // Separate SliverAppBar for title that can collapse
            // SliverAppBar(
            //   backgroundColor: colorScheme.onPrimary,
            //   pinned: false, // Allow this to collapse
            //   floating: false,
            //   expandedHeight: 12,
            //   flexibleSpace: FlexibleSpaceBar(
            //     title: Text(
            //       "Fashionista",
            //       style: textTheme.titleLarge!.copyWith(
            //         color: colorScheme.primary,
            //       ),
            //     ),
            //     centerTitle: false,
            //     titlePadding: const EdgeInsets.only(left: 16, bottom: 0),
            //   ),
            // ),
            // Separate pinned SliverAppBar for tabs
            SliverAppBar(
              backgroundColor: colorScheme.onPrimary,
              pinned: true, // Keep tabs visible
              toolbarHeight: 0, // No title bar
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(48),
                child: TabBar(
                  labelColor: colorScheme.primary,
                  unselectedLabelColor: AppTheme.darkGrey,
                  indicatorColor: colorScheme.primary,
                  dividerHeight: 0.1,
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
                    Container(
                      margin: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 8,
                      ),
                      child: Text(
                        "For You",
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
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: <Widget>[
            user.accountType == 'Designer'
                ? DesignerHomePage(
                    navigationCallback: widget.navigationCallback?.call,
                  )
                : UserHomePage(),
            TrendsScreen(),
            DiscoverTrendsScreen(),
          ],
        ),
      ),
    );
  }
}
