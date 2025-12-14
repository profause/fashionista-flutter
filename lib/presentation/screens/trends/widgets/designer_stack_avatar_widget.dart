
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class DesignerStackAvatarWidget extends StatelessWidget {
  const DesignerStackAvatarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    //final colorScheme = Theme.of(context).colorScheme;
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      period: const Duration(seconds: 2), // smooth shimmer speed
      child: CircleAvatar(
        radius: 24,
        child: Container(
          margin: const EdgeInsets.all(2),
          clipBehavior: Clip.antiAlias,
          decoration: const BoxDecoration(shape: BoxShape.circle),
        ),
      ),
    );
  }
}
