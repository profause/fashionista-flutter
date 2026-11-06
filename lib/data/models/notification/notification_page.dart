import 'package:equatable/equatable.dart';
import 'package:fashionista/data/models/notification/notification_model.dart';

/// One page of the notification inbox, newest first.
///
/// The cursor is the Firestore document snapshot of the last returned row, not
/// its timestamp: two notifications created in the same millisecond would
/// otherwise be skipped or fetched twice.
class NotificationPage extends Equatable {
  final List<NotificationModel> notifications;

  /// Opaque cursor for the next page; `null` on an empty page.
  ///
  /// Production carries a Firestore `DocumentSnapshot`; keeping the type
  /// opaque here lets the bloc be unit tested without a live Firestore, and
  /// confines the cast to the service.
  final Object? cursor;

  /// Exact: derived from a `limit + 1` probe, not a heuristic.
  final bool hasMore;

  const NotificationPage({
    required this.notifications,
    this.cursor,
    this.hasMore = false,
  });

  static const NotificationPage empty = NotificationPage(notifications: []);

  bool get isEmpty => notifications.isEmpty;

  @override
  List<Object?> get props => [notifications, cursor, hasMore];
}
