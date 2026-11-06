import 'package:dartz/dartz.dart';
import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/core/theme/app.theme.dart';
import 'package:fashionista/data/models/notification/bloc/notification_bloc.dart';
import 'package:fashionista/data/models/notification/bloc/notification_bloc_event.dart';
import 'package:fashionista/data/models/notification/bloc/notification_bloc_state.dart';
import 'package:fashionista/data/models/notification/notification_model.dart';
import 'package:fashionista/data/models/notification/notification_page.dart';
import 'package:fashionista/data/services/firebase/firebase_notification_service.dart';
import 'package:fashionista/data/services/hive/hive_notification_service.dart';
import 'package:fashionista/presentation/screens/notification/notification_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

NotificationModel notification(String id, {int createdAt = 0}) {
  return NotificationModel(
    uid: id,
    title: 'Title $id',
    description: 'Body $id',
    type: 'info',
    createdAt: createdAt,
    status: 'new',
    to: 'user_1',
  );
}

class FakeNotificationService implements FirebaseNotificationService {
  final List<Either<String, NotificationPage>> queue = [];

  /// Fake latency, advanced by `tester.pump(duration)`. A real pending future
  /// would deadlock `bloc.close()` when an assertion fails mid-flight.
  Duration delay = Duration.zero;
  int pageRequests = 0;

  @override
  Future<Either<String, NotificationPage>> findNotificationsPage(
    String uid, {
    int limit = 20,
    Object? cursor,
  }) async {
    pageRequests += 1;
    final result = queue.isEmpty
        ? const Right<String, NotificationPage>(NotificationPage.empty)
        : queue.removeAt(0);
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    return result;
  }

  @override
  Future<Either> updateNotification(NotificationModel notification) async =>
      Right(notification);
  @override
  Future<Either> deleteNotification(String notificationId) async =>
      const Right('deleted');
  @override
  Future<Either<String, int>> markAllAsRead(String uid) async => const Right(0);
  @override
  Future<Either> createNotification(NotificationModel notification) async =>
      Right(notification);
  @override
  Future<Either<String, NotificationModel>> findNotificationById(String id) async =>
      Right(notification(id));
  @override
  Future<Either> fetchNotificationsFromFirestore(String uid) async =>
      const Right(<NotificationModel>[]);
  @override
  Future<Either<String, int>> getCount(String uid) async => const Right(0);
  @override
  Future<Either<String, int>> getUnreadCount(String uid) async => const Right(0);
}

class FakeHiveNotificationService extends HiveNotificationService {
  @override
  Future<List<NotificationModel>> getItems(String key) async => [];
  @override
  Future<void> insertItems(List<NotificationModel> items) async {}
  @override
  Future<void> updateItem(NotificationModel item) async {}
  @override
  Future<void> deleteItem(String uid) async {}
}

late FakeNotificationService service;
late NotificationBloc bloc;

Future<void> pumpScreen(
  WidgetTester tester, {
  Size viewport = const Size(1080, 2000),
}) async {
  tester.view.physicalSize = viewport;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  // Created here, inside the test body: a bloc constructed in `setUp` belongs
  // to a different zone and its event stream is never drained by FakeAsync.
  bloc = NotificationBloc(userIdProvider: () => 'user_1');

  await tester.pumpWidget(
    MaterialApp(
      theme: fashionistaLightTheme,
      home: BlocProvider<NotificationBloc>.value(
        value: bloc,
        child: const NotificationScreen(),
      ),
    ),
  );
  // First pump builds the screen and dispatches the initial load; the second
  // lets the asynchronous handler finish, since pumpAndSettle alone returns
  // immediately when no frame is scheduled.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 20));
}

/// Pumps a fixed number of frames.
///
/// `pumpAndSettle` never returns while a progress indicator is on screen: the
/// indeterminate animation schedules frames forever.
Future<void> pumpFrames(WidgetTester tester, [int frames = 8]) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 20));
  }
}

List<NotificationModel> many(int count) => [
  for (var i = 0; i < count; i++)
    notification('n$i', createdAt: 100 - i),
];

