import 'package:cached_network_image/cached_network_image.dart';
import 'package:fashionista/core/theme/app.theme.dart';
import 'package:fashionista/core/utils/get_relative_time.dart';
import 'package:fashionista/data/models/notification/notification_model.dart';
import 'package:fashionista/presentation/screens/notification/widgets/notification_tile.dart';
import 'package:fashionista/presentation/widgets/default_profile_avatar_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';

/// Notification card shown to the author of a trend when someone likes it or
/// comments on it.
///
/// Sends the user straight to the post instead of the generic info card, which
/// cannot offer a destination.
class NotificationTrendWidget extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const NotificationTrendWidget({
    super.key,
    required this.notification,
    this.onTap,
    this.onDelete,
  });

  /// Likes and comments share the `trend` type, so the icon follows the event.
  IconData get _icon =>
      notification.event == 'trend_commented'
          ? Icons.mode_comment_outlined
          : Icons.favorite_border;

  /// The trend the notification points at, when the payload carried its id.
  String? get _trendRoute {
    final trendId = (notification.refId ?? '').trim();
    if (trendId.isEmpty) return null;
    return '/trends/$trendId';
  }

  void _openTrend(BuildContext context) {
    onTap?.call();

    final route = _trendRoute;
    if (route == null) return;
    context.push(route);
  }

  @override
  Widget build(BuildContext context) {
    final bool unread = notification.status == 'new';
    final author = notification.author;
    final authorName = (author?.name ?? '').trim();
    final hasAuthor = authorName.isNotEmpty;

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
            onTap: () => _openTrend(context),
            splashColor: context.accent.withValues(alpha: 0.1),
            highlightColor: context.accent.withValues(alpha: 0.05),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  NotificationIconCluster(
                    icon: _icon,
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
                        // Server-written notifications carry the liker in the
                        // body only; the snapshot is shown when present.
                        if (hasAuthor) ...[
                          const SizedBox(height: 10),
                          _AuthorLine(
                            uid: author?.uid ?? '',
                            name: authorName,
                            avatar: author?.avatar,
                          ),
                        ],
                        if (_trendRoute != null) ...[
                          const SizedBox(height: 12),
                          NotificationCardButton(
                            label: 'View trend',
                            style: unread
                                ? NotificationCardButtonStyle.primary
                                : NotificationCardButtonStyle.solid,
                            onPressed: () => _openTrend(context),
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

/// The actor's avatar and name.
class _AuthorLine extends StatelessWidget {
  final String uid;
  final String name;
  final String? avatar;

  const _AuthorLine({required this.uid, required this.name, this.avatar});

  @override
  Widget build(BuildContext context) {
    final hasAvatar = (avatar ?? '').trim().isNotEmpty;

    final fallback = DefaultProfileAvatar(uid: uid, name: name, size: 24);

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
            name,
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
