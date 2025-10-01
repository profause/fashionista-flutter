import 'package:fashionista/data/models/clients/client_model.dart';
import 'package:fashionista/data/models/work_order/bloc/work_order_bloc.dart';
import 'package:fashionista/data/models/work_order/bloc/work_order_bloc_event.dart';
import 'package:fashionista/data/models/work_order/bloc/work_order_bloc_state.dart';
import 'package:fashionista/presentation/screens/work_order/widgets/work_order_info_card_widget.dart';
import 'package:fashionista/presentation/widgets/page_empty_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ClientProjectPage extends StatefulWidget {
  final Client client;
  const ClientProjectPage({super.key, required this.client});

  @override
  State<ClientProjectPage> createState() => _ClientProjectPageState();
}

class _ClientProjectPageState extends State<ClientProjectPage> {
  @override
  void initState() {
    context.read<WorkOrderBloc>().add(
      LoadWorkOrdersByClientId(widget.client.uid),
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    //final colorScheme = Theme.of(context).colorScheme;
    //final textTheme = Theme.of(context).textTheme;
    return BlocBuilder<WorkOrderBloc, WorkOrderBlocState>(
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
          case WorkOrdersLoaded(:final workOrders, :final fromCache):
            final filteredWorkOrders = workOrders;

            if (filteredWorkOrders.isEmpty) {
              return Center(
                child: PageEmptyWidget(
                  title: "No Work orders Found",
                  subtitle: "Add a work order to see them here.",
                  icon: Icons.work_history,
                  iconSize: 48,
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.only(top: 8, left: 12, right: 12),
              itemBuilder: (context, index) {
                final workOrder = filteredWorkOrders[index];
                return WorkOrderInfoCardWidget(
                  workOrderInfo: workOrder,
                  onTap: () {
                    context.read<WorkOrderBloc>().add(
                      const LoadWorkOrdersCacheFirstThenNetwork(''),
                    );
                  },
                );
              },
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemCount: filteredWorkOrders.length,
            );

          case WorkOrderError(:final message):
            debugPrint(message);
            return Center(child: Text("Error: $message"));

          default:
            return Center(
              child: PageEmptyWidget(
                title: "No Work orders Found",
                subtitle: "Add a work order to see them here.",
                icon: Icons.work_history,
                iconSize: 48,
              ),
            );
        }
      },
    );
  }
}
