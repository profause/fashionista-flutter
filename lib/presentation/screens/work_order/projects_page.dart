import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/data/models/work_order/bloc/work_order_bloc.dart';
import 'package:fashionista/data/models/work_order/bloc/work_order_bloc_event.dart';
import 'package:fashionista/data/models/work_order/work_order_model.dart';
import 'package:fashionista/data/services/hive/hive_work_order_service.dart';
import 'package:fashionista/presentation/screens/work_order/widgets/pinned_work_order_info_card_widget.dart';
import 'package:fashionista/presentation/screens/work_order/widgets/work_order_info_card_widget.dart';
import 'package:fashionista/presentation/widgets/custom_icon_button_rounded.dart';
import 'package:fashionista/presentation/widgets/page_empty_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:sliver_tools/sliver_tools.dart';

class ProjectsPage extends StatefulWidget {
  const ProjectsPage({super.key});

  @override
  State<ProjectsPage> createState() => _ProjectsPageState();
}

class _ProjectsPageState extends State<ProjectsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchText = "";

  @override
  void initState() {
    context.read<WorkOrderBloc>().add(
      const LoadWorkOrdersCacheFirstThenNetwork(''),
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return MultiSliver(
      // 👈 helper from 'sliver_tools' package, or just return a Column of slivers
      children: [
        SliverAppBar(
          backgroundColor: colorScheme.surface,
          pinned: true, // keeps the searchbar visible when collapsed
          floating: true, // allows it to appear/disappear as you scroll
          snap: true, // snaps into view when scrolling up
          stretch: true,
          expandedHeight: 18,
          toolbarHeight: 5,
          flexibleSpace: FlexibleSpaceBar(
            background: Padding(
              padding: const EdgeInsets.fromLTRB(12, 20, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: "Search projects...",
                        hintStyle: textTheme.bodyMedium!.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: colorScheme.primary,
                        ),
                        filled: true,
                        fillColor: colorScheme.surfaceContainerHighest,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 0,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (value) {
                        setState(() => _searchText = value);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  CustomIconButtonRounded(
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    onPressed: () {
                      //_showFilterBottomSheet(context);
                    },
                    iconData: Icons.filter_list_outlined,
                  ),
                ],
              ),
            ),
          ),
        ),

        ValueListenableBuilder<Box<WorkOrderModel>>(
          valueListenable: sl<HiveWorkOrderService>().itemListener(),
          builder: (context, box, _) {
            final workOrders = box.values.toList().cast<WorkOrderModel>();
            final sortedworkOrders = [...workOrders]
              ..sort((a, b) => b.createdAt!.compareTo(a.createdAt!));

            final filteredWorkOrders = _searchText.isEmpty
                ? sortedworkOrders
                : sortedworkOrders.where((workOrder) {
                    final title = workOrder.title.toLowerCase();
                    final description = workOrder.description!.toLowerCase();
                    return title.contains(_searchText.toLowerCase()) ||
                        description.contains(_searchText.toLowerCase());
                  }).toList();

            if (filteredWorkOrders.isEmpty) {
              return SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: PageEmptyWidget(
                    title: "No Work orders Found",
                    subtitle: "Add a work order to see them here.",
                    icon: Icons.work_history,
                    iconSize: 48,
                  ),
                ),
              );
            }
            final pinnedWorkOrders = filteredWorkOrders
                .where((c) => c.isBookmarked ?? false)
                .toList()
                .reversed
                .toList();

            final workOrderRequests = filteredWorkOrders
                .where((c) =>['REQUEST','new'].contains(c.status))
                .toList()
                .reversed
                .toList();

            final unpinnedWorkOrders = filteredWorkOrders
                .where((c) => c.isBookmarked == false)
                .toList();

            return MultiSliver(
              children: [
                if (pinnedWorkOrders.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16, bottom: 8),
                      child: Text("Bookmarked", style: textTheme.labelLarge),
                    ),
                  ),
                  // ✅ Pinned work orders (horizontal)
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 110,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemBuilder: (context, index) {
                          final workOrder = pinnedWorkOrders[index];
                          return SizedBox(
                            width: 280, // 👈 give fixed width
                            child: PinnedWorkOrderInfoCardWidget(
                              key: ValueKey(workOrder.uid),
                              workOrderInfo: workOrder,
                            ),
                          );
                        },
                        separatorBuilder: (context, index) =>
                            const SizedBox(width: 8),
                        itemCount: pinnedWorkOrders.length,
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 16)),
                  const SliverToBoxAdapter(
                    child: Divider(
                      height: .1,
                      thickness: .1,
                      indent: 16,
                      endIndent: 16,
                    ),
                  ),
                ],

                if (workOrderRequests.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16, bottom: 8, top: 12),
                      child: Text("Requests", style: textTheme.labelLarge),
                    ),
                  ),
                  // ✅ Pinned work orders (horizontal)
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 110,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemBuilder: (context, index) {
                          final workOrder = workOrderRequests[index];
                          return SizedBox(
                            width: 280, // 👈 give fixed width
                            child: PinnedWorkOrderInfoCardWidget(
                              key: ValueKey(workOrder.uid),
                              workOrderInfo: workOrder,
                            ),
                          );
                        },
                        separatorBuilder: (context, index) =>
                            const SizedBox(width: 8),
                        itemCount: workOrderRequests.length,
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 16)),
                  const SliverToBoxAdapter(
                    child: Divider(
                      height: .1,
                      thickness: .1,
                      indent: 16,
                      endIndent: 16,
                    ),
                  ),
                ],

                if (unpinnedWorkOrders.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(
                        left: 16,
                        bottom: 8,
                        top: 12,
                      ),
                      child: Text("All", style: textTheme.labelLarge),
                    ),
                  ),
                  // ✅ Unpinned work orders (vertical)
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    sliver: SliverList.separated(
                      itemBuilder: (context, index) {
                        final workOrder = unpinnedWorkOrders[index];
                        return WorkOrderInfoCardWidget(
                          key: ValueKey(workOrder.uid),
                          workOrderInfo: workOrder,
                        );
                      },
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemCount: unpinnedWorkOrders.length,
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
