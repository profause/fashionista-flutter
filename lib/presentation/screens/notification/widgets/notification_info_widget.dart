import 'package:fashionista/core/utils/get_relative_time.dart';
import 'package:fashionista/data/models/notification/notification_model.dart';
import 'package:fashionista/presentation/widgets/custom_icon_rounded.dart';
import 'package:flutter/material.dart';

class NotificationInfoWidget extends StatelessWidget {
  final NotificationModel notification;
  const NotificationInfoWidget({super.key, required this.notification});

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
        leading: CustomIconRounded(icon: Icons.info, size: 24),
        contentPadding: const EdgeInsets.all(0),
        title: Text(
          notification.title,
          style: textTheme.titleSmall!.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(notification.description, style: textTheme.labelMedium),
        trailing: Text(
          formatRelativeTime(notification.createdAt),
          style: textTheme.bodySmall,
        ),
      ),
    );
  }
}
