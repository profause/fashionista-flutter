import 'package:equatable/equatable.dart';
import 'package:fashionista/data/models/notification/notification_model.dart';

abstract class NotificationBlocEvent extends Equatable {
  const NotificationBlocEvent();
  @override
  List<Object?> get props => [];
}

class LoadNotification extends NotificationBlocEvent {
  final String uid;
  const LoadNotification(this.uid);
  @override
  List<Object?> get props => [uid];
}

class UpdateNotification extends NotificationBlocEvent {
  final NotificationModel notification;
  const UpdateNotification(this.notification);

  @override
  List<Object?> get props => [notification];
}

class LoadNotificationsByFrom extends NotificationBlocEvent {
  final String uid;
  const LoadNotificationsByFrom(this.uid);

  @override
  List<Object?> get props => [uid];
}


class NotificationsCounter extends NotificationBlocEvent {
  final String uid;
  const NotificationsCounter(this.uid);

  @override
  List<Object?> get props => [uid];
}

class DeleteNotification extends NotificationBlocEvent {
  final String uid;
  const DeleteNotification(this.uid);

  @override
  List<Object?> get props => [uid];
}

class ClearNotification extends NotificationBlocEvent {
  const ClearNotification();
}

/// Marks every unread notification of [uid] as read.
class MarkAllNotificationsRead extends NotificationBlocEvent {
  final String uid;
  const MarkAllNotificationsRead(this.uid);

  @override
  List<Object?> get props => [uid];
}

/// Loads the newest page of the inbox, newest first.
///
/// Always starts from the top: [refresh] discards the current list and cursor,
/// which is also what pull-to-refresh uses.
class LoadNotificationsPage extends NotificationBlocEvent {
  final String uid;
  final int limit;
  final bool refresh;

  const LoadNotificationsPage(
    this.uid, {
    this.limit = 20,
    this.refresh = false,
  });

  @override
  List<Object?> get props => [uid, limit, refresh];
}

/// Appends the next page using the cursor of the last loaded row.
class LoadMoreNotifications extends NotificationBlocEvent {
  const LoadMoreNotifications();

  @override
  List<Object?> get props => const [];
}
