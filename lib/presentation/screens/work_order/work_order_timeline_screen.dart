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
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        foregroundColor: colorScheme.primary,
        backgroundColor: colorScheme.onPrimary,
        elevation: 0,
      ),
      body: SafeArea(
        // 👈 makes sure it stays below status bar
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 16, top: 8),
                child: Text(
                  textAlign: TextAlign.start,
                  'Project Timeline',
                  style: textTheme.titleLarge!.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16, top: 4),
                child: Text(
                  textAlign: TextAlign.start,
                  'Stay on top of deadlines, updates, and progress — all in one place.',
                  style: textTheme.titleSmall,
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: SizedBox(
        height: 40, // default is 48
        child: FloatingActionButton.extended(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          onPressed: () {},
          label: Text(
            "Update timeline",
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
          ),
          extendedPadding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
