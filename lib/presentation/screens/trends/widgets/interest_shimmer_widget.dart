import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class InterestShimmerWidget extends StatelessWidget {
  final double width; 
  const InterestShimmerWidget({super.key, required this.width});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      period: const Duration(seconds: 2), // smooth shimmer speed
      child: Container(
        height: 40,
        width: width,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}
