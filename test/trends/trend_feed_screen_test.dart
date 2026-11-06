import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/core/theme/app.theme.dart';
import 'package:fashionista/data/models/trends/bloc/trend_feed_bloc.dart';
import 'package:fashionista/data/models/trends/trend_feed_model.dart';
import 'package:fashionista/data/models/trends/trend_feed_page.dart';
import 'package:fashionista/data/services/firebase/firebase_trends_service.dart';
import 'package:fashionista/data/services/hive/hive_trend_service.dart';
import 'package:fashionista/presentation/screens/trends/discover_trends_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'trend_feed_fakes.dart';

late FakeTrendsService service;
late FakeHiveTrendService hive;
late TrendFeedBloc bloc;

TrendFeedPage page(
  List<TrendFeedModel> trends, {
  Object? cursor,
  bool hasMore = false,
}) {
  return TrendFeedPage(trends: trends, cursor: cursor, hasMore: hasMore);
}

List<TrendFeedModel> many(int count, {int from = 0}) => [
  for (var i = from; i < from + count; i++)
    trend('t$i', createdAt: 10_000 - i),
];

Future<void> pumpScreen(
  WidgetTester tester, {
  Size viewport = const Size(1080, 700),
}) async {
  tester.view.physicalSize = viewport;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  // Built here, inside the test body: a bloc constructed in `setUp` belongs to
  // a different zone and FakeAsync never drains its event stream.
  bloc = TrendFeedBloc(userIdProvider: () => 'viewer_1');

  await tester.pumpWidget(
    MaterialApp(
      theme: fashionistaLightTheme,
      home: BlocProvider<TrendFeedBloc>.value(
        value: bloc,
        child: const DiscoverTrendsPage(),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 20));
}

/// Pumps a fixed number of frames.
///
/// `pumpAndSettle` never returns while a progress indicator is on screen.
Future<void> pumpFrames(WidgetTester tester, [int frames = 8]) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 20));
  }
}

Future<void> scrollToBottom(WidgetTester tester) async {
  final scrollable = find.descendant(
    of: find.byType(CustomScrollView),
    matching: find.byType(Scrollable),
  );

  // Card heights vary with the viewport width, so drag until the end is
  // actually reached rather than assuming one drag gets there.
  for (var i = 0; i < 12; i++) {
    final position = tester.state<ScrollableState>(scrollable.first).position;
    if (position.hasContentDimensions && position.extentAfter <= 0) break;
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -3000));
    await pumpFrames(tester, 4);
  }

  await pumpFrames(tester);
}

