import 'package:fashionista/core/utils/get_relative_time.dart';
import 'package:fashionista/data/models/notification/notification_model.dart';
import 'package:fashionista/presentation/widgets/custom_icon_rounded.dart';
import 'package:flutter/material.dart';

class NotificationWorkOrderRequestWidget extends StatelessWidget {
  final NotificationModel notification;
  const NotificationWorkOrderRequestWidget({
    super.key,
    required this.notification,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 2, top: 4),
      decoration: BoxDecoration(
        color: colorScheme.onPrimary,
        borderRadius: BorderRadius.circular(0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        visualDensity: VisualDensity.compact,
        leading: CustomIconRounded(icon: Icons.work_history, size: 24),
        contentPadding: const EdgeInsets.all(0),
        title: Text(
          notification.title,
          style: textTheme.titleSmall!.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(notification.description, style: textTheme.labelMedium),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                //TextButton
                TextButton(
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () {},
                  child: Text("View", style: textTheme.bodySmall),
                ),
                //TextButton
                const SizedBox(width: 12),
                TextButton(
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () {},
                  child: Text("Cancel", style: textTheme.bodySmall),
                ),
              ],
            ),
          ],
        ),
        trailing: Text(
          formatRelativeTime(notification.createdAt),
          style: textTheme.bodySmall,
        ),
      ),
    );
  }
}
