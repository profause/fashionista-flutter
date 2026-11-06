import 'package:cached_network_image/cached_network_image.dart';
import 'package:fashionista/core/theme/app.theme.dart';
import 'package:fashionista/core/utils/get_relative_time.dart';
import 'package:fashionista/data/models/notification/notification_model.dart';
import 'package:fashionista/presentation/screens/notification/widgets/notification_tile.dart';
import 'package:fashionista/presentation/widgets/default_profile_avatar_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';

/// Notification card shown to a designer when a client reviews them.
///
/// Surfaces the star rating when the payload carried one, so the designer can
/// judge the review before opening their profile.
class NotificationReviewWidget extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const NotificationReviewWidget({
    super.key,
    required this.notification,
    this.onTap,
    this.onDelete,
  });

  /// Star rating carried by the push, or `null` when the review had none.
  ///
  /// Older notifications were written before the rating was added to the
  /// payload, so absence is expected rather than an error.
  int? get _rating {
    final raw = notification.data?['rating']?.trim();
    if (raw == null || raw.isEmpty) return null;

    final parsed = int.tryParse(raw) ?? double.tryParse(raw)?.round();
    if (parsed == null || parsed < 1 || parsed > 5) return null;
    return parsed;
  }

  /// The review lives on the designer's profile, addressed by the designer id
  /// (not the review document id), matching `NotificationRouter`.
  String? get _profileRoute {
    final designerId = (notification.data?['designer_id'] ?? '').trim();
    if (designerId.isEmpty) return null;
    return '/designers/$designerId';
  }

  void _openProfile(BuildContext context) {
    onTap?.call();

    final route = _profileRoute;
    if (route == null) return;
    context.push(route);
  }

  @override
  Widget build(BuildContext context) {
    final bool unread = notification.status == 'new';
    final rating = _rating;
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
            onTap: () => _openProfile(context),
            splashColor: context.accent.withValues(alpha: 0.1),
            highlightColor: context.accent.withValues(alpha: 0.05),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  NotificationIconCluster(
                    icon: Icons.star_border,
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
                        if (rating != null) ...[
                          const SizedBox(height: 6),
                          _RatingStars(rating: rating),
                        ],
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
                        if (hasAuthor) ...[
                          const SizedBox(height: 10),
                          _AuthorLine(
                            uid: author?.uid ?? '',
                            name: authorName,
                            avatar: author?.avatar,
                          ),
                        ],
                        if (_profileRoute != null) ...[
                          const SizedBox(height: 12),
                          NotificationCardButton(
                            label: 'View profile',
                            style: unread
                                ? NotificationCardButtonStyle.primary
                                : NotificationCardButtonStyle.solid,
                            onPressed: () => _openProfile(context),
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

/// Five stars, filled up to [rating].
class _RatingStars extends StatelessWidget {
  final int rating;

  const _RatingStars({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$rating out of 5 stars',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(5, (index) {
          final filled = index < rating;
          return Padding(
            padding: const EdgeInsets.only(right: 2),
            child: Icon(
              filled ? Icons.star_rounded : Icons.star_outline_rounded,
              size: 16,
              color: filled ? AppTheme.appIconColor : context.mutedText,
            ),
          );
        }),
      ),
    );
  }
}

/// The reviewer's avatar and name.
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
