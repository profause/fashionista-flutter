
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

  /// `true` when another page may exist.
  final bool hasMore;

  /// A subsequent page is in flight; the list stays on screen.
  final bool isLoadingMore;

  /// A subsequent page failed; the list stays on screen and offers a retry.
  final String? loadMoreError;

  NotificationsLoaded(
    this.notifications, {
    this.fromCache = false,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.loadMoreError,
    int? unreadCount,
  }) : super(
         notificationCount:
             unreadCount ??
             notifications.where((n) => n.status == 'new').length,
       );

  NotificationsLoaded copyWith({
    List<NotificationModel>? notifications,
    bool? fromCache,
    bool? hasMore,
    bool? isLoadingMore,
    String? loadMoreError,
    bool clearLoadMoreError = false,
    int? unreadCount,
  }) {
    return NotificationsLoaded(
      notifications ?? this.notifications,
      fromCache: fromCache ?? this.fromCache,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      loadMoreError: clearLoadMoreError
          ? null
          : (loadMoreError ?? this.loadMoreError),
      unreadCount: unreadCount ?? notificationCount,
    );
  }

  @override
  List<Object?> get props => [
    notifications,
    fromCache,
    hasMore,
    isLoadingMore,
    loadMoreError,
    notificationCount,
  ];
}

/// Result of a mark-all-read action.
class NotificationsMarkedRead extends NotificationBlocState {
  final int affected;
  const NotificationsMarkedRead(this.affected) : super(notificationCount: 0);

  @override
  List<Object?> get props => [affected];
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