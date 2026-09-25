import 'package:fashionista/core/theme/app.theme.dart';
import 'package:fashionista/data/models/clients/bloc/client_bloc.dart';
import 'package:fashionista/data/models/clients/bloc/client_event.dart';
import 'package:fashionista/data/models/clients/bloc/client_state.dart';
import 'package:fashionista/data/models/profile/bloc/user_bloc.dart';
import 'package:fashionista/data/models/work_order/bloc/work_order_bloc.dart';
import 'package:fashionista/data/models/work_order/bloc/work_order_bloc_event.dart';
import 'package:fashionista/data/models/work_order/bloc/work_order_bloc_state.dart';
import 'package:fashionista/presentation/screens/clients/clients_screen.dart';
import 'package:fashionista/presentation/screens/work_order/projects_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class ClientsAndProjectsScreen extends StatefulWidget {
  const ClientsAndProjectsScreen({super.key});

  @override
  State<ClientsAndProjectsScreen> createState() =>
      _ClientsAndProjectsScreenState();
}

class _ClientsAndProjectsScreenState extends State<ClientsAndProjectsScreen>
    with SingleTickerProviderStateMixin {
  static const double expandedHeight = 168;

  late final TabController _tabController;
  final GlobalKey<_ClientsAndProjectsScreenState> clientsAndProjectsKey =
      GlobalKey<_ClientsAndProjectsScreenState>();
  late UserBloc userBloc;
  late GoRouter router;

  @override
  void initState() {
    _tabController = TabController(length: 2, vsync: this);
    userBloc = context.read<UserBloc>();
    _runFetchEvents();
    super.initState();
  }

  void _runFetchEvents() {
    context.read<WorkOrderBloc>().add(const WorkOrdersCounter(''));
    context.read<ClientBloc>().add(const ClientsCounter(''));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    router = GoRouter.of(context);
    router.routerDelegate.addListener(_onRouteChange);
  }

  void _onRouteChange() {
    // Check if we’re currently on this route
    if (router.routerDelegate.currentConfiguration.uri.toString() ==
        '/clients') {
      _runFetchEvents();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: context.canvasBackground,
      body: NestedScrollView(
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
                backgroundColor: context.canvasBackground,
                foregroundColor: context.onCanvasText,
                elevation: 0,
                flexibleSpace: LayoutBuilder(
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
                                  Icon(Icons.people, size: avatarSize),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Opacity(
                              opacity:
                                  percent, // ✅ fade name out as it collapses
                              child: Text(
                                "Clients",
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
                  labelColor: context.onCanvasText,
                  unselectedLabelColor: context.mutedText,
                  indicatorColor: context.accent,
                  dividerColor: context.hairline,
                  physics: const BouncingScrollPhysics(),
                  dividerHeight: 1,
                  indicatorWeight: 2,
                  indicatorSize: TabBarIndicatorSize.label,
                  indicatorPadding: const EdgeInsets.only(left: 8, right: 8),
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
                            "Clients",
                            style: textTheme.bodyMedium!.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          BlocSelector<ClientBloc,ClientBlocState,int >(
                            selector: (state) => state.clientsCount,
                            builder: (context, count) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 0,
                                  horizontal: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: context.accent.withValues(
                                    alpha: 0.10,
                                  ),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  "$count",
                                  style: textTheme.labelSmall!.copyWith(
                                    color: context.accent,
                                    fontWeight: FontWeight.w600,
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
                            "Projects",
                            style: textTheme.bodyMedium!.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          BlocSelector<WorkOrderBloc,WorkOrderBlocState,int >(
                            selector: (state) => state.workOrdersCount,
                            builder: (context, count) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 0,
                                  horizontal: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: context.accent.withValues(
                                    alpha: 0.10,
                                  ),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  "$count",
                                  style: textTheme.labelSmall!.copyWith(
                                    color: context.accent,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              );
                            },
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
                  key: PageStorageKey("clients"),
                  slivers: [
                    SliverOverlapInjector(
                      handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
                        context,
                      ),
                    ),
                    ClientsScreen(),
                  ],
                );
              },
            ),
            Builder(
              builder: (context) {
                return CustomScrollView(
                  key: PageStorageKey("projects"),
                  slivers: [
                    SliverOverlapInjector(
                      handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
                        context,
                      ),
                    ),
                    ProjectsPage(key: clientsAndProjectsKey),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showOptionsBottomsheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.cardSurface,
      barrierColor: const Color(0x730F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF3A3938)
                          : const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: context.canvasBackground,
                    borderRadius: BorderRadius.circular(16),
                    //border: Border.all(color: context.hairline),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0D000000),
                        blurRadius: 2,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _ActionRow(
                        icon: Icons.person_add_alt,
                        label: "Add new client",
                        onTap: () {
                          Navigator.pop(context);
                          context.push('/clients/add');
                        },
                      ),
                      Divider(color: context.hairline, height: 1, thickness: 1),
                      _ActionRow(
                        icon: Icons.work_history,
                        label: "Start a new work order",
                        onTap: () {
                          Navigator.pop(context);
                          context.push('/workorders/add');
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 56,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: context.canvasBackground,
                        borderRadius: BorderRadius.circular(16),
                        //border: Border.all(color: context.hairline),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x0D000000),
                            blurRadius: 2,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      child: const Text(
                        "Cancel",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFFF3B30),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    router.routerDelegate.removeListener(_onRouteChange);
    super.dispose();
  }

  Widget _buildSegmentedTabs() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: context.hairline)),
      ),
      child: TabBar(
        labelColor: context.accent,
        unselectedLabelColor: context.mutedText,
        indicatorColor: context.accent,
        dividerColor: context.hairline,
        dividerHeight: 0,
        indicatorWeight: 2.5,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        tabs: const [
          Tab(icon: Icon(Icons.person_2, size: 20), text: 'Info'),
          Tab(
            icon: Icon(Icons.straighten_rounded, size: 20),
            text: 'Measurements',
          ),
          Tab(icon: Icon(Icons.work_history, size: 20), text: 'Orders'),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(icon, size: 20, color: context.accent),
              const SizedBox(width: 14),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CountPill extends StatelessWidget {
  final int count;
  const _CountPill({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: context.iconSubstrate,
        borderRadius: BorderRadius.circular(999),
        //border: Border.all(color: context.hairline),
      ),
      child: Text(
        "$count",
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: context.mutedText,
        ),
      ),
    );
  }
}
