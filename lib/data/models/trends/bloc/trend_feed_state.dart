import 'package:equatable/equatable.dart';
import 'package:fashionista/data/models/trends/trend_feed_model.dart';

/// State of the paginated trends feed.
///
/// [items] is a projection of the Hive cache in feed order; the pagination
/// metadata (cursor, `hasMore`, loading flags) lives here because it cannot be
/// derived from the cache.
class TrendFeedState extends Equatable {
  final List<TrendFeedModel> items;

  /// First load of a feed that has nothing cached to paint.
  final bool isLoadingInitial;

  /// A page is being appended; the list stays on screen.
  final bool isLoadingMore;

  final bool hasMore;

  /// Failure of a first load that had no cache to fall back to.
  final String? initialError;

  /// Failure while appending, shown as a retry at the bottom of the feed.
  final String? loadMoreError;

  /// The visible items came from the cache, not from the network.
  final bool fromCache;

  /// Pages appended since the last reset; part of `props` so every page
  /// advances the state even when it added nothing new.
  final int pagesLoaded;

  const TrendFeedState({
    this.items = const [],
    this.isLoadingInitial = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.initialError,
    this.loadMoreError,
    this.fromCache = false,
    this.pagesLoaded = 0,
  });

  TrendFeedState copyWith({
    List<TrendFeedModel>? items,
    bool? isLoadingInitial,
    bool? isLoadingMore,
    bool? hasMore,
    String? initialError,
    String? loadMoreError,
    bool? fromCache,
    int? pagesLoaded,
    bool clearInitialError = false,
    bool clearLoadMoreError = false,
  }) {
    return TrendFeedState(
      items: items ?? this.items,
      isLoadingInitial: isLoadingInitial ?? this.isLoadingInitial,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      initialError: clearInitialError
          ? null
          : initialError ?? this.initialError,
      loadMoreError: clearLoadMoreError
          ? null
          : loadMoreError ?? this.loadMoreError,
      fromCache: fromCache ?? this.fromCache,
      pagesLoaded: pagesLoaded ?? this.pagesLoaded,
    );
  }

  bool get isEmpty => items.isEmpty;

  @override
  List<Object?> get props => [
    items,
    isLoadingInitial,
    isLoadingMore,
    hasMore,
    initialError,
    loadMoreError,
    fromCache,
    pagesLoaded,
  ];
}
