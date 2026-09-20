import 'package:fashionista/core/theme/app.theme.dart';
import 'package:flutter/material.dart';

/// Compact shortcut tile used by the quick actions grid on the For You tab
/// (Stitch: 48px tall card with a label, optional accessory and chevron).
class QuickActionTileWidget extends StatelessWidget {
  const QuickActionTileWidget({
    super.key,
    required this.label,
    this.trailing,
    this.onTap,
  });

  final String label;

  /// Optional accessory rendered between the label and the chevron.
  final Widget? trailing;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SizedBox(
      height: 48,
      child: Material(
        color: context.cardSurface,
        borderRadius: BorderRadius.circular(10),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: context.hairline),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyMedium?.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      height: 1.2,
                    ),
                  ),
                ),
                if (trailing != null) ...[const SizedBox(width: 8), trailing!],
                const SizedBox(width: 6),
                Icon(
                  Icons.chevron_right,
                  size: 16,
                  color: context.mutedText,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
