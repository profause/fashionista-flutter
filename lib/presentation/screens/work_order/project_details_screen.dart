import 'package:fashionista/core/theme/app.theme.dart';
import 'package:fashionista/data/models/profile/bloc/user_bloc.dart';
import 'package:fashionista/data/models/work_order/work_order_model.dart';
import 'package:fashionista/presentation/screens/work_order/work_order_timeline_page.dart';
import 'package:fashionista/presentation/screens/work_order/work_order_details_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProjectDetailsScreen extends StatefulWidget {
  final WorkOrderModel workOrderInfo;
  const ProjectDetailsScreen({super.key, required this.workOrderInfo});

  @override
  State<ProjectDetailsScreen> createState() => _ProjectDetailsScreenState();
}

class _ProjectDetailsScreenState extends State<ProjectDetailsScreen>
    with SingleTickerProviderStateMixin {
  static const double expandedHeight = 84;
  late final TabController _tabController;
  late UserBloc userBloc;

  @override
  void initState() {
    _tabController = TabController(length: 2, vsync: this);
    userBloc = context.read<UserBloc>();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

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
                toolbarHeight: kToolbarHeight, // 👈 allow space for back button
                expandedHeight: expandedHeight,
                backgroundColor: colorScheme.onPrimary,
                foregroundColor: colorScheme.primary,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () =>
                      Navigator.of(context).maybePop(), // 👈 back action
                ),
                flexibleSpace: LayoutBuilder(
                  builder: (context, constraints) {
                    final percent =
                        ((constraints.maxHeight - kToolbarHeight) /
                                (expandedHeight - kToolbarHeight))
                            .clamp(0.0, 1.0); // scroll progress 0..1
                    return FlexibleSpaceBar(
                      collapseMode: CollapseMode.parallax,
                      background: SafeArea(
                        child: Column(
                          children: [
                            Opacity(
                              opacity:
                                  percent, // ✅ fade name out as it collapses
                              child: Text(
                                "Work Order",
                                style: textTheme.titleMedium!.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
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
                        vertical: 2,
                        horizontal: 8,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "Details",
                            style: textTheme.bodyMedium!.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
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
                            "Timeline",
                            style: textTheme.bodyMedium!.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController, // ✅ connect the same controller
          children: [
            Builder(
              builder: (context) {
                return CustomScrollView(
                  // Let this scroll work with NestedScrollView
                  key: PageStorageKey("details"),
                  slivers: [
                    SliverOverlapInjector(
                      handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
                        context,
                      ),
                    ),
                    WorkOrderDetailsPage(workOrderInfo: widget.workOrderInfo),
                  ],
                );
              },
            ),
            Builder(
              builder: (context) {
                return CustomScrollView(
                  key: PageStorageKey("timeline"),
                  slivers: [
                    SliverOverlapInjector(
                      handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
                        context,
                      ),
                    ),
                    WorkOrderTimelinePage(workOrderInfo: widget.workOrderInfo),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
