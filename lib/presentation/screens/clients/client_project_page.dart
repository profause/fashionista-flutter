import 'package:fashionista/core/theme/app.theme.dart';
import 'package:fashionista/data/models/clients/client_model.dart';
import 'package:fashionista/data/models/work_order/bloc/work_order_bloc.dart';
import 'package:fashionista/data/models/work_order/bloc/work_order_bloc_event.dart';
import 'package:fashionista/data/models/work_order/bloc/work_order_bloc_state.dart';
import 'package:fashionista/presentation/screens/work_order/widgets/work_order_info_card_widget.dart';
import 'package:fashionista/presentation/widgets/page_empty_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sliver_tools/sliver_tools.dart';

class ClientProjectPage extends StatefulWidget {
  final Client client;
  const ClientProjectPage({super.key, required this.client});

  @override
  State<ClientProjectPage> createState() => _ClientProjectPageState();
}

class _ClientProjectPageState extends State<ClientProjectPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchText = "";
  @override
  void initState() {
    context.read<WorkOrderBloc>().add(
      LoadWorkOrdersByClientId(widget.client.uid),
    );
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    //final textTheme = Theme.of(context).textTheme;
    return MultiSliver(
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
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: context.cardSurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _searchFocusNode.hasFocus
                              ? context.accent
                              : context.hairline,
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
                          Icon(
                            Icons.search,
                            size: 18,
                            color: context.mutedText,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              focusNode: _searchFocusNode,
                              cursorColor: context.accent,
                              style: TextStyle(
                                fontSize: 15,
                                color: context.onCanvasText,
                              ),
                              decoration: InputDecoration(
                                hintText: "Search clients...",
                                hintStyle: TextStyle(
                                  fontSize: 15,
                                  color: context.mutedText,
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
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: Material(
                      color: colorScheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(color: context.hairline),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () => {
                          //herheher
                          context.push('/workorders/add'),
                        },
                        child: Icon(
                          Icons.add,
                          size: 20,
                          color: colorScheme.onPrimary,
                        ),
                      ),
                    ),
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
                return SizedBox(
                  height: 400,
                  child: Center(
                    child: SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(),
                    ),
                  ),
                );
              case WorkOrdersLoaded(:final workOrders):
                final filteredWorkOrders = workOrders;

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

                return SliverPadding(
                  padding: const EdgeInsets.only(top: 4, left: 12, right: 12),
                  sliver: SliverList.separated(
                    itemBuilder: (context, index) {
                      final workOrder = filteredWorkOrders[index];
                      return WorkOrderInfoCardWidget(
                        key: ValueKey(workOrder.uid),
                        workOrderInfo: workOrder,
                      );
                    },
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemCount: filteredWorkOrders.length,
                  ),
                );

              case WorkOrderError(:final message):
                return SliverFillRemaining(
                  hasScrollBody: false,
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
}
