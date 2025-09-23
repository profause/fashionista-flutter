import 'package:fashionista/data/models/work_order/work_order_model.dart';
import 'package:flutter/material.dart';

class ProjectDetailsScreen extends StatefulWidget {
  final WorkOrderModel workOrderInfo;
  const ProjectDetailsScreen({super.key, required this.workOrderInfo});

  @override
  State<ProjectDetailsScreen> createState() => _ProjectDetailsScreenState();
}

class _ProjectDetailsScreenState extends State<ProjectDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold();
  }
}