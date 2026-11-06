import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/data/models/notification/bloc/notification_bloc.dart';
import 'package:fashionista/data/models/notification/bloc/notification_bloc_event.dart';
import 'package:fashionista/data/models/notification/bloc/notification_bloc_state.dart';
import 'package:fashionista/data/models/notification/notification_model.dart';
import 'package:fashionista/data/models/notification/notification_page.dart';
import 'package:fashionista/data/services/firebase/firebase_notification_service.dart';
import 'package:fashionista/data/services/hive/hive_notification_service.dart';
import 'package:flutter_test/flutter_test.dart';

NotificationModel notification(String id, {int createdAt = 0, String status = 'new'}) {
  return NotificationModel(
    uid: id,
    title: 'Title $id',
    description: 'Body $id',
    type: 'info',
    createdAt: createdAt,
    status: status,
    to: 'user_1',
  );
}

/// Records every page request and returns queued pages.
class FakeNotificationService implements FirebaseNotificationService {
  final List<({int limit, Object? cursor})> requests = [];
  final List<Either<String, NotificationPage>> queue = [];
  Completer<void>? gate;

  /// When set, every page request returns this instead of the queue.
  Either<String, NotificationPage>? forced;

  @override
  Future<Either<String, NotificationPage>> findNotificationsPage(
    String uid, {
    int limit = 20,
    Object? cursor,
  }) async {
    requests.add((limit: limit, cursor: cursor));

    final result = forced ??
        (queue.isEmpty
            ? const Right<String, NotificationPage>(NotificationPage.empty)
            : queue.removeAt(0));

    if (gate != null) await gate!.future;
    return result;
  }

  @override
  Future<Either> updateNotification(NotificationModel notification) async =>
      Right(notification);

  @override
  Future<Either> deleteNotification(String notificationId) async =>
      const Right('deleted');

  @override
  Future<Either<String, int>> markAllAsRead(String uid) async =>
      const Right(1);

  @override
  Future<Either> createNotification(NotificationModel notification) async =>
      Right(notification);

  @override
  Future<Either<String, NotificationModel>> findNotificationById(
    String notificationId,
  ) async =>
      Right(notification(notificationId));

  @override
  Future<Either> fetchNotificationsFromFirestore(String uid) async =>
      const Right(<NotificationModel>[]);

  @override
  Future<Either<String, int>> getCount(String uid) async => const Right(0);

  @override
  Future<Either<String, int>> getUnreadCount(String uid) async => const Right(0);
}

class FakeHiveNotificationService extends HiveNotificationService {
  List<NotificationModel> cached = [];
  final List<List<NotificationModel>> seeded = [];
  int getItemsCalls = 0;

  @override
  Future<List<NotificationModel>> getItems(String key) async {
    getItemsCalls += 1;
    return cached;
  }

  @override
  Future<void> insertItems(List<NotificationModel> items) async {
    seeded.add(items);
    cached = items;
  }

  @override
  Future<void> updateItem(NotificationModel item) async {
    cached = [
      for (final existing in cached)
        if (existing.uid == item.uid) item else existing,
    ];
  }

  @override
  Future<void> deleteItem(String uid) async {
    cached = [
      for (final existing in cached)
        if (existing.uid != uid) existing,
    ];
  }
}

late FakeNotificationService service;
late FakeHiveNotificationService hive;

NotificationBloc buildBloc() =>
    NotificationBloc(userIdProvider: () => 'user_1');

/// Lets the bloc finish its async work before assertions.
Future<void> settle() => Future<void>.delayed(Duration.zero);

