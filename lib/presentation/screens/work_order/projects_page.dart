import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/core/theme/app.theme.dart';
import 'package:fashionista/data/models/work_order/work_order_model.dart';
import 'package:fashionista/data/services/hive/hive_work_order_service.dart';
import 'package:fashionista/presentation/screens/work_order/widgets/pinned_work_order_info_card_widget.dart';
import 'package:fashionista/presentation/screens/work_order/widgets/work_order_info_card_widget.dart';
import 'package:fashionista/presentation/widgets/page_empty_widget.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:sliver_tools/sliver_tools.dart';

class ProjectsPage extends StatefulWidget {
  const ProjectsPage({super.key});

  @override
  State<ProjectsPage> createState() => _ProjectsPageState();
}

class _ProjectsPageState extends State<ProjectsPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchText = "";

  @override
  void initState() {
    // context.read<WorkOrderBloc>().add(
    //   const LoadWorkOrdersCacheFirstThenNetwork(''),
    // );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MultiSliver(
      // 👈 helper from 'sliver_tools' package, or just return a Column of slivers
      children: [
        SliverAppBar(
          backgroundColor: context.canvasBackground,
          pinned: true, // keeps the searchbar visible when collapsed
          floating: true, // allows it to appear/disappear as you scroll
          snap: true, // snaps into view when scrolling up
          stretch: true,
          expandedHeight: 18,
          toolbarHeight: 5,
          flexibleSpace: FlexibleSpaceBar(
            background: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Row(
                children: [
                  Expanded(child: _buildSearchField()),
                  const SizedBox(width: 12),
                  _buildFilterButton(),
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
                      child: Text(
                        "BOOKMARKED (${pinnedWorkOrders.length})",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: context.mutedText,
                        ),
                      ),
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
                  const SliverToBoxAdapter(child: SizedBox(height: 12)),
                ],

                if (workOrderRequests.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16, bottom: 8, top: 12),
                      child: Text(
                        "REQUESTS (${workOrderRequests.length})",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: context.mutedText,
                        ),
                      ),
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
                  const SliverToBoxAdapter(child: SizedBox(height: 12)),
                ],

                if (unpinnedWorkOrders.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(
                        left: 16,
                        bottom: 8,
                        top: 12,
                      ),
                      child: Text(
                        "ALL (${unpinnedWorkOrders.length})",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: context.mutedText,
                        ),
                      ),
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
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Widget _buildSearchField() {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: context.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _searchFocusNode.hasFocus ? context.accent : context.hairline,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.search, size: 18, color: context.placeholderText),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              style: TextStyle(
                fontSize: 15,
                color: context.onCanvasText,
              ),
              decoration: InputDecoration(
                hintText: "Search projects...",
                hintStyle: TextStyle(
                  fontSize: 15,
                  color: context.placeholderText,
                ),
                isDense: true,
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (value) {
                setState(() => _searchText = value);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton() {
    return SizedBox(
      width: 44,
      height: 44,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: context.cardSurface,
          side: BorderSide(color: context.hairline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: EdgeInsets.zero,
          minimumSize: const Size(44, 44),
        ),
        onPressed: () {},
        child: Icon(
          Icons.filter_list_outlined,
          size: 20,
          color: context.onCanvasText,
        ),
      ),
    );
  }
}
