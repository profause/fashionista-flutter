import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/data/models/notification/bloc/notification_bloc_event.dart';
import 'package:fashionista/data/models/notification/bloc/notification_bloc_state.dart';
import 'package:fashionista/data/models/notification/notification_model.dart';
import 'package:fashionista/data/services/firebase/firebase_notification_service.dart';
import 'package:fashionista/data/services/hive/hive_notification_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class NotificationBloc
    extends Bloc<NotificationBlocEvent, NotificationBlocState> {
  NotificationBloc() : super(const NotificationInitial()) {
    on<LoadNotification>(_onLoadNotification);
    on<LoadNotifications>(_onLoadNotifications);
    on<UpdateNotification>(_updateNotification);
    on<DeleteNotification>(_deleteNotification);
    on<LoadNotificationsCacheFirstThenNetwork>(
      _onLoadNotificationsCacheFirstThenNetwork,
    );
    on<LoadNotificationsByFrom>(_onLoadNotificationsByFrom);
    on<ClearNotification>(_onClearNotification);
    on<NotificationsCounter>(_onCountNotifications);
    on<LoadNotificationsPage>(_onLoadPage);
    on<MarkAllNotificationsRead>(_onMarkAllRead);
  }

  Future<void> _onLoadNotification(
    LoadNotification event,
    Emitter<NotificationBlocState> emit,
  ) async {
    emit(const NotificationLoading());

    final result = await sl<FirebaseNotificationService>().findNotificationById(
      event.uid,
    );

    result.fold((failure) => emit(NotificationError(failure.toString())), (
      workorder,
    ) {
      emit(NotificationLoaded(workorder));
    });
  }

  Future<void> _updateNotification(
    UpdateNotification event,
    Emitter<NotificationBlocState> emit,
  ) async {
    final notification = event.notification;
    final toWrite = notification.status == 'read' && notification.readAt == null
        ? notification.copyWith(readAt: DateTime.now().toUtc())
        : notification;

    final result = await sl<FirebaseNotificationService>().updateNotification(
      toWrite,
    );

    await result.fold(
      (failure) async {
        emit(NotificationError(failure.toString()));
      },
      (notification) async {
        await sl<HiveNotificationService>().updateItem(toWrite);
        emit(NotificationLoaded(notification)); // ✅ safe emit
      },
    );
  }

  Future<void> _onLoadNotifications(
    LoadNotifications event,
    Emitter<NotificationBlocState> emit,
  ) async {
    emit(const NotificationLoading());

    final result = await sl<FirebaseNotificationService>()
        .findNotificationsFromFirestore(event.uid);

    result.fold((failure) => emit(NotificationError(failure.toString())), (
      notifications,
    ) {
      if (notifications.isEmpty) {
        emit(const NotificationsEmpty());
      } else {
        emit(NotificationsLoaded(notifications));
      }
    });
  }

  Future<void> _deleteNotification(
    DeleteNotification event,
    Emitter<NotificationBlocState> emit,
  ) async {
    try {
      final result = await sl<FirebaseNotificationService>().deleteNotification(
        event.uid,
      );

      await result.fold(
        (failure) async {
          emit(NotificationError(failure.toString()));
        },
        (notification) async {
          await sl<HiveNotificationService>().deleteItem(event.uid);
          emit(NotificationLoaded(notification)); // ✅ safe emit
        },
      );
    } catch (e) {
      // ❌ Rollback if persistence failed (optional)
      emit(NotificationError("Failed to delete item: $e"));
    }
  }

  Future<void> _onLoadNotificationsByFrom(
    LoadNotificationsByFrom event,
    Emitter<NotificationBlocState> emit,
  ) async {
    String uid = event.uid;
    final us = FirebaseAuth.instance.currentUser;
    if (us != null) {
      uid = us.uid;
    }
    emit(const NotificationLoading());

    final cachedItems = await sl<HiveNotificationService>().getItems(uid);

    if (cachedItems.isEmpty) {
      emit(const NotificationsEmpty());
      return;
    }

    final workOrderItems = cachedItems
        .where((NotificationModel item) => item.uid == event.uid)
        .toList();

    if (workOrderItems.isEmpty) {
      emit(const NotificationsEmpty());
      return;
    }
    if (workOrderItems.isNotEmpty) {
      emit(NotificationsLoaded(workOrderItems, fromCache: true));
    }
  }

  void _onClearNotification(
    ClearNotification event,
    Emitter<NotificationBlocState> emit,
  ) {
    emit(const NotificationInitial());
  }

  Future<void> _onCountNotifications(
    NotificationsCounter event,
    Emitter<NotificationBlocState> emit,
  ) async {
    final uid = event.uid.isEmpty
        ? FirebaseAuth.instance.currentUser?.uid ?? ''
        : event.uid;

    if (uid.isEmpty) {
      emit(const NotificationsCounted(0));
      return;
    }

    final result = await sl<FirebaseNotificationService>().getUnreadCount(uid);

    // Fall back to the cache when offline so the badge is not misleading.
    final cachedUnread = result.fold(
      (_) async => (await sl<HiveNotificationService>().getItems(uid))
          .where((item) => item.status == 'new')
          .length,
      (count) async => count,
    );

    emit(NotificationsCounted(await cachedUnread));
  }

  Future<void> _onLoadNotificationsCacheFirstThenNetwork(
    LoadNotificationsCacheFirstThenNetwork event,
    Emitter<NotificationBlocState> emit,
  ) async {
    String uid = event.uid;
    final us = FirebaseAuth.instance.currentUser;
    if (us != null) {
      uid = us.uid;
    }
    emit(const NotificationLoading());

    final cachedItems = await sl<HiveNotificationService>().getItems(uid);

    if (cachedItems.isNotEmpty) {
      emit(NotificationsLoaded(cachedItems, fromCache: true));
    }

    final result = await sl<FirebaseNotificationService>()
        .findNotificationsFromFirestore(uid);

    result.fold(
      (failure) async {
        if (cachedItems.isEmpty) {
          emit(NotificationError(failure.toString()));
        }
      },
      (notifications) async {
        if (notifications.isEmpty) {
          if (cachedItems.isEmpty) {
            emit(const NotificationsEmpty());
          }
          return;
        }

        if (cachedItems.toString() != notifications.toString()) {
          emit(NotificationsLoaded(notifications, fromCache: false));
          await sl<HiveNotificationService>().insertItems(notifications,
          );
        } else {
          emit(NotificationsLoaded(cachedItems, fromCache: true));
        }
      },
    );
  }

  @override
  Future<void> close() {
    // _hiveSubscription?.cancel(); // 👈 clean up
    return super.close();
  }

  Future<void> _onLoadPage(
    LoadNotificationsPage event,
    Emitter<NotificationBlocState> emit,
  ) async {
    if (event.beforeCreatedAt == null) emit(const NotificationLoading());

    final result = await sl<FirebaseNotificationService>()
        .findNotificationsPage(
          event.uid,
          limit: event.limit,
          beforeCreatedAt: event.beforeCreatedAt,
        );

    result.fold(
      (failure) => emit(NotificationError(failure.toString())),
      (page) {
        if (page.isEmpty) {
          if (event.beforeCreatedAt == null) {
            emit(const NotificationsEmpty());
          } else {
            emit(NotificationsLoaded(const [], hasMore: false));
          }
          return;
        }

        emit(
          NotificationsLoaded(
            page,
            hasMore: page.length >= event.limit,
          ),
        );
      },
    );
  }

  Future<void> _onMarkAllRead(
    MarkAllNotificationsRead event,
    Emitter<NotificationBlocState> emit,
  ) async {
    final result = await sl<FirebaseNotificationService>().markAllAsRead(
      event.uid,
    );

    result.fold(
      (failure) => emit(NotificationError(failure.toString())),
      (affected) => emit(NotificationsMarkedRead(affected)),
    );
  }
}
