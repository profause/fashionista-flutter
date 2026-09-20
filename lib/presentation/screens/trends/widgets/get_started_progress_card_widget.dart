import 'package:fashionista/core/theme/app.theme.dart';
import 'package:flutter/material.dart';

/// Compact onboarding tracker card used by the "Get started" row on the
/// For You tab (Stitch: 160x110 card with a circular progress indicator).
class GetStartedProgressCardWidget extends StatelessWidget {
  const GetStartedProgressCardWidget({
    super.key,
    required this.title,
    required this.subtitle,
    required this.progress,
    this.onTap,
  });

  final String title;
  final String subtitle;

  /// Normalised progress (0.0 – 1.0). Values outside the range are clamped.
  final double progress;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final double value = progress.isFinite ? progress.clamp(0.0, 1.0) : 0.0;

    return SizedBox(
      width: 160,
      height: 110,
      child: Material(
        color: context.cardSurface,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.hairline),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    value: value,
                    strokeWidth: 3.5,
                    strokeCap: StrokeCap.round,
                    backgroundColor: context.hairline,
                    valueColor: AlwaysStoppedAnimation<Color>(context.accent),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleSmall?.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.labelSmall?.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0,
                        height: 1.2,
                        color: context.mutedText,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
