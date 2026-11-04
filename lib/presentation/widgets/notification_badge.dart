import 'package:fashionista/core/theme/app.theme.dart';
import 'package:flutter/material.dart';

/// Unread-count pill for the notification bell.
///
/// Hidden at zero and capped at `99+` so the badge never changes width
/// unpredictably.
class NotificationBadge extends StatelessWidget {
  final int count;

  /// Caps the label; counts above this render as `99+`.
  final int maxCount;

  const NotificationBadge({super.key, required this.count, this.maxCount = 99});

  bool get _isVisible => count > 0;

  String get label => count > maxCount ? '$maxCount+' : '$count';

  @override
  Widget build(BuildContext context) {
    if (!_isVisible) return const SizedBox.shrink();

    return Semantics(
      label: '$count unread notification${count == 1 ? '' : 's'}',
      child: Container(
        constraints: const BoxConstraints(minWidth: 16),
        height: 16,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: context.accent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: context.canvasBackground, width: 1.5),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 9,
            fontWeight: FontWeight.w700,
            height: 1,
          ),
        ),
      ),
    );
  }
}
