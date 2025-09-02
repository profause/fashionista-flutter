import 'package:fashionista/core/repository/hive_repository.dart';
import 'package:fashionista/core/service_locator/hive_service.dart';
import 'package:fashionista/data/models/trends/trend_feed_model.dart';
import 'package:flutter/material.dart';

class HiveTrendService
    implements HiveRepository<TrendFeedModel> {
  //late final Box trendsBox;
  final hive = HiveService();

  @override
  Future<List<TrendFeedModel>> getItems(String key) async {
    try {
      final data = hive.trendsBox.get(key);
      if (data == null) {
        return ([]);
      }
      final List<TrendFeedModel> designCollectionList = data
          .cast<TrendFeedModel>();
      return (designCollectionList);
    } catch (e) {
      debugPrint(e.toString());
    }
    return [];
  }

  @override
  Future<void> insertItems(
    String key, {
    required List<TrendFeedModel> items,
  }) async {
    try {
      await Future.wait([
        hive.trendsBox.put(key, items),
        hive.trendsBox.put(
          'cacheTimestamp',
          DateTime.now().millisecondsSinceEpoch,
        ),
      ]);
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  @override
  Future<bool> isCacheEmpty() async {
    return hive.trendsBox.isEmpty;
  }

  @override
  Future<void> clearCache() async {
    await hive.trendsBox.clear();
  }
}
