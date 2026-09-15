import 'package:fashionista/core/theme/app.theme.dart';
import 'package:fashionista/core/utils/get_relative_time.dart';
import 'package:fashionista/data/models/notification/notification_model.dart';
import 'package:fashionista/presentation/screens/notification/widgets/notification_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';

class NotificationWorkOrderStatusWidget extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const NotificationWorkOrderStatusWidget({
    super.key,
    required this.notification,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final bool unread = notification.status == 'new';

    return Slidable(
      key: ValueKey(notification.uid),
      endActionPane: ActionPane(
        motion: const BehindMotion(),
        dismissible: DismissiblePane(onDismissed: () {}),
        children: [
          SlidableAction(
            onPressed: (BuildContext context) {
              onDelete?.call();
            },
            backgroundColor: AppTheme.appIconColor,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: 'Delete',
          ),
        ],
      ),
      child: NotificationTileCard(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap ?? () {},
            splashColor: context.accent.withValues(alpha: 0.1),
            highlightColor: context.accent.withValues(alpha: 0.05),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  NotificationIconCluster(
                    icon: Icons.update,
                    unread: unread,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        NotificationTitleRow(
                          title: notification.title,
                          time: formatRelativeTime(notification.createdAt),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          notification.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            color: context.descriptionText,
                            height: 1.6,
                          ),
                        ),
                        if (unread) ...[
                          const SizedBox(height: 12),
                          NotificationCardButton(
                            label: 'View Update',
                            onPressed: () {
                              onTap?.call();
                              context.push(
                                '/workorders/timeline/${notification.refId}',
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}