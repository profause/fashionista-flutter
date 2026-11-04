import 'package:cached_network_image/cached_network_image.dart';
import 'package:fashionista/core/theme/app.theme.dart';
import 'package:fashionista/core/utils/get_relative_time.dart';
import 'package:fashionista/data/models/author/author_model.dart';
import 'package:fashionista/data/models/notification/notification_model.dart';
import 'package:fashionista/presentation/screens/notification/widgets/notification_tile.dart';
import 'package:fashionista/presentation/widgets/default_profile_avatar_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';

/// Notification card shown to a designer when a client books an appointment.
///
/// Differs from the generic info card by surfacing who booked, so the designer
/// can decide whether to open the request without leaving the list.
class NotificationBookingWidget extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const NotificationBookingWidget({
    super.key,
    required this.notification,
    this.onTap,
    this.onDelete,
  });

  /// Designer-scoped appointments list for the recipient of this notification.
  String get _appointmentsRoute {
    final designerId = notification.to;
    return Uri(
      path: '/designer-bookings',
      queryParameters: {if (designerId.isNotEmpty) 'designerId': designerId},
    ).toString();
  }

  void _openAppointments(BuildContext context) {
    onTap?.call();
    context.push(_appointmentsRoute);
  }

  @override
  Widget build(BuildContext context) {
    final bool unread = notification.status == 'new';
    final author = notification.author;

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
            onTap: () => _openAppointments(context),
            splashColor: context.accent.withValues(alpha: 0.1),
            highlightColor: context.accent.withValues(alpha: 0.05),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  NotificationIconCluster(
                    icon: Icons.event_available_outlined,
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
                        if (author != null && _hasAuthorDetails(author)) ...[
                          const SizedBox(height: 10),
                          _AuthorLine(
                            uid: author.uid ?? '',
                            name: author.name,
                            avatar: author.avatar,
                            mobileNumber: author.mobileNumber,
                          ),
                        ],
                        const SizedBox(height: 12),
                        NotificationCardButton(
                          label: 'View appointments',
                          style: unread
                              ? NotificationCardButtonStyle.primary
                              : NotificationCardButtonStyle.solid,
                          onPressed: () => _openAppointments(context),
                        ),
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

  bool _hasAuthorDetails(AuthorModel author) {
    return (author.name ?? '').toString().trim().isNotEmpty ||
        (author.avatar ?? '').toString().trim().isNotEmpty ||
        (author.mobileNumber ?? '').toString().trim().isNotEmpty;
  }
}

/// The booking client's avatar, name and phone number.
class _AuthorLine extends StatelessWidget {
  final String uid;
  final String? name;
  final String? avatar;
  final String? mobileNumber;

  const _AuthorLine({
    required this.uid,
    this.name,
    this.avatar,
    this.mobileNumber,
  });

  @override
  Widget build(BuildContext context) {
    final hasAvatar = (avatar ?? '').trim().isNotEmpty;
    final displayName = (name ?? '').trim().isEmpty ? 'Client' : name!.trim();
    final phone = (mobileNumber ?? '').trim();

    final fallback = DefaultProfileAvatar(
      uid: uid,
      name: displayName,
      size: 24,
    );

    return Row(
      children: [
        ClipOval(
          child: hasAvatar
              ? CachedNetworkImage(
                  imageUrl: avatar!,
                  width: 24,
                  height: 24,
                  fit: BoxFit.cover,
                  placeholder: (_, _) => fallback,
                  errorWidget: (_, _, _) => fallback,
                )
              : fallback,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            phone.isEmpty ? displayName : '$displayName · $phone',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: context.secondaryLabel,
            ),
          ),
        ),
      ],
    );
  }
}
