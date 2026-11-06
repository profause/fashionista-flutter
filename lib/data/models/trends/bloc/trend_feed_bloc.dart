import 'dart:async';

import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/data/models/trends/bloc/trend_feed_event.dart';
import 'package:fashionista/data/models/trends/bloc/trend_feed_state.dart';
import 'package:fashionista/data/models/trends/trend_feed_page.dart';
import 'package:fashionista/data/services/firebase/firebase_trends_service.dart';
import 'package:fashionista/data/services/hive/hive_trend_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Paginated trends feed.
///
/// The items themselves live in the Hive cache (that is what makes the feed
/// paint instantly and survive restarts); this bloc owns the part the cache
/// cannot know: the page cursor, whether more exists, and loading/error state.
class TrendFeedBloc extends Bloc<TrendFeedEvent, TrendFeedState> {
  TrendFeedBloc({String? Function()? userIdProvider})
    : _userIdProvider = userIdProvider ?? _signedInUserId,
      super(const TrendFeedState()) {
    on<TrendFeedOpened>(_onOpened);
    on<TrendFeedRefresh>(_onRefresh);
    on<TrendFeedLoadMore>(_onLoadMore);
    on<TrendFeedRetry>(_onRetry);
    on<TrendFeedCacheChanged>(_onCacheChanged);

    _cacheSubscription = sl<HiveTrendService>().itemChanges().listen((_) {
      if (isClosed) return;
      add(const TrendFeedCacheChanged());
    });
  }

  /// Default page size for the feed.
  static const int pageSize = 20;

  /// How many consecutive pages may add nothing before we stop walking.
  ///
  /// The cache outlives a session, so it can already hold documents older than
  /// the newest page; those pages fetch fine but add nothing visible.
  static const int maxDuplicatePages = 5;

  final String? Function() _userIdProvider;

  static String? _signedInUserId() => FirebaseAuth.instance.currentUser?.uid;

  late final StreamSubscription<void> _cacheSubscription;

  /// Cursor of the last fetched page; `null` until the first page lands.
  Object? _cursor;

  /// Bumped on every fresh load so an older in-flight page cannot overwrite it.
  int _generation = 0;

  String? _ownerUid;

  @override
  Future<void> close() async {
    await _cacheSubscription.cancel();
    return super.close();
  }

  Future<void> _onOpened(
    TrendFeedOpened event,
    Emitter<TrendFeedState> emit,
  ) {
    final uid = event.uid ?? _userIdProvider() ?? '';
    return _loadFirstPage(emit, uid: uid);
  }

  Future<void> _onRefresh(
    TrendFeedRefresh event,
    Emitter<TrendFeedState> emit,
  ) {
    return _loadFirstPage(emit, uid: _ownerUid ?? _userIdProvider() ?? '');
  }

  /// Paints the cache, then replaces it with the newest page.
  Future<void> _loadFirstPage(
    Emitter<TrendFeedState> emit, {
    required String uid,
  }) async {
    final generation = ++_generation;
    _cursor = null;
    _ownerUid = uid;

    // Pruned before painting, never mid-scroll: trimming during pagination
    // would delete cards the user is currently looking at.
    await sl<HiveTrendService>().pruneCache(
      keepAuthorUid: uid.isEmpty ? null : uid,
    );
    if (generation != _generation) return;

    final cached = sl<HiveTrendService>().getSortedItems();
    final hasCache = cached.isNotEmpty;

    emit(
      state.copyWith(
        items: cached,
        isLoadingInitial: !hasCache,
        isLoadingMore: false,
        hasMore: true,
        fromCache: hasCache,
        clearInitialError: true,
        clearLoadMoreError: true,
      ),
    );

    final result = await sl<FirebaseTrendsService>().fetchTrendsPage(
      limit: pageSize,
    );
    if (generation != _generation) return;

    await result.fold(
      (failure) async {
        final items = sl<HiveTrendService>().getSortedItems();

        if (items.isEmpty) {
          emit(
            state.copyWith(
              isLoadingInitial: false,
              initialError: failure.toString(),
              hasMore: false,
            ),
          );
          return;
        }

        // A failure must never blank a feed that is already on screen. Stop the
        // sentinel (no cursor to continue from) and offer the retry instead.
        emit(
          state.copyWith(
            isLoadingInitial: false,
            hasMore: false,
            loadMoreError: failure.toString(),
          ),
        );
      },
      (page) async {
        _cursor = page.cursor;
        await sl<HiveTrendService>().insertItems(page.trends);
        if (generation != _generation) return;

        emit(
          state.copyWith(
            items: sl<HiveTrendService>().getSortedItems(),
            isLoadingInitial: false,
            isLoadingMore: false,
            hasMore: page.hasMore,
            fromCache: false,
            pagesLoaded: 1,
            clearInitialError: true,
            clearLoadMoreError: true,
          ),
        );
      },
    );
  }

