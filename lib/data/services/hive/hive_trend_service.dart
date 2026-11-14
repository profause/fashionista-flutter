import 'package:fashionista/core/service_locator/hive_service.dart';
import 'package:fashionista/data/models/trends/trend_feed_model.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

class HiveTrendService {
  //late final Box trendsBox;
  final hive = HiveService();

  /// Upper bound on cached trends. The feed appends every page it loads, so
  /// without a cap the box (and the sort over it) grows for the life of the
  /// install. Pruning only ever runs before a fresh load, never mid-scroll.
  static const int maxCachedItems = 500;

  /// Feed ordering: newest first, ties broken by uid.
  ///
  /// Mirrors Firestore's `created_at DESC` + implicit `__name__ ASC`, so a page
  /// fetched with a cursor lands where the local sort expects it.
  static int _compareFeedOrder(TrendFeedModel a, TrendFeedModel b) {
    final byDate = (b.createdAt ?? 0).compareTo(a.createdAt ?? 0);
    if (byDate != 0) return byDate;
    return (a.uid ?? '').compareTo(b.uid ?? '');
  }

  /// The whole cache in feed order.
  ///
  /// Drafts are left out by default: the cache is shared with the author's own
  /// posts, and a draft must never reach the public feed. Callers that own the
  /// post (the author's profile) ask for them explicitly.
  ///
  /// Reported trends are also hidden by default. They stay in the box so a
  /// later network refresh can overwrite the stale copy, but public
  /// projections never expose them.
  List<TrendFeedModel> getSortedItems({
    bool includeDrafts = false,
    bool includeReported = false,
  }) {
    try {
      final items = hive.trendsBox.values
          .where(
            (item) =>
                (includeDrafts || !item.isDraft) &&
                (includeReported || !item.isReported),
          )
          .toList();
      items.sort(_compareFeedOrder);
      return items;
    } catch (e) {
      debugPrint(e.toString());
    }
    return [];
  }

  /// Emits once per cache mutation, so a bloc can re-project the feed.
  Stream<void> itemChanges() {
    return hive.trendsBox.watch().map((_) {});
  }

  /// Drops the oldest trends beyond [maxCachedItems].
  ///
  /// The signed-in user's own posts are never pruned: the For You tab reads
  /// them from this same box.
  Future<void> pruneCache({String? keepAuthorUid}) async {
    try {
      final sorted = getSortedItems(includeDrafts: true, includeReported: true);
      if (sorted.length <= maxCachedItems) return;

      final doomed = sorted
          .skip(maxCachedItems)
          .where((item) => item.createdBy != keepAuthorUid)
          .map((item) => item.uid)
          .whereType<String>()
          .toList(growable: false);

      if (doomed.isEmpty) return;
      await hive.trendsBox.deleteAll(doomed);
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<List<TrendFeedModel>> getItems(String key) async {
    try {
      final data = hive.trendsBox.values;
      return data.toList();
    } catch (e) {
      debugPrint(e.toString());
    }
    return [];
  }

  Future<List<TrendFeedModel>> getItemsBelongsTo(String key) async {
    try {
      final data = hive.trendsBox.values;
      final filtered = data.where((item) => item.createdBy == key).toList();
      return filtered;
    } catch (e) {
      debugPrint(e.toString());
    }
    return [];
  }

  Future<void> insertItems(List<TrendFeedModel> items) async {
    try {
      final allI = items.map((e) {
        return hive.trendsBox.put(e.uid, e);
      });
      await Future.wait(allI);
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> updateItem(TrendFeedModel item) async {
    try {
      await hive.trendsBox.put(item.uid, item);
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> addItem(TrendFeedModel item) async {
    try {
      await hive.trendsBox.put(item.uid, item);
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> deleteItem(String uid) async {
    await hive.trendsBox.delete(uid);
  }

  Future<bool> isCacheEmpty() async {
    return hive.trendsBox.isEmpty;
  }

  Future<void> clearCache() async {
    await hive.trendsBox.clear();
  }

  Future<TrendFeedModel> getItem(String key) async {
    try {
      final data = hive.trendsBox.get(key);
      if (data == null) {
        return TrendFeedModel.empty();
      }
      return data;
    } catch (e) {
      debugPrint(e.toString());
    }
    return TrendFeedModel.empty();
  }

  ValueListenable<Box<TrendFeedModel>> itemListener() {
    return hive.trendsBox.listenable();
  }
}