void main() {
  setUp(() {
    service = FakeTrendsService();
    hive = FakeHiveTrendService();
    sl.registerSingleton<HiveTrendService>(hive);
    sl.registerSingleton<FirebaseTrendsService>(service);
  });

  tearDown(() async {
    // The bloc is intentionally not closed: a gated fake would make close()
    // wait forever under FakeAsync. Each test builds its own bloc.
    await hive.changes.close();
    await sl.reset();
  });

  testWidgets('shows a spinner during the initial load', (tester) async {
    service.gate = Completer<void>();
    service.queue.add(const Right(TrendFeedPage.empty));

    await pumpScreen(tester);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    service.gate!.complete();
    service.gate = null;
    await pumpFrames(tester);
  });

  testWidgets('renders cached trends before the network answers', (
    tester,
  ) async {
    for (final item in many(6)) {
      hive.store[item.uid!] = item;
    }
    service.gate = Completer<void>();
    service.queue.add(Right(page(many(6), cursor: 'c1', hasMore: true)));

    await pumpScreen(tester);
    await pumpFrames(tester);

    expect(find.text('Trend t0'), findsWidgets);

    service.gate!.complete();
    service.gate = null;
    await pumpFrames(tester);
  });

  testWidgets('reaching the bottom loads exactly one more page', (
    tester,
  ) async {
    service.queue.add(Right(page(many(6), cursor: 'c1', hasMore: true)));
    service.queue.add(Right(page(many(6, from: 6), cursor: 'c2', hasMore: false)));

    await pumpScreen(tester);
    await pumpFrames(tester);
    expect(service.requests, hasLength(1));

    await scrollToBottom(tester);

    expect(service.requests, hasLength(2));
    expect(service.requests.last.cursor, 'c1');
    // The page is appended, not substituted; the new card is below the fold.
    expect(bloc.state.items, hasLength(12));
  });

  testWidgets('keeps the cards on screen while a page loads', (tester) async {
    service.queue.add(Right(page(many(6), cursor: 'c1', hasMore: true)));
    service.queue.add(Right(page(many(6, from: 6), cursor: 'c2', hasMore: false)));

    await pumpScreen(tester);
    await pumpFrames(tester);

    service.gate = Completer<void>();
    await scrollToBottom(tester);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(bloc.state.items, hasLength(6)); // nothing dropped while loading

    service.gate!.complete();
    service.gate = null;
    await pumpFrames(tester);

    expect(bloc.state.items, hasLength(12));
  });

  testWidgets('shows a retry at the bottom when a page fails', (tester) async {
    service.queue.add(Right(page(many(6), cursor: 'c1', hasMore: true)));

    await pumpScreen(tester);
    await pumpFrames(tester);

    service.queue.add(const Left('offline'));
    await scrollToBottom(tester);

    expect(find.text('Could not load more'), findsOneWidget);
    expect(bloc.state.items, hasLength(6));

    // The scroll listener must not retry by itself.
    final requestsAfterFailure = service.requests.length;
    await scrollToBottom(tester);
    expect(service.requests.length, requestsAfterFailure);

    service.queue.add(Right(page(many(6, from: 6), cursor: 'c2', hasMore: false)));
    await tester.tap(find.text('Retry'));
    await pumpFrames(tester);

    expect(find.text('Could not load more'), findsNothing);
    expect(bloc.state.items, hasLength(12));
  });

  testWidgets('pull to refresh reloads the newest page', (tester) async {
    service.queue.add(Right(page(many(3), cursor: 'c1', hasMore: true)));
    service.queue.add(
      Right(page([trend('fresh', createdAt: 99_999)], cursor: 'c2', hasMore: true)),
    );

    await pumpScreen(tester);
    await pumpFrames(tester);

    await tester.fling(find.byType(CustomScrollView), const Offset(0, 400), 1200);
    await pumpFrames(tester, 20);

    expect(service.requests.last.cursor, isNull);
    expect(bloc.state.items.first.uid, 'fresh');
    expect(find.text('Trend fresh'), findsWidgets);
  });

  for (final size in const [
    Size(375, 667), // small phone
    Size(834, 1112), // tablet portrait
    Size(1440, 900), // desktop / landscape
  ]) {
    testWidgets(
      'loads one page per bottom arrival on a ${size.width.toInt()}x${size.height.toInt()} screen',
      (tester) async {
        // Enough cards to overflow every viewport above.
        service.queue.add(Right(page(many(12), cursor: 'c1', hasMore: true)));
        service.queue.add(
          Right(page(many(12, from: 12), cursor: 'c2', hasMore: true)),
        );

        await pumpScreen(tester, viewport: size);
        await pumpFrames(tester);

        final requestsAfterFirstPage = service.requests.length;
        expect(requestsAfterFirstPage, lessThanOrEqualTo(2));

        await scrollToBottom(tester);

        expect(service.requests.length, greaterThanOrEqualTo(2));
        expect(bloc.state.items.length, greaterThan(12));

        // Scrolling further must not stampede: one page per arrival.
        final afterScroll = service.requests.length;
        await tester.drag(
          find.byType(CustomScrollView),
          const Offset(0, -200),
        );
        await pumpFrames(tester);
        expect(service.requests.length - afterScroll, lessThanOrEqualTo(1));
      },
    );
  }

  testWidgets('fills a short feed on a tall screen', (tester) async {
    service.queue.add(Right(page(many(3), cursor: 'c1', hasMore: true)));
    service.queue.add(Right(page(many(3, from: 3), cursor: 'c2', hasMore: true)));

    // Very tall viewport: three cards cannot fill it, so no scroll notification
    // is ever emitted and the sentinel has to drive the next page.
    await pumpScreen(tester, viewport: const Size(800, 4000));
    await pumpFrames(tester, 12);

    expect(service.requests.length, greaterThanOrEqualTo(2));
    expect(bloc.state.items.length, greaterThan(3));
  });

  testWidgets('shows the empty state when there is nothing', (tester) async {
    service.queue.add(const Right(TrendFeedPage.empty));

    await pumpScreen(tester);
    await pumpFrames(tester);

    expect(find.text('No trends found'), findsOneWidget);
  });
}
