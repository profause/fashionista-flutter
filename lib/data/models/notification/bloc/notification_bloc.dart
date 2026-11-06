import 'dart:async';

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
  NotificationBloc({String? Function()? userIdProvider})
    : _userIdProvider = userIdProvider ?? _signedInUserId,
      super(const NotificationInitial()) {
    on<LoadNotification>(_onLoadNotification);
    on<UpdateNotification>(_updateNotification);
    on<DeleteNotification>(_deleteNotification);
    on<LoadNotificationsByFrom>(_onLoadNotificationsByFrom);
    on<ClearNotification>(_onClearNotification);
    on<NotificationsCounter>(_onCountNotifications);
    on<LoadNotificationsPage>(_onLoadPage);
    on<LoadMoreNotifications>(_onLoadMore);
    on<MarkAllNotificationsRead>(_onMarkAllRead);
  }

  /// Default page size for the inbox feed.
  static const int defaultPageSize = 20;

  /// Signed-in user, injectable so the bloc is testable without Firebase.
  final String? Function() _userIdProvider;

  static String? _signedInUserId() => FirebaseAuth.instance.currentUser?.uid;

  /// Cursor of the last loaded row; `null` before the first page.
  Object? _lastDocument;

  /// Bumped on every fresh load so an older in-flight page cannot overwrite it.
  int _generation = 0;

  /// Uid the current list belongs to; pages for another user are discarded.
  String? _pageOwnerUid;

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

        // With the feed rendered from bloc state, replacing the list with a
        // single-item state would blank the screen.
        final current = state;
        if (current is NotificationsLoaded) {
          emit(
            current.copyWith(
              notifications: [
                for (final item in current.notifications)
                  if (item.uid == toWrite.uid) toWrite else item,
              ],
            ),
          );
          return;
        }

        emit(NotificationLoaded(notification));
      },
    );
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

          final current = state;
          if (current is NotificationsLoaded) {
            emit(
              current.copyWith(
                notifications: [
                  for (final item in current.notifications)
                    if (item.uid != event.uid) item,
                ],
              ),
            );
            return;
          }

          emit(NotificationLoaded(notification));
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
    final signedIn = _userIdProvider();
    final uid = (signedIn == null || signedIn.isEmpty) ? event.uid : signedIn;
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
        ? _userIdProvider() ?? ''
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

  Future<void> _onLoadPage(
    LoadNotificationsPage event,
    Emitter<NotificationBlocState> emit,
  ) async {
    final uid = event.uid.isEmpty
        ? _userIdProvider() ?? ''
        : event.uid;
    if (uid.isEmpty) {
      emit(const NotificationsEmpty());
      return;
    }

    // A refresh invalidates any page currently in flight.
    final generation = ++_generation;
    _pageOwnerUid = uid;
    _lastDocument = null;

    final current = state is NotificationsLoaded
        ? state as NotificationsLoaded
        : null;
    final isRefresh = event.refresh && current != null;

    // Offline-first paint: show the cached newest page while the network call
    // runs, instead of an empty spinner.
    var showingCache = false;
    if (!isRefresh) {
      final cached = await sl<HiveNotificationService>().getItems(uid);
      if (generation != _generation) return;
      if (cached.isNotEmpty) {
        final sorted = [...cached]
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        emit(NotificationsLoaded(sorted, fromCache: true));
        showingCache = true;
      } else {
        emit(const NotificationLoading());
      }
    }

    final result = await sl<FirebaseNotificationService>()
        .findNotificationsPage(uid, limit: event.limit);

    if (generation != _generation) return; // superseded by a newer load

    result.fold(
      (failure) {
        // A failure must never blank a feed that is already on screen.
        if (showingCache || isRefresh) return;
        emit(NotificationError(failure.toString()));
      },
      (page) {
        _lastDocument = page.cursor;

        if (page.isEmpty) {
          emit(const NotificationsEmpty());
          return;
        }

        emit(
          NotificationsLoaded(
            page.notifications,
            hasMore: page.hasMore,
          ),
        );
        unawaited(_seedCache(page.notifications));
      },
    );
  }

  /// Appends the next page, keeping everything already on screen.
  Future<void> _onLoadMore(
    LoadMoreNotifications event,
    Emitter<NotificationBlocState> emit,
  ) async {
    final current = state;
    if (current is! NotificationsLoaded) return;
    if (current.isLoadingMore) return; // rapid scroll guard
    if (!current.hasMore) return;
    if (_lastDocument == null) return;

    final uid = _pageOwnerUid ?? _userIdProvider() ?? '';
    if (uid.isEmpty) return;

    final generation = _generation;

    emit(current.copyWith(isLoadingMore: true, clearLoadMoreError: true));

    final result = await sl<FirebaseNotificationService>()
        .findNotificationsPage(
          uid,
          limit: defaultPageSize,
          cursor: _lastDocument,
        );

    // Refresh happened while this page was loading: drop the stale result.
    if (generation != _generation) return;

    final latest = state;
    if (latest is! NotificationsLoaded) return;

    result.fold(
      (failure) => emit(
        latest.copyWith(
          isLoadingMore: false,
          loadMoreError: failure.toString(),
        ),
      ),
      (page) {
        _lastDocument = page.cursor ?? _lastDocument;

        final seen = latest.notifications
            .map((notification) => notification.uid)
            .whereType<String>()
            .toSet();
        final appended = page.notifications
            .where((notification) => !seen.contains(notification.uid))
            .toList(growable: false);

        emit(
          latest.copyWith(
            // Always a new list: Equatable compares list identity, so mutating
            // in place would not rebuild the screen.
            notifications: [...latest.notifications, ...appended],
            hasMore: page.hasMore,
            isLoadingMore: false,
            clearLoadMoreError: true,
          ),
        );
      },
    );
  }

  /// Keeps the offline cache to the newest page (D3 in the plan).
  Future<void> _seedCache(List<NotificationModel> notifications) async {
    try {
      await sl<HiveNotificationService>().insertItems(notifications);
    } catch (_) {
      // Cache failures must never break the feed.
    }
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
      (affected) {
        final current = state;
        if (current is! NotificationsLoaded) {
          emit(NotificationsMarkedRead(affected));
          return;
        }

        emit(
          current.copyWith(
            notifications: [
              for (final item in current.notifications)
                if (item.status == 'new')
                  item.copyWith(status: 'read', readAt: DateTime.now().toUtc())
                else
                  item,
            ],
            unreadCount: 0,
          ),
        );
      },
    );
  }
}
