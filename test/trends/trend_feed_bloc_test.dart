import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/data/models/trends/bloc/trend_feed_bloc.dart';
import 'package:fashionista/data/models/trends/bloc/trend_feed_event.dart';
import 'package:fashionista/data/models/trends/bloc/trend_feed_state.dart';
import 'package:fashionista/data/models/trends/trend_feed_model.dart';
import 'package:fashionista/data/services/firebase/firebase_trends_service.dart';
import 'package:fashionista/data/services/hive/hive_trend_service.dart';
import 'package:flutter_test/flutter_test.dart';

import 'trend_feed_fakes.dart';

void main() {
  late FakeTrendsService service;
  late FakeHiveTrendService hive;

  setUp(() {
    service = FakeTrendsService();
    hive = FakeHiveTrendService();
    sl.registerSingleton<FirebaseTrendsService>(service);
    sl.registerSingleton<HiveTrendService>(hive);
  });

  tearDown(() async {
    await hive.changes.close();
    await sl.reset();
  });

  TrendFeedBloc buildBloc() => TrendFeedBloc(userIdProvider: () => viewerUid);

  /// Resolves once the state satisfies [predicate], or fails the test.
  Future<TrendFeedState> waitFor(
    TrendFeedBloc bloc,
    bool Function(TrendFeedState) predicate,
  ) {
    return bloc.stream
        .firstWhere(predicate)
        .timeout(
          const Duration(seconds: 5),
          onTimeout: () => throw StateError(
            'timed out waiting for state; current=${bloc.state}',
          ),
        );
  }

  test('opening paints the cache before the network page', () async {
    hive.store['c1'] = trend('c1', createdAt: 100);
    service.queue.add(
      Right(
        page([trend('c1', createdAt: 100)], cursor: 'cur-1', hasMore: true),
      ),
    );

    final bloc = buildBloc();
    final cachePainted = waitFor(bloc, (state) => state.items.isNotEmpty);

    bloc.add(const TrendFeedOpened());

    final cachedState = await cachePainted;
    expect(cachedState.fromCache, isTrue);
    expect(cachedState.items.single.uid, 'c1');

    final loaded = await waitFor(bloc, (state) => !state.fromCache);
    expect(loaded.items.single.uid, 'c1');
    expect(hive.pruneCalls, 1);
    expect(hive.prunedForUid, viewerUid);

    await bloc.close();
  });

  test('a draft in the cache never reaches the feed', () async {
    hive.store['draft'] = trend(
      'draft',
      createdAt: 200,
      audience: TrendFeedModel.audienceDraft,
    );
    hive.store['live'] = trend('live', createdAt: 100);
    service.queue.add(Right(page([trend('live', createdAt: 100)])));

    final bloc = buildBloc();
    final loaded = waitFor(bloc, (state) => state.pagesLoaded == 1);
    bloc.add(const TrendFeedOpened());
    await loaded;

    expect(bloc.state.items.map((item) => item.uid), ['live']);

    await bloc.close();
  });

  test('a reported trend in the cache never reaches the feed', () async {
    hive.store['reported'] = trend(
      'reported',
      createdAt: 200,
      status: TrendFeedModel.statusReported,
    );
    hive.store['live'] = trend('live', createdAt: 100);
    service.queue.add(Right(page([trend('live', createdAt: 100)])));

    final bloc = buildBloc();
    final loaded = waitFor(bloc, (state) => state.pagesLoaded == 1);
    bloc.add(const TrendFeedOpened());
    await loaded;

    expect(bloc.state.items.map((item) => item.uid), ['live']);

    await bloc.close();
  });

  test('reported pages do not look like visible progress', () async {
    final reported = [
      for (var i = 0; i < 5; i++)
        trend(
          'reported$i',
          createdAt: 500 - i,
          status: TrendFeedModel.statusReported,
        ),
    ];
    service.queue.add(Right(page(reported, cursor: 'cur-1', hasMore: true)));
    service.queue.add(
      Right(
        page([trend('live', createdAt: 10)], cursor: 'cur-2', hasMore: false),
      ),
    );

    final bloc = buildBloc();
    final firstPage = waitFor(bloc, (state) => state.pagesLoaded == 1);
    bloc.add(const TrendFeedOpened());
    await firstPage;
    expect(bloc.state.items, isEmpty);

    final nextPage = waitFor(bloc, (state) => state.items.isNotEmpty);
    bloc.add(const TrendFeedLoadMore());
    await nextPage;

    expect(bloc.state.items.map((item) => item.uid), ['live']);
    expect(service.requests, hasLength(2));

    await bloc.close();
  });

  test(
    'the first page asks for one extra document and keeps it exact',
    () async {
      final first = [
        for (var i = 0; i < 20; i++) trend('t$i', createdAt: 1000 - i),
      ];
      service.queue.add(Right(page(first, cursor: 'cur-1', hasMore: true)));

      final bloc = buildBloc();
      final loaded = waitFor(bloc, (state) => state.pagesLoaded == 1);
      bloc.add(const TrendFeedOpened());
      final state = await loaded;

      expect(service.requests.single.limit, TrendFeedBloc.pageSize);
      expect(service.requests.single.cursor, isNull);
      expect(state.items, hasLength(20));
      expect(state.hasMore, isTrue);
      expect(state.isLoadingInitial, isFalse);

      await bloc.close();
    },
  );

  test(
    'stops asking for pages when the server says there is no more',
    () async {
      service.queue.add(
        Right(
          page([trend('t0', createdAt: 10)], cursor: 'cur-1', hasMore: false),
        ),
      );

      final bloc = buildBloc();
      final loaded = waitFor(bloc, (state) => state.pagesLoaded == 1);
      bloc.add(const TrendFeedOpened());
      await loaded;

      expect(bloc.state.hasMore, isFalse);

      bloc.add(const TrendFeedLoadMore());
      await Future<void>.delayed(Duration.zero);

      expect(service.requests, hasLength(1));

      await bloc.close();
    },
  );

  test('loading more appends the next page and passes its cursor', () async {
    service.queue.add(
      Right(page([trend('a', createdAt: 20)], cursor: 'cur-1', hasMore: true)),
    );
    service.queue.add(
      Right(page([trend('b', createdAt: 10)], cursor: 'cur-2', hasMore: false)),
    );

    final bloc = buildBloc();
    final loaded = waitFor(bloc, (state) => state.pagesLoaded == 1);
    bloc.add(const TrendFeedOpened());
    await loaded;

    final appended = waitFor(bloc, (state) => state.pagesLoaded == 2);
    bloc.add(const TrendFeedLoadMore());
    final state = await appended;

    expect(state.items.map((item) => item.uid), ['a', 'b']);
    expect(service.requests.last.cursor, 'cur-1');
    expect(state.hasMore, isFalse);
    expect(state.isLoadingMore, isFalse);

    await bloc.close();
  });

  test('a page in flight keeps the list on screen', () async {
    service.queue.add(
      Right(page([trend('a', createdAt: 20)], cursor: 'cur-1', hasMore: true)),
    );
    service.queue.add(
      Right(page([trend('b', createdAt: 10)], cursor: 'cur-2', hasMore: false)),
    );

    final bloc = buildBloc();
    final loaded = waitFor(bloc, (state) => state.pagesLoaded == 1);
    bloc.add(const TrendFeedOpened());
    await loaded;

    service.gate = Completer<void>();
    bloc.add(const TrendFeedLoadMore());

    final loading = await waitFor(bloc, (state) => state.isLoadingMore);
    expect(loading.items, hasLength(1)); // still visible while loading
    expect(loading.isLoadingInitial, isFalse);

    service.gate!.complete();
    service.gate = null;
    final done = await waitFor(bloc, (state) => !state.isLoadingMore);
    expect(done.items, hasLength(2));

    await bloc.close();
  });

  test('a failed page keeps the items and offers a retry', () async {
    service.queue.add(
      Right(page([trend('a', createdAt: 20)], cursor: 'cur-1', hasMore: true)),
    );
    service.queue.add(const Left('offline'));

    final bloc = buildBloc();
    final loaded = waitFor(bloc, (state) => state.pagesLoaded == 1);
    bloc.add(const TrendFeedOpened());
    await loaded;

    final failed = waitFor(bloc, (state) => state.loadMoreError != null);
    bloc.add(const TrendFeedLoadMore());
    final state = await failed;

    expect(state.items, hasLength(1));
    expect(state.loadMoreError, 'offline');
    expect(state.isLoadingMore, isFalse);

    await bloc.close();
  });

  test('retry clears the error and loads the next page', () async {
    service.queue.add(
      Right(page([trend('a', createdAt: 20)], cursor: 'cur-1', hasMore: true)),
    );
    service.queue.add(const Left('offline'));
    service.queue.add(
      Right(page([trend('b', createdAt: 10)], cursor: 'cur-2', hasMore: false)),
    );

    final bloc = buildBloc();
    final loaded = waitFor(bloc, (state) => state.pagesLoaded == 1);
    bloc.add(const TrendFeedOpened());
    await loaded;

    final failed = waitFor(bloc, (state) => state.loadMoreError != null);
    bloc.add(const TrendFeedLoadMore());
    await failed;

    final recovered = waitFor(
      bloc,
      (state) => state.loadMoreError == null && state.pagesLoaded == 2,
    );
    bloc.add(const TrendFeedRetry());
    final state = await recovered;

    expect(state.items.map((item) => item.uid), ['a', 'b']);

    await bloc.close();
  });

  test('refresh resets the cursor and reloads the newest page', () async {
    service.queue.add(
      Right(page([trend('a', createdAt: 20)], cursor: 'cur-1', hasMore: true)),
    );
    service.queue.add(
      Right(page([trend('a', createdAt: 20)], cursor: 'cur-1', hasMore: true)),
    );

    final bloc = buildBloc();
    final loaded = waitFor(bloc, (state) => state.pagesLoaded == 1);
    bloc.add(const TrendFeedOpened());
    await loaded;

    final refreshed = waitFor(
      bloc,
      (state) => state.pagesLoaded == 1 && state.fromCache == false,
    );
    bloc.add(const TrendFeedRefresh());
    await refreshed;

    expect(service.requests.last.cursor, isNull);

    await bloc.close();
  });

  test('a refresh is not overwritten by an older in-flight page', () async {
    service.queue.add(
      Right(page([trend('a', createdAt: 20)], cursor: 'cur-1', hasMore: true)),
    );
    service.queue.add(
      Right(
        page(
          [trend('stale', createdAt: 5)],
          cursor: 'cur-stale',
          hasMore: true,
        ),
      ),
    );
    service.queue.add(
      Right(
        page(
          [trend('fresh', createdAt: 30)],
          cursor: 'cur-fresh',
          hasMore: true,
        ),
      ),
    );

    final bloc = buildBloc();
    final loaded = waitFor(bloc, (state) => state.pagesLoaded == 1);
    bloc.add(const TrendFeedOpened());
    await loaded;

    // Hold the load-more open, then refresh over the top of it.
    service.gate = Completer<void>();
    bloc.add(const TrendFeedLoadMore());
    await waitFor(bloc, (state) => state.isLoadingMore);

    service.gate = null;
    final refreshing = waitFor(
      bloc,
      (state) => state.items.any((item) => item.uid == 'fresh'),
    );
    bloc.add(const TrendFeedRefresh());
    await refreshing;

    // Let the stale page resolve; it must be discarded.
    service.gate?.complete();
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(bloc.state.items.map((item) => item.uid), isNot(contains('stale')));

    await bloc.close();
  });

  test('pages that add nothing are walked, then stop', () async {
    // The cache already holds everything the first two pages will return.
    for (var i = 0; i < 40; i++) {
      hive.store['c$i'] = trend('c$i', createdAt: 10000 - i);
    }
    service.queue.add(
      Right(
        page(
          [for (var i = 0; i < 20; i++) trend('c$i', createdAt: 10000 - i)],
          cursor: 'cur-1',
          hasMore: true,
        ),
      ),
    );
    service.queue.add(
      Right(
        page(
          [for (var i = 20; i < 40; i++) trend('c$i', createdAt: 10000 - i)],
          cursor: 'cur-2',
          hasMore: true,
        ),
      ),
    );
    service.queue.add(
      Right(
        page([trend('new', createdAt: 1)], cursor: 'cur-3', hasMore: false),
      ),
    );

    final bloc = buildBloc();
    final loaded = waitFor(bloc, (state) => state.pagesLoaded == 1);
    bloc.add(const TrendFeedOpened());
    await loaded;

    final finished = waitFor(bloc, (state) => state.hasMore == false);
    bloc.add(const TrendFeedLoadMore());
    final state = await finished;

    // Page 2 added nothing, so the bloc walked on to page 3 by itself.
    expect(service.requests, hasLength(3));
    expect(state.items.map((item) => item.uid), contains('new'));

    await bloc.close();
  });

  test('the duplicate walk is bounded', () async {
    for (var i = 0; i < 200; i++) {
      hive.store['c$i'] = trend('c$i', createdAt: 10000 - i);
    }
    for (var i = 0; i < 20; i++) {
      service.queue.add(
        Right(
          page(
            [for (var j = 0; j < 20; j++) trend('c$j', createdAt: 10000 - j)],
            cursor: 'cur-$i',
            hasMore: true,
          ),
        ),
      );
    }

    final bloc = buildBloc();
    final loaded = waitFor(bloc, (state) => state.pagesLoaded == 1);
    bloc.add(const TrendFeedOpened());
    await loaded;

    final stopped = waitFor(bloc, (state) => !state.isLoadingMore);
    bloc.add(const TrendFeedLoadMore());
    await stopped;

    // 1 initial page + at most maxDuplicatePages follow-ups.
    expect(
      service.requests.length,
      lessThanOrEqualTo(1 + TrendFeedBloc.maxDuplicatePages),
    );

    await bloc.close();
  });

  test('items are emitted newest first with a stable tie break', () async {
    service.queue.add(
      Right(
        page(
          [
            trend('b', createdAt: 100),
            trend('a', createdAt: 100),
            trend('c', createdAt: 200),
          ],
          cursor: 'cur-1',
          hasMore: false,
        ),
      ),
    );

    final bloc = buildBloc();
    final loaded = waitFor(bloc, (state) => state.pagesLoaded == 1);
    bloc.add(const TrendFeedOpened());
    final state = await loaded;

    expect(state.items.map((item) => item.uid), ['c', 'a', 'b']);
    expect(hive.getSortedItems().map((item) => item.uid), ['c', 'a', 'b']);

    await bloc.close();
  });

  test(
    'a cache mutation re-projects the feed without losing pagination',
    () async {
      service.queue.add(
        Right(
          page([trend('a', createdAt: 20)], cursor: 'cur-1', hasMore: true),
        ),
      );

      final bloc = buildBloc();
      final loaded = waitFor(bloc, (state) => state.pagesLoaded == 1);
      bloc.add(const TrendFeedOpened());
      await loaded;

      final updated = waitFor(bloc, (state) => state.items.first.uid == 'new');
      hive.store['new'] = trend('new', createdAt: 500);
      hive.changes.add(null);
      final state = await updated;

      expect(state.hasMore, isTrue); // pagination untouched
      expect(state.items.map((item) => item.uid), ['new', 'a']);

      await bloc.close();
    },
  );
}
