import 'package:fashionista/core/service_locator/hive_service.dart';
import 'package:fashionista/data/models/trends/trend_feed_model.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

class HiveTrendService {
  //late final Box trendsBox;
  final hive = HiveService();

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
