import 'package:fashionista/data/models/work_order/work_order_model.dart';
import 'package:flutter/material.dart';

class WorkOrderTimelineScreen extends StatefulWidget {
  final WorkOrderModel workOrderInfo; // 👈 workOrderInfo
  const WorkOrderTimelineScreen({super.key, required this.workOrderInfo});

  @override
  State<WorkOrderTimelineScreen> createState() =>
      _WorkOrderTimelineScreenState();
}

class _WorkOrderTimelineScreenState extends State<WorkOrderTimelineScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        // 👈 makes sure it stays below status bar
        child: Stack(
          children: [
            // Your main page content goes here
            const Center(child: Text("Timeline")),

            // Back arrow on top-left
            Positioned(
              top: 8,
              left: 8,
              child: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