void main() {
  setUp(() {
    service = FakeNotificationService();
    hive = FakeHiveNotificationService();
    sl.registerSingleton<FirebaseNotificationService>(service);
    sl.registerSingleton<HiveNotificationService>(hive);
  });

  tearDown(() => sl.reset());

  group('initial load', () {
    test('requests one page and shows it newest first', () async {
      service.queue.add(
        Right(
          NotificationPage(
            notifications: [notification('n1', createdAt: 20), notification('n2', createdAt: 10)],
            cursor: 'c1',
            hasMore: true,
          ),
        ),
      );
      final bloc = buildBloc();

      bloc.add(const LoadNotificationsPage('user_1'));
      await settle();

      expect(service.requests, hasLength(1));
      expect(service.requests.single.limit, NotificationBloc.defaultPageSize);
      expect(service.requests.single.cursor, isNull);

      final state = bloc.state as NotificationsLoaded;
      expect(state.notifications.map((n) => n.uid), ['n1', 'n2']);
      expect(state.hasMore, isTrue);
      expect(state.isLoadingMore, isFalse);
    });

    test('shows the cached page while the network call runs', () async {
      hive.cached = [notification('cached', createdAt: 5)];
      service.gate = Completer<void>();
      service.queue.add(
        Right(
          NotificationPage(
            notifications: [notification('fresh', createdAt: 99)],
            cursor: 'c1',
            hasMore: false,
          ),
        ),
      );
      final bloc = buildBloc();

      bloc.add(const LoadNotificationsPage('user_1'));
      await settle();

      final cachedState = bloc.state as NotificationsLoaded;
      expect(cachedState.fromCache, isTrue);
      expect(cachedState.notifications.single.uid, 'cached');

      service.gate!.complete();
      await settle();

      final freshState = bloc.state as NotificationsLoaded;
      expect(freshState.notifications.single.uid, 'fresh');
      expect(freshState.fromCache, isFalse);
    });

    test('emits the empty state for an empty collection', () async {
      service.queue.add(const Right(NotificationPage.empty));
      final bloc = buildBloc();

      bloc.add(const LoadNotificationsPage('user_1'));
      await settle();

      expect(bloc.state, isA<NotificationsEmpty>());
    });

    test('seeds the cache with the first page only', () async {
      service.queue.add(
        Right(NotificationPage(notifications: [notification('n1')], cursor: 'c1', hasMore: true)),
      );
      service.queue.add(
        Right(NotificationPage(notifications: [notification('n2')], cursor: 'c2', hasMore: false)),
      );
      final bloc = buildBloc();

      bloc.add(const LoadNotificationsPage('user_1'));
      await settle();
      bloc.add(const LoadMoreNotifications());
      await settle();

      expect(hive.seeded, hasLength(1));
      expect(hive.seeded.single.single.uid, 'n1');
    });
  });

  group('load more', () {
    Future<NotificationBloc> loadedWithMore() async {
      service.queue.add(
        Right(
          NotificationPage(
            notifications: [notification('n1', createdAt: 30)],
            cursor: 'c1',
            hasMore: true,
          ),
        ),
      );
      final bloc = buildBloc();
      bloc.add(const LoadNotificationsPage('user_1'));
      await settle();
      return bloc;
    }

    test('appends the next page using the stored cursor', () async {
      final bloc = await loadedWithMore();
      service.queue.add(
        Right(
          NotificationPage(
            notifications: [notification('n2', createdAt: 20)],
            cursor: 'c2',
            hasMore: false,
          ),
        ),
      );

      bloc.add(const LoadMoreNotifications());
      await settle();

      final state = bloc.state as NotificationsLoaded;
      expect(state.notifications.map((n) => n.uid), ['n1', 'n2']);
      expect(state.hasMore, isFalse);
      expect(service.requests.last.cursor, 'c1');
    });

    test('stops when hasMore is false', () async {
      final bloc = await loadedWithMore();
      service.queue.add(
        Right(NotificationPage(notifications: [notification('n2')], hasMore: false)),
      );
      bloc.add(const LoadMoreNotifications());
      await settle();
      final callsAfterLastPage = service.requests.length;

      bloc.add(const LoadMoreNotifications());
      await settle();

      expect(service.requests.length, callsAfterLastPage);
    });

    test('ignores a second request while one is in flight', () async {
      final bloc = await loadedWithMore();
      service.gate = Completer<void>();
      service.queue.add(
        Right(NotificationPage(notifications: [notification('n2')], hasMore: false)),
      );

      bloc.add(const LoadMoreNotifications());
      await settle();
      bloc.add(const LoadMoreNotifications());
      await settle();

      expect(service.requests.length, 2); // initial + one page
      service.gate!.complete();
      await settle();
    });

    test('keeps the list and exposes a retry when the page fails', () async {
      final bloc = await loadedWithMore();
      service.queue.add(const Left('offline'));

      bloc.add(const LoadMoreNotifications());
      await settle();

      var state = bloc.state as NotificationsLoaded;
      expect(state.notifications.map((n) => n.uid), ['n1']);
      expect(state.loadMoreError, 'offline');
      expect(state.isLoadingMore, isFalse);

      service.queue.add(
        Right(NotificationPage(notifications: [notification('n2')], hasMore: false)),
      );
      bloc.add(const LoadMoreNotifications());
      await settle();

      state = bloc.state as NotificationsLoaded;
      expect(state.loadMoreError, isNull);
      expect(state.notifications.map((n) => n.uid), ['n1', 'n2']);
    });

    test('never appends the same notification twice', () async {
      final bloc = await loadedWithMore();
      service.queue.add(
        Right(
          NotificationPage(
            notifications: [notification('n1'), notification('n2')],
            hasMore: false,
          ),
        ),
      );

      bloc.add(const LoadMoreNotifications());
      await settle();

      final state = bloc.state as NotificationsLoaded;
      expect(state.notifications.map((n) => n.uid), ['n1', 'n2']);
    });
  });

  group('refresh', () {
    test('resets the cursor and replaces the list', () async {
      service.queue.add(
        Right(
          NotificationPage(notifications: [notification('old')], cursor: 'c1', hasMore: true),
        ),
      );
      final bloc = buildBloc();
      bloc.add(const LoadNotificationsPage('user_1'));
      await settle();

      service.queue.add(
        Right(
          NotificationPage(notifications: [notification('new')], cursor: 'c0', hasMore: false),
        ),
      );
      bloc.add(const LoadNotificationsPage('user_1', refresh: true));
      await settle();

      expect(service.requests.last.cursor, isNull);
      final state = bloc.state as NotificationsLoaded;
      expect(state.notifications.map((n) => n.uid), ['new']);
    });

    test('an older in-flight page cannot overwrite the refresh', () async {
      service.queue.add(
        Right(
          NotificationPage(notifications: [notification('n1')], cursor: 'c1', hasMore: true),
        ),
      );
      final bloc = buildBloc();
      bloc.add(const LoadNotificationsPage('user_1'));
      await settle();

      // Page 2 starts and hangs.
      final pageGate = Completer<void>();
      service.gate = pageGate;
      service.queue.add(
        Right(
          NotificationPage(notifications: [notification('stale')], hasMore: false),
        ),
      );
      bloc.add(const LoadMoreNotifications());
      await settle();

      // Refresh lands while page 2 is still in flight.
      service.gate = null;
      service.queue.add(
        Right(
          NotificationPage(notifications: [notification('fresh')], hasMore: false),
        ),
      );
      bloc.add(const LoadNotificationsPage('user_1', refresh: true));
      await settle();

      // The stale page now resolves.
      pageGate.complete();
      await settle();

      final state = bloc.state as NotificationsLoaded;
      expect(state.notifications.map((n) => n.uid), ['fresh']);
    });

    test('a failed refresh keeps the visible feed', () async {
      service.queue.add(
        Right(NotificationPage(notifications: [notification('n1')], cursor: 'c1', hasMore: true)),
      );
      final bloc = buildBloc();
      bloc.add(const LoadNotificationsPage('user_1'));
      await settle();

      service.queue.add(const Left('offline'));
      bloc.add(const LoadNotificationsPage('user_1', refresh: true));
      await settle();

      expect(bloc.state, isA<NotificationsLoaded>());
      expect((bloc.state as NotificationsLoaded).notifications.single.uid, 'n1');
    });
  });

  group('list-preserving actions', () {
    Future<NotificationBloc> loaded() async {
      service.queue.add(
        Right(
          NotificationPage(
            notifications: [notification('n1'), notification('n2')],
            cursor: 'c1',
            hasMore: false,
          ),
        ),
      );
      final bloc = buildBloc();
      bloc.add(const LoadNotificationsPage('user_1'));
      await settle();
      return bloc;
    }

    test('marking one read keeps the feed', () async {
      final bloc = await loaded();

      bloc.add(UpdateNotification(notification('n1', status: 'read')));
      await settle();

      final state = bloc.state as NotificationsLoaded;
      expect(state.notifications, hasLength(2));
      expect(state.notifications.first.status, 'read');
      expect(state.notifications.last.status, 'new');
    });

    test('deleting one keeps the rest', () async {
      final bloc = await loaded();

      bloc.add(const DeleteNotification('n1'));
      await settle();

      final state = bloc.state as NotificationsLoaded;
      expect(state.notifications.map((n) => n.uid), ['n2']);
    });

    test('mark all read keeps the feed and zeroes the count', () async {
      final bloc = await loaded();

      bloc.add(const MarkAllNotificationsRead('user_1'));
      await settle();

      final state = bloc.state as NotificationsLoaded;
      expect(state.notifications, hasLength(2));
      expect(state.notifications.every((n) => n.status == 'read'), isTrue);
      expect(state.notificationCount, 0);
    });
  });
}
