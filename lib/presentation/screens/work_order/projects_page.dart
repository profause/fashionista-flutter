import 'package:fashionista/data/models/clients/bloc/client_event.dart';
import 'package:fashionista/data/models/work_order/bloc/work_order_bloc.dart';
import 'package:fashionista/data/models/work_order/bloc/work_order_bloc_event.dart';
import 'package:fashionista/data/models/work_order/bloc/work_order_bloc_state.dart';
import 'package:fashionista/presentation/screens/work_order/widgets/work_order_info_card_widget.dart';
import 'package:fashionista/presentation/widgets/custom_icon_button_rounded.dart';
import 'package:fashionista/presentation/widgets/page_empty_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
        BlocBuilder<WorkOrderBloc, WorkOrderBlocState>(
          builder: (context, state) {
            switch (state) {
              case WorkOrderLoading():
                return const SliverToBoxAdapter(
                  child: SizedBox(
                    height: 400,
                    child: Center(
                      child: SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  ),
                );
              case WorkOrdersLoaded(:final workOrders, :final fromCache):
                final filteredWorkOrders = _searchText.isEmpty
                    ? workOrders
                    : workOrders.where((workOrder) {
                        final title = workOrder.title.toLowerCase();
                        final description = workOrder.description!
                            .toLowerCase();
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
                    .where((c) => c.isBookmarked)
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
                            "Bookmarked",
                            style: textTheme.labelLarge,
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: 100,
                          child: CustomScrollView(
                            scrollDirection: Axis.horizontal,
                            shrinkWrap: true, // ✅ don’t expand infinitely
                            primary: false, // ✅ don’t hijack the parent scroll
                            physics:
                                const ClampingScrollPhysics(), // ✅ smoother nested scroll
                            slivers: [
                              SliverPadding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ), // ✅ add spacing at edges
                                sliver: SliverList(
                                  delegate: SliverChildBuilderDelegate(
                                    (context, index) {
                                      if (index.isEven) {
                                        final workOrder =
                                            pinnedWorkOrders[index ~/ 2];
                                        return WorkOrderInfoCardWidget(
                                          workOrderInfo: workOrder,
                                        );
                                      } else {
                                        return const SizedBox(
                                          width: 8,
                                        ); // separator between items
                                      }
                                    },
                                    childCount: pinnedWorkOrders.length * 2 - 1,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

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
                            top: 8,
                          ),
                          child: Text("All", style: textTheme.labelLarge),
                        ),
                      ),
                      SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          if (index.isEven) {
                            final workOrder = unpinnedWorkOrders[index ~/ 2];
                            return WorkOrderInfoCardWidget(
                              workOrderInfo: workOrder,
                              onTap: () async {
                                // await Navigator.push(
                                //   context,
                                //   MaterialPageRoute(
                                //     builder: (context) =>
                                //        ClientDetailsScreen(client: client),
                                //   ),
                                // );
                              },
                            );
                          } else {
                            return const Divider(
                              height: .1,
                              thickness: .1,
                              indent: 80,
                            );
                          }
                        }, childCount: unpinnedWorkOrders.length * 2 - 1),
                      ),
                    ],
                  ],
                );

              case WorkOrderError(:final message):
                debugPrint(message);
                return SliverToBoxAdapter(
                  child: Center(child: Text("Error: $message")),
                );

              default:
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
