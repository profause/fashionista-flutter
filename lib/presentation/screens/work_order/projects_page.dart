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
    String selectedFilter = 'All';
  String? showAs = "list";

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
        onPressed: () {
          _showFilterBottomsheet(
                          context,
                          showAs!,
                          selectedFilter,
                          (filter) =>
                              setState(() => selectedFilter = filter),
                        );
        },
        child: Icon(
          Icons.filter_list_outlined,
          size: 20,
          color: context.onCanvasText,
        ),
      ),
    );
  }

  void _showFilterBottomsheet(
    BuildContext context,
    String showAs,
    String selectedFilter,
    Function(String) onFilterSelected,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.cardSurface,
      barrierColor: const Color(0x66000000),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        String tempShowAs = showAs; // copy parent value
        String tempFilter = selectedFilter;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 6,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color:
                              Theme.of(context).brightness == Brightness.dark
                                  ? const Color(0xFF3A3938)
                                  : const Color(0xFFD1D5DB),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const _FilterSheetLabel("Show as"),
                    const SizedBox(height: 10),
                    _FilterOptionCard(
                      children: [
                        _FilterRadioRow(
                          label: "List",
                          value: "list",
                          groupValue: tempShowAs,
                          onChanged: (val) {
                            setModalState(() => tempShowAs = val);
                            setState(() => showAs = val);
                          },
                        ),
                        _FilterRadioRow(
                          label: "Grid",
                          value: "grid",
                          groupValue: tempShowAs,
                          onChanged: (val) {
                            setModalState(() => tempShowAs = val);
                            setState(() => showAs = val);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const _FilterSheetLabel("Filter by"),
                    const SizedBox(height: 10),
                    _FilterOptionCard(
                      children: [
                        _FilterRadioRow(
                          label: "All",
                          value: "All",
                          groupValue: tempFilter,
                          onChanged: (val) {
                            setModalState(() => tempFilter = val);
                            setState(() => selectedFilter = val);
                            onFilterSelected(val);
                          },
                        ),
                        _FilterRadioRow(
                          label: "Newest",
                          value: "Newest",
                          groupValue: tempFilter,
                          onChanged: (val) {
                            setModalState(() => tempFilter = val);
                            setState(() => selectedFilter = val);
                            onFilterSelected(val);
                          },
                        ),
                        _FilterRadioRow(
                          label: "Pinned",
                          value: "Pinned",
                          groupValue: tempFilter,
                          onChanged: (val) {
                            setModalState(() => tempFilter = val);
                            setState(() => selectedFilter = val);
                            onFilterSelected(val);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _FilterSheetLabel extends StatelessWidget {
  final String text;
  const _FilterSheetLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: context.mutedText,
      ),
    );
  }
}

class _FilterOptionCard extends StatelessWidget {
  final List<Widget> children;
  const _FilterOptionCard({required this.children});

  @override
  Widget build(BuildContext context) {
    final divider = Divider(color: context.hairline, height: 1, thickness: 1);
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) rows.add(divider);
      rows.add(children[i]);
    }
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: context.canvasBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.hairline),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(children: rows),
      ),
    );
  }
}

class _FilterRadioRow extends StatelessWidget {
  final String label;
  final String value;
  final String groupValue;
  final ValueChanged<String> onChanged;

  const _FilterRadioRow({
    required this.label,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final bool isSelected = groupValue == value;
    return SizedBox(
      height: 52,
      child: InkWell(
        onTap: () => onChanged(value),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: context.onCanvasText,
              ),
            ),
            const Spacer(),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  width: 2,
                  color: isSelected
                      ? context.accent
                      : (Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF3A3938)
                          : const Color(0xFFCBD5E1)),
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: context.accent,
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}