import 'package:fashionista/core/theme/app.theme.dart';
import 'package:fashionista/data/models/profile/bloc/user_bloc.dart';
import 'package:fashionista/data/models/work_order/bloc/work_order_bloc.dart';
import 'package:fashionista/data/models/work_order/bloc/work_order_bloc_event.dart';
import 'package:fashionista/data/models/work_order/bloc/work_order_bloc_state.dart';
import 'package:fashionista/data/models/work_order/work_order_model.dart';
import 'package:fashionista/presentation/screens/work_order/work_order_details_page.dart';
import 'package:fashionista/presentation/screens/work_order/work_order_timeline_page.dart';
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
  late final TabController _tabController;

  late UserBloc userBloc;
  WorkOrderModel? workOrderInfo;

  static const double _tabBarHeight = kTextTabBarHeight;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 2, vsync: this);

    userBloc = context.read<UserBloc>();

    context.read<WorkOrderBloc>().add(
      LoadWorkOrder(widget.workOrderId, isFromCache: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.canvasBackground,
      body: NestedScrollView(
        physics: const ClampingScrollPhysics(),
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return [
            SliverOverlapAbsorber(
              handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
              sliver: SliverAppBar(
                pinned: true,

                // Only the toolbar is the expanded/collapsed height.
                expandedHeight: 84,

                toolbarHeight: kToolbarHeight,

                backgroundColor: context.canvasBackground,
                foregroundColor: context.onCanvasText,
                surfaceTintColor: Colors.transparent,
                elevation: 0,

                automaticallyImplyLeading: true,

                title: Text(
                  'Work Order',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    color: context.onCanvasText,
                  ),
                ),

                actions: [
                  Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () async {
                            final canDelete = await showDialog<bool>(
                              context: context,
                              builder: (dialogContext) {
                                return AlertDialog(
                                  title: const Text('Delete Project'),
                                  content: const Text(
                                    'Are you sure you want to delete this project?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(dialogContext).pop(false);
                                      },
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(dialogContext).pop(true);
                                      },
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.red,
                                      ),
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                );
                              },
                            );

                            if (canDelete == true) {
                              if (!mounted) return;

                              showLoadingDialog(context);

                              await _deleteWorkOrder(widget.workOrderId);
                            }
                          },
                          icon: Icon(
                            Icons.delete_outline_rounded,
                            size: 22,
                            color: context.mutedText,
                          ),
                        ),

                        const SizedBox(width: 4),

                        IconButton(
                          onPressed: () {
                            context.push(
                              '/workorders/edit/${widget.workOrderId}',
                            );
                          },
                          icon: Icon(
                            Icons.edit_outlined,
                            size: 20,
                            color: context.onCanvasText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(kTextTabBarHeight),
                  child: TabBar(
                    controller: _tabController,

                    labelColor: context.accent,
                    unselectedLabelColor: context.mutedText,

                    dividerColor: context.hairline,
                    dividerHeight: 1,

                    physics: const BouncingScrollPhysics(),

                    labelStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),

                    unselectedLabelStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),

                    indicator: UnderlineTabIndicator(
                      borderSide: BorderSide(width: 3, color: context.accent),
                      borderRadius: BorderRadius.circular(3),
                      insets: const EdgeInsets.symmetric(horizontal: 40),
                    ),

                    tabs: const [
                      Tab(text: 'Details'),
                      Tab(text: 'Timeline'),
                    ],
                  ),
                ),
              ),
            ),
          ];
        },

        body: BlocBuilder<WorkOrderBloc, WorkOrderBlocState>(
          buildWhen: (previous, current) {
            return current is WorkOrderLoaded ||
                current is WorkOrderLoading ||
                current is WorkOrderUpdated ||
                current is WorkOrderError;
          },
          builder: (context, state) {
            if (state is WorkOrderLoading) {
              return const Center(
                child: SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            }

            if (state is WorkOrderError) {
              return Center(
                child: Text(
                  state.message,
                  style: TextStyle(color: context.onCanvasText),
                ),
              );
            }

            if (state is WorkOrderLoaded) {
              workOrderInfo = state.workorder;
            }

            if (state is WorkOrderUpdated) {
              workOrderInfo = state.workorder;
            }

            final workOrder = workOrderInfo;

            if (workOrder == null) {
              return const SizedBox.shrink();
            }

            return TabBarView(
              controller: _tabController,
              physics: const BouncingScrollPhysics(),
              children: [
                CustomScrollView(
                  key: const PageStorageKey<String>('details'),
                  physics: const ClampingScrollPhysics(),
                  slivers: [
                    SliverOverlapInjector(
                      handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
                        context,
                      ),
                    ),

                    WorkOrderDetailsPage(workOrderInfo: workOrder),
                  ],
                ),

                CustomScrollView(
                  key: const PageStorageKey<String>('timeline'),
                  physics: const ClampingScrollPhysics(),
                  slivers: [
                    SliverOverlapInjector(
                      handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
                        context,
                      ),
                    ),

                    WorkOrderTimelinePage(workOrderInfo: workOrder),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _deleteWorkOrder(String uid) async {
    context.read<WorkOrderBloc>().add(DeleteWorkOrder(uid));

    if (!mounted) return;

    dismissLoadingDialog(context);

    context.pop();
  }

  void showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  void dismissLoadingDialog(BuildContext context) {
    if (Navigator.canPop(context)) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
