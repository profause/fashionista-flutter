import 'package:fashionista/core/theme/app.theme.dart';
import 'package:fashionista/data/models/profile/bloc/user_bloc.dart';
import 'package:fashionista/presentation/screens/home/designer_home_page.dart';
import 'package:fashionista/presentation/screens/home/user_home_page.dart';
import 'package:fashionista/presentation/screens/trends/trends_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  TabController? _tabController;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    UserBloc userBloc = context.read<UserBloc>();
    final user = userBloc.state;
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[
            SliverAppBar(
              pinned: true,
              floating: true,
              snap: true,
              title: Text("Fashionista", style: textTheme.titleLarge!.copyWith(
                color: colorScheme.primary
              )),
              bottom: TabBar(
                labelColor: colorScheme.primary,
                unselectedLabelColor: AppTheme.darkGrey,
                indicatorColor: colorScheme.primary,
                //dividerColor: AppTheme.lightGrey,
                dividerHeight: 0.1,
                indicatorWeight: 2,
                indicator: UnderlineTabIndicator(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(width: 4, color: colorScheme.primary),
                ),
                dividerColor: colorScheme.primary.withValues(alpha: 0.2),
                controller: _tabController,
                tabs: <Widget>[
                  Tab(
                    child: Text(
                      "Trends",
                      style: textTheme.bodyMedium!.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary
                      ),
                    ),
                  ),
                  Tab(
                    child: Text(
                      "For You",
                      style: textTheme.bodyMedium!.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: <Widget>[
            TrendsScreen(),
            user.accountType == 'Designer'
                ? DesignerHomePage()
                : UserHomePage(),
          ],
        ),
      ),
    );
  }
}
