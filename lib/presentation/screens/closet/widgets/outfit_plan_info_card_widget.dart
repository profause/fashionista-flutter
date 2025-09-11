import 'package:fashionista/data/models/closet/outfit_plan_model.dart';
import 'package:flutter/material.dart';

class OutfitPlanInfoCardWidget extends StatefulWidget {
  final OutfitPlanModel plan;
  final VoidCallback? onTap;

  const OutfitPlanInfoCardWidget({super.key, required this.plan, this.onTap});

  @override
  State<OutfitPlanInfoCardWidget> createState() => _OutfitPlanInfoCardWidgetState();
}

class _OutfitPlanInfoCardWidgetState extends State<OutfitPlanInfoCardWidget> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold();
  }
}