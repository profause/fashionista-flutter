import 'package:fashionista/core/theme/app.theme.dart';
import 'package:fashionista/data/models/profile/bloc/user_bloc.dart';
import 'package:fashionista/data/models/work_order/bloc/work_order_bloc.dart';
import 'package:fashionista/data/models/work_order/bloc/work_order_bloc_event.dart';
import 'package:fashionista/data/models/work_order/bloc/work_order_bloc_state.dart';
import 'package:fashionista/data/models/work_order/work_order_model.dart';
import 'package:fashionista/presentation/screens/work_order/work_order_timeline_page.dart';
import 'package:fashionista/presentation/screens/work_order/work_order_details_page.dart';
import 'package:fashionista/presentation/widgets/custom_icon_button_rounded.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class ProjectDetailsScreen extends StatefulWidget {
  final String workOrderId;
  const ProjectDetailsScreen({super.key, required this.workOrderId});

  @override
  State<ProjectDetailsScreen> createState() => _ProjectDetailsScreenState();
}

class _ProjectDetailsScreenState extends State<ProjectDetailsScreen>
    with SingleTickerProviderStateMixin {
  static const double expandedHeight = 84;
  late final TabController _tabController;
  late UserBloc userBloc;
  late WorkOrderModel workOrderInfo;

  @override
  void initState() {
    _tabController = TabController(length: 2, vsync: this);
    userBloc = context.read<UserBloc>();
    context.read<WorkOrderBloc>().add(
      LoadWorkOrder(widget.workOrderId, isFromCache: true),
    );
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
                title: Text(
                  "Work Order",
                  style: textTheme.titleMedium!.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                automaticallyImplyLeading: true,
                pinned: true,
                toolbarHeight: kToolbarHeight, // 👈 allow space for back button
                expandedHeight: expandedHeight,
                backgroundColor: colorScheme.onPrimary,
                foregroundColor: colorScheme.primary,
                elevation: 0,
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(right: 18),
                    child: Row(
                      children: [
                        CustomIconButtonRounded(
                          size: 16,
                          iconData: Icons.delete,
                          onPressed: () async {
                            final canDelete = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Delete Project'),
                                content: const Text(
                                  'Are you sure you want to delete this project?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(ctx).pop(false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(ctx).pop(true),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.red,
                                    ),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            );

                            if (canDelete == true) {
                              if (mounted) {
                                showLoadingDialog(context);
                              }
                              await _deleteWorkOrder(widget.workOrderId);
                            }
                          },
                        ),
                        const SizedBox(width: 8),
                        CustomIconButtonRounded(
                          size: 16,
                          iconData: Icons.edit,
                          onPressed: () {
                            context.push(
                              '/workorders/edit/${widget.workOrderId}',
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],

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
        body: BlocBuilder<WorkOrderBloc, WorkOrderBlocState>(
          buildWhen: (context, state) {
            return state is WorkOrderLoaded || state is WorkOrderLoading || state is WorkOrderUpdated;
          },
          builder: (context, state) {
            switch (state) {
              case WorkOrderLoading():
                return const Center(
                  child: SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );

              case WorkOrderError():
                return Center(child: Text(state.message));
              case WorkOrderLoaded(:final workorder):
              case WorkOrderUpdated(:final workorder):
                workOrderInfo = workorder;
                return TabBarView(
                  controller: _tabController, // ✅ connect the same controller
                  children: [
                    Builder(
                      builder: (context) {
                        return CustomScrollView(
                          // Let this scroll work with NestedScrollView
                          key: PageStorageKey("details"),
                          slivers: [
                            SliverOverlapInjector(
                              handle:
                                  NestedScrollView.sliverOverlapAbsorberHandleFor(
                                    context,
                                  ),
                            ),
                            WorkOrderDetailsPage(workOrderInfo: workOrderInfo),
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
                              handle:
                                  NestedScrollView.sliverOverlapAbsorberHandleFor(
                                    context,
                                  ),
                            ),
                            WorkOrderTimelinePage(
                              workOrderInfo: workOrderInfo,
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                );
              default:
                return SizedBox.shrink();
            }
          },
        ),
      ),
    );
  }

  Future<void> _deleteWorkOrder(String uid) async {
    context.read<WorkOrderBloc>().add(DeleteWorkOrder(uid));
    if (!mounted) return;
    dismissLoadingDialog(context);
    context.pop(); // notify ClientsScreen
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // prevent accidental dismiss
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
  }

  void dismissLoadingDialog(BuildContext context) {
    if (Navigator.canPop(context)) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }
}
