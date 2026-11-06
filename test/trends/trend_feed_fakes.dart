import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:fashionista/data/models/author/author_model.dart';
import 'package:fashionista/data/models/comment/comment_model.dart';
import 'package:fashionista/data/models/social_interactions/social_interaction_model.dart';
import 'package:fashionista/data/models/trends/trend_feed_model.dart';
import 'package:fashionista/data/models/trends/trend_feed_page.dart';
import 'package:fashionista/data/services/firebase/firebase_trends_service.dart';
import 'package:fashionista/data/services/hive/hive_trend_service.dart';

const String viewerUid = 'viewer_1';

TrendFeedModel trend(String id, {int createdAt = 0, String? createdBy}) {
  return TrendFeedModel(
    uid: id,
    description: 'Trend $id',
    featuredMedia: const [],
    createdAt: createdAt,
    updatedAt: createdAt,
    createdBy: createdBy ?? 'author_x',
    tags: '',
    author: const AuthorModel(uid: 'author_x', name: 'Author X', avatar: ''),
  );
}

TrendFeedPage page(
  List<TrendFeedModel> trends, {
  Object? cursor,
  bool hasMore = false,
}) {
  return TrendFeedPage(trends: trends, cursor: cursor, hasMore: hasMore);
}

class FakeTrendsService implements FirebaseTrendsService {
  final List<({int limit, Object? cursor})> requests = [];
  final List<Either<String, TrendFeedPage>> queue = [];

  /// Held open to simulate a slow page; complete it to let the call return.
  Completer<void>? gate;

  @override
  Future<Either<String, TrendFeedPage>> fetchTrendsPage({
    int limit = 20,
    Object? cursor,
  }) async {
    requests.add((limit: limit, cursor: cursor));

    final result = queue.isEmpty
        ? const Right<String, TrendFeedPage>(TrendFeedPage.empty)
        : queue.removeAt(0);

    if (gate != null) await gate!.future;
    return result;
  }

  @override
  Future<Either> findTrendsCreatedBy(String createdBy) async =>
      throw UnimplementedError();
  @override
  Future<Either<String, List<TrendFeedModel>>> fetchTrendsCreatedBy(
    int limit,
    String createdBy,
  ) async => throw UnimplementedError();
  @override
  Future<Either<String, List<TrendFeedModel>>> fetchTrendsByTag(
    String tag, {
    int limit = 100,
  }) async => throw UnimplementedError();
  @override
  Future<Either> addTrendToFirestore(TrendFeedModel trend) async =>
      throw UnimplementedError();
  @override
  Future<Either> updateTrendToFirestore(TrendFeedModel trend) async =>
      throw UnimplementedError();
  @override
  Future<Either> deleteTrendById(String uid) async =>
      throw UnimplementedError();
  @override
  Future<Either> findTrendById(String uid) async => throw UnimplementedError();
  @override
  Future<Either> likeOrUnlikeTrend(SocialInteractionModel like) async =>
      throw UnimplementedError();
  @override
  Future<Either> followOrUnFollowTrend(SocialInteractionModel follow) async =>
      throw UnimplementedError();
  @override
  Future<bool> isFollowedTrend(String uid) async => false;
  @override
  Future<bool> isLikedTrend(String uid) async => false;
  @override
  Future<Either> fetchFollowedTrends(List<String> uids) async =>
      throw UnimplementedError();
  @override
  Future<Either> addCommentToTrend(CommentModel comment) async =>
      throw UnimplementedError();
  @override
  Future<Either> deleteCommentToTrend(CommentModel comment) async =>
      throw UnimplementedError();
  @override
  Future<Either> findTrendComments(String uid) async =>
      throw UnimplementedError();
  @override
  Future<Either> deleteTrendImage(String imageUrl) async =>
      throw UnimplementedError();
}

/// In-memory stand-in for the Hive box.
class FakeHiveTrendService extends HiveTrendService {
  final Map<String, TrendFeedModel> store = {};
  final StreamController<void> changes = StreamController<void>.broadcast();

  int pruneCalls = 0;
  String? prunedForUid;

  @override
  List<TrendFeedModel> getSortedItems() {
    final items = store.values.toList();
    items.sort((a, b) {
      final byDate = (b.createdAt ?? 0).compareTo(a.createdAt ?? 0);
      if (byDate != 0) return byDate;
      return (a.uid ?? '').compareTo(b.uid ?? '');
    });
    return items;
  }

  @override
  Stream<void> itemChanges() => changes.stream;

  @override
  Future<void> insertItems(List<TrendFeedModel> items) async {
    for (final item in items) {
      store[item.uid!] = item;
    }
  }

  @override
  Future<void> pruneCache({String? keepAuthorUid}) async {
    pruneCalls += 1;
    prunedForUid = keepAuthorUid;
  }
}

