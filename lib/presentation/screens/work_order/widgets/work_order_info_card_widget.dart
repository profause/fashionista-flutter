import 'package:fashionista/data/models/work_order/work_order_model.dart';
import 'package:fashionista/presentation/screens/work_order/project_details_screen.dart';
import 'package:flutter/material.dart';

class WorkOrderInfoCardWidget extends StatelessWidget {
  final WorkOrderModel workOrderInfo;
  final VoidCallback? onTap; // Callback for navigation or action

  const WorkOrderInfoCardWidget({
    super.key,
    required this.workOrderInfo,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap:
          onTap ??
          () {
            //context.read<ClientCubit>().updateClient(widget.clientInfo);
            // Example: Navigate to Client Details Screen
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    ProjectDetailsScreen(workOrderInfo: workOrderInfo),
              ),
            );
          },

      child: Container(),
    );
  }
}
