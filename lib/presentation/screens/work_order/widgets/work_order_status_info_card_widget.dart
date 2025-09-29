import 'package:fashionista/data/models/work_order/work_order_status_progress_model.dart';
import 'package:flutter/material.dart';

class WorkOrderStatusInfoCardWidget extends StatefulWidget {
  final WorkOrderStatusProgressModel workOrderStatusInfo;
  final VoidCallback? onTap; // Callback for navigation or action
  const WorkOrderStatusInfoCardWidget({super.key, required this.workOrderStatusInfo, this.onTap});

  @override
  State<WorkOrderStatusInfoCardWidget> createState() => _WorkOrderStatusInfoCardWidgetState();
}

class _WorkOrderStatusInfoCardWidgetState extends State<WorkOrderStatusInfoCardWidget> {
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}