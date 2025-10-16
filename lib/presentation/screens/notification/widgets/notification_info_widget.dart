import 'package:fashionista/core/theme/app.theme.dart';
import 'package:fashionista/core/utils/get_relative_time.dart';
import 'package:fashionista/data/models/notification/notification_model.dart';
import 'package:fashionista/presentation/widgets/custom_icon_rounded.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class NotificationInfoWidget extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback? onTap;
  final VoidCallback? onDelete; // 👈 optional callback when tapped

  const NotificationInfoWidget({
    super.key,
    required this.notification,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Slidable(
      key: ValueKey(notification.uid), // 👈 Use stable unique key
      endActionPane: ActionPane(
        motion: const BehindMotion(),
        dismissible: DismissiblePane(onDismissed: () {}),
        children: [
          SlidableAction(
            onPressed: (BuildContext context) {
              onDelete?.call();
            },
            backgroundColor: AppTheme.appIconColor,
            foregroundColor: colorScheme.primary,
            icon: Icons.delete,
            label: 'Delete',
          ),
        ],
      ),
      child: Material(
        color: colorScheme.onPrimary, // 👈 Needed for ripple to show
        child: InkWell(
          onTap: onTap ?? () {}, // 👈 Trigger ripple effect
          splashColor: colorScheme.primary.withValues(alpha: 0.1),
          highlightColor: colorScheme.primary.withValues(alpha: 0.05),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: ListTile(
              visualDensity: VisualDensity.compact,
              contentPadding: EdgeInsets.zero,
              leading: Stack(
                children: [
                  CustomIconRounded(icon: Icons.info, size: 24),
                  if (notification.status == 'new')
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppTheme.appIconColor.withValues(alpha: 0.6),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              title: Text(
                notification.title,
                style: textTheme.titleSmall!.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 3.0),
                child: Text(
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  notification.description,
                  style: textTheme.labelMedium,
                ),
              ),
              trailing: Text(
                formatRelativeTime(notification.createdAt),
                style: textTheme.bodySmall,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
