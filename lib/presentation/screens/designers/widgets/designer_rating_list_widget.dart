import 'package:flutter/material.dart';

class DesignerRatingListWidget extends StatelessWidget {
  final Map<String, double> ratings;
  final int totalRating;

  const DesignerRatingListWidget({super.key, required this.ratings, required this.totalRating});

  @override
  Widget build(BuildContext context) {
    final entries = ratings.entries.toList()
      ..sort((a, b) => int.parse(b.key).compareTo(int.parse(a.key))); // 5→1 order

    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(entries.length, (index) {
        final rating = entries[index];
        final stars = int.parse(rating.key);
        final count = rating.value;
        final progress = totalRating == 0 ? 0.0 : count / totalRating;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              // Rating label (e.g. "5 ★")
              SizedBox(
                width: 40,
                child: Text(
                  '$stars ★',
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Animated progress bar
              Expanded(
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: progress),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOutCubic,
                  builder: (context, animatedValue, _) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: animatedValue,
                        minHeight: 8,
                        backgroundColor: colorScheme.surfaceContainerHighest,
                        color: Colors.amber,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
