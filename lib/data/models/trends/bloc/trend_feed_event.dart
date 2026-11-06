import 'package:equatable/equatable.dart';

abstract class TrendFeedEvent extends Equatable {
  const TrendFeedEvent();

  @override
  List<Object?> get props => [];
}

/// First load: paint the cache, then fetch the newest page.
///
/// [uid] is optional and defaults to the signed-in user; it is used to protect
/// the viewer's own cached posts from pruning.
class TrendFeedOpened extends TrendFeedEvent {
  final String? uid;
  const TrendFeedOpened({this.uid});

  @override
  List<Object?> get props => [uid];
}

/// Fired by the sentinel when the end of the feed is near.
class TrendFeedLoadMore extends TrendFeedEvent {
  const TrendFeedLoadMore();
}

/// Pull-to-refresh: reset the cursor and reload the newest page.
class TrendFeedRefresh extends TrendFeedEvent {
  const TrendFeedRefresh();
}

/// Retry after a failed page.
class TrendFeedRetry extends TrendFeedEvent {
  const TrendFeedRetry();
}

/// Internal: the Hive cache changed, re-project the feed.
class TrendFeedCacheChanged extends TrendFeedEvent {
  const TrendFeedCacheChanged();
}
