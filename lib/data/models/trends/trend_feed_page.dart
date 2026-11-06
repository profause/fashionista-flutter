import 'package:equatable/equatable.dart';
import 'package:fashionista/data/models/trends/trend_feed_model.dart';

/// One page of the trends feed, newest first.
///
/// The cursor is the Firestore document snapshot of the last returned trend,
/// not its `created_at` value: two trends shared by the same millisecond would
/// otherwise be skipped or fetched twice.
class TrendFeedPage extends Equatable {
  final List<TrendFeedModel> trends;

  /// Opaque cursor for the next page; `null` on an empty page.
  ///
  /// Production carries a Firestore `DocumentSnapshot`; keeping the type
  /// opaque here lets the bloc be unit tested without a live Firestore, and
  /// confines the cast to the service.
  final Object? cursor;

  /// Exact: derived from a `limit + 1` probe, not a heuristic.
  final bool hasMore;

  const TrendFeedPage({
    required this.trends,
    this.cursor,
    this.hasMore = false,
  });

  static const TrendFeedPage empty = TrendFeedPage(trends: []);

  bool get isEmpty => trends.isEmpty;

  @override
  List<Object?> get props => [trends, cursor, hasMore];
}
