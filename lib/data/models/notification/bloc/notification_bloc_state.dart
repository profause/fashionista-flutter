
import 'package:equatable/equatable.dart';
import 'package:fashionista/data/models/notification/notification_model.dart';

class NotificationBlocState extends Equatable {
  final int notificationCount;
  const NotificationBlocState({this.notificationCount = 0});
  @override
  List<Object?> get props => [notificationCount];
}

class NotificationInitial extends NotificationBlocState {
  const NotificationInitial({super.notificationCount = 0});
}

class NotificationLoading extends NotificationBlocState {
  const NotificationLoading({super.notificationCount = 0});
}

class NotificationLoaded extends NotificationBlocState {
  final NotificationModel notification;
  const NotificationLoaded(this.notification);

  @override
  List<Object?> get props => [notification];
}

class NotificationUpdated extends NotificationBlocState {
  final NotificationModel notification;
  const NotificationUpdated(this.notification);
  @override
  List<Object?> get props => [notification];
}

class NotificationsLoaded extends NotificationBlocState {
  final List<NotificationModel> notifications;
  final bool fromCache;
  const NotificationsLoaded(this.notifications, {this.fromCache = false})
    : super(notificationCount: notifications.length);

  @override
  List<Object?> get props => [notifications, fromCache, notificationCount];
}

class NotificationsCounted extends NotificationBlocState {
  const NotificationsCounted(int count) : super(notificationCount: count);
  @override
  List<Object?> get props => [notificationCount];
}

class NotificationsEmpty extends NotificationBlocState {
  const NotificationsEmpty();
}

class NotificationError extends NotificationBlocState {
  final String message;
  const NotificationError(this.message, {super.notificationCount = 0});

  @override
  List<Object?> get props => [message, notificationCount];
}

class NotificationsNewData extends NotificationBlocState {
  final List<NotificationModel> notifications;
  const NotificationsNewData(this.notifications);

  @override
  List<Object?> get props => [notifications];
}

class NotificationDeleted extends NotificationBlocState {
  final String message;
  const NotificationDeleted(this.message, {super.notificationCount = 0});
  @override
  List<Object?> get props => [message, notificationCount];
}