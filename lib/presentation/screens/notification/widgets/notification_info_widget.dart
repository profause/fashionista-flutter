import 'package:fashionista/core/utils/get_relative_time.dart';
import 'package:fashionista/data/models/notification/notification_model.dart';
import 'package:fashionista/presentation/widgets/custom_icon_rounded.dart';
import 'package:flutter/material.dart';

class NotificationInfoWidget extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback? onTap; // 👈 optional callback when tapped

  const NotificationInfoWidget({
    super.key,
    required this.notification,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: colorScheme.onPrimary, // 👈 Needed for ripple to show
      child: InkWell(
        onTap: onTap ?? () {}, // 👈 Trigger ripple effect
        splashColor: colorScheme.primary.withOpacity(0.1),
        highlightColor: colorScheme.primary.withOpacity(0.05),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: ListTile(
            visualDensity: VisualDensity.compact,
            contentPadding: EdgeInsets.zero,
            leading: CustomIconRounded(icon: Icons.info, size: 24),
            title: Text(
              notification.title,
              style: textTheme.titleSmall!.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              notification.description,
              style: textTheme.labelMedium,
            ),
            trailing: Text(
              formatRelativeTime(notification.createdAt),
              style: textTheme.bodySmall,
            ),
          ),
        ),
      ),
    );
  }
}
