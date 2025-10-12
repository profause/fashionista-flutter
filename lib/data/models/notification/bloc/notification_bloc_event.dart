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

class LoadNotifications extends NotificationBlocEvent {
  final String uid;
  const LoadNotifications(this.uid);

  @override
  List<Object?> get props => [uid];
}

class LoadNotificationsCacheFirstThenNetwork extends NotificationBlocEvent {
  final String uid;
  const LoadNotificationsCacheFirstThenNetwork(this.uid);

  @override
  List<Object?> get props => [uid];
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
