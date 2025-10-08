import 'package:fashionista/core/theme/app.theme.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class DesignerShimmerWidget extends StatelessWidget {
  const DesignerShimmerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      period: const Duration(seconds: 2), // smooth shimmer speed
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(radius: 24, backgroundColor: AppTheme.lightGrey),
            const SizedBox(height: 8),
            Container(
              height: 10,
              width: 100,
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 40,
              width: 100,
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