  /// Appends the next page, keeping everything already on screen.
  Future<void> _onLoadMore(
    TrendFeedLoadMore event,
    Emitter<TrendFeedState> emit,
  ) async {
    if (state.isLoadingInitial || state.isLoadingMore) return; // rapid scroll
    if (!state.hasMore) return;
    if (_cursor == null) return; // the first page still owns the feed

    final generation = _generation;

    emit(state.copyWith(isLoadingMore: true, clearLoadMoreError: true));

    var duplicatePages = 0;

    while (true) {
      final result = await sl<FirebaseTrendsService>().fetchTrendsPage(
        limit: pageSize,
        cursor: _cursor,
      );

      // A refresh started while this page was loading: drop the stale result.
      if (generation != _generation) return;

      final failure = result.fold<String?>(
        (failure) => failure.toString(),
        (_) => null,
      );

      if (failure != null) {
        emit(state.copyWith(isLoadingMore: false, loadMoreError: failure));
        return;
      }

      final page = result.getOrElse(() => TrendFeedPage.empty);
      _cursor = page.cursor ?? _cursor;

      final seen = sl<HiveTrendService>()
          .getSortedItems()
          .map((trend) => trend.uid)
          .whereType<String>()
          .toSet();

      await sl<HiveTrendService>().insertItems(page.trends);
      if (generation != _generation) return;

      final added = page.trends
          .where((trend) => !seen.contains(trend.uid))
          .length;

      duplicatePages = added == 0 ? duplicatePages + 1 : 0;
      final shouldContinue =
          added == 0 &&
          page.hasMore &&
          duplicatePages < maxDuplicatePages;

      emit(
        state.copyWith(
          // Always a new list: Equatable compares list identity, so mutating in
          // place would not rebuild the feed.
          items: sl<HiveTrendService>().getSortedItems(),
          hasMore: page.hasMore,
          isLoadingMore: shouldContinue,
          fromCache: false,
          pagesLoaded: state.pagesLoaded + 1,
          clearLoadMoreError: true,
        ),
      );

      if (!shouldContinue) return;
    }
  }

  Future<void> _onRetry(
    TrendFeedRetry event,
    Emitter<TrendFeedState> emit,
  ) async {
    final uid = _ownerUid ?? _userIdProvider() ?? '';

    // No cursor means the failure was the first page, not an appended one.
    if (_cursor == null) {
      await _loadFirstPage(emit, uid: uid);
      return;
    }

    emit(state.copyWith(clearLoadMoreError: true));
    await _onLoadMore(const TrendFeedLoadMore(), emit);
  }

  void _onCacheChanged(
    TrendFeedCacheChanged event,
    Emitter<TrendFeedState> emit,
  ) {
    final items = sl<HiveTrendService>().getSortedItems();

    // Skip identical projections so an unrelated cache write (My Posts, a
    // like count) does not rebuild the feed.
    final current = state.items
        .map((trend) => trend.uid)
        .whereType<String>()
        .toList(growable: false);
    final next = items
        .map((trend) => trend.uid)
        .whereType<String>()
        .toList(growable: false);

    if (current.length == next.length) {
      var same = true;
      for (var i = 0; i < current.length; i++) {
        if (current[i] != next[i]) {
          same = false;
          break;
        }
      }
      if (same) return;
    }

    emit(state.copyWith(items: items));
  }
}
