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
    final result = await sl<FirebaseNotificationService>().updateNotification(
      event.notification,
    );

    await result.fold(
      (failure) async {
        emit(NotificationError(failure.toString()));
      },
      (notification) async {
        await sl<HiveNotificationService>().updateItem(event.notification);
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
    String uid = event.uid;
    final cachedItems = await sl<HiveNotificationService>().getItems(uid);

    emit(NotificationsCounted(cachedItems.length));
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
          await sl<HiveNotificationService>().insertItems(
            uid,
            items: notifications,
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
}