void main() {
  setUp(() {
    service = FakeNotificationService();
    sl.registerSingleton<FirebaseNotificationService>(service);
    sl.registerSingleton<HiveNotificationService>(FakeHiveNotificationService());
  });

  tearDown(() async {
    // The bloc is intentionally not closed: a pending fake-latency timer would
    // make close() wait forever under FakeAsync. Each test builds its own bloc.
    await sl.reset();
  });

  testWidgets('shows a spinner during the initial load', (tester) async {
    service.delay = const Duration(milliseconds: 200);
    service.queue.add(const Right(NotificationPage.empty));

    await pumpScreen(tester);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 300));
    await pumpFrames(tester);
  });

  testWidgets('renders the loaded notifications', (tester) async {
    service.queue.add(
      Right(
        NotificationPage(
          notifications: [notification('n1', createdAt: 10), notification('n2', createdAt: 5)],
          hasMore: false,
        ),
      ),
    );
    await pumpScreen(tester);
    await pumpFrames(tester);

    expect(find.text('Title n1'), findsOneWidget);
    expect(find.text('Title n2'), findsOneWidget);
  });

  testWidgets('shows the empty state when there is nothing', (tester) async {
    service.queue.add(const Right(NotificationPage.empty));
    await pumpScreen(tester);
    await pumpFrames(tester);

    expect(find.text('No notifications yet'), findsOneWidget);
  });

  testWidgets('keeps the list on screen while loading another page', (tester) async {
    service.queue.add(
      Right(
        NotificationPage(notifications: many(14), cursor: 'c1', hasMore: true),
      ),
    );
    // Small viewport so the first page overflows and the auto-fill stays idle.
    await pumpScreen(tester, viewport: const Size(1080, 700));
    await pumpFrames(tester);

    service.delay = const Duration(milliseconds: 200);
    service.queue.add(
      Right(NotificationPage(notifications: [notification('n14')], hasMore: false)),
    );

    bloc.add(const LoadMoreNotifications());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));

    // The footer only exists once it scrolls into view.
    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pump();

    // Rows still rendered (the first one has scrolled away), footer spinner on.
    expect(find.textContaining('Title n'), findsWidgets);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect((bloc.state as NotificationsLoaded).notifications, hasLength(14));

    await tester.pump(const Duration(milliseconds: 300));
    await pumpFrames(tester);

    expect((bloc.state as NotificationsLoaded).notifications, hasLength(15));
  });

  testWidgets('offers a retry at the bottom when a page fails', (tester) async {
    service.queue.add(
      Right(
        NotificationPage(notifications: many(14), cursor: 'c1', hasMore: true),
      ),
    );
    await pumpScreen(tester, viewport: const Size(1080, 700));
    await pumpFrames(tester);

    // A failed page must not be retried by the scroll listener, so a single
    // failure keeps the error row on screen until the user taps Retry.
    service.queue.add(const Left('offline'));

    bloc.add(const LoadMoreNotifications());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));

    await tester.drag(find.byType(ListView), const Offset(0, -800));
    await pumpFrames(tester);

    expect(find.text('Could not load more'), findsOneWidget);
    expect(find.textContaining('Title n'), findsWidgets);
    expect(service.pageRequests, 2);

    service.queue.add(
      Right(NotificationPage(notifications: [notification('n14')], hasMore: false)),
    );
    await tester.tap(find.text('Retry'));
    await pumpFrames(tester);

    expect(find.text('Could not load more'), findsNothing);
    expect((bloc.state as NotificationsLoaded).notifications, hasLength(15));
  });

  testWidgets('pull to refresh reloads the newest page', (tester) async {
    service.queue.add(
      Right(
        NotificationPage(
          notifications: many(14),
          cursor: 'c1',
          hasMore: true,
        ),
      ),
    );
    await pumpScreen(tester, viewport: const Size(1080, 700));
    await pumpFrames(tester);

    service.queue.add(
      Right(
        NotificationPage(
          notifications: [notification('fresh', createdAt: 500)],
          hasMore: false,
        ),
      ),
    );

    await tester.fling(find.byType(ListView), const Offset(0, 400), 1000);
    await pumpFrames(tester, 40);

    final state = bloc.state as NotificationsLoaded;
    expect(state.notifications.map((n) => n.uid), ['fresh']);
  });

  testWidgets('fills the viewport when the first page is short', (tester) async {
    service.queue.add(
      Right(
        NotificationPage(
          notifications: [notification('n1', createdAt: 10)],
          cursor: 'c1',
          hasMore: true,
        ),
      ),
    );
    service.queue.add(
      Right(NotificationPage(notifications: [notification('n2')], hasMore: false)),
    );

    await pumpScreen(tester);
    await pumpFrames(tester);

    // The post-frame fill requested page 2 without any user scroll.
    expect(find.text('Title n2'), findsOneWidget);
    expect(service.pageRequests, 2);
  });
}
