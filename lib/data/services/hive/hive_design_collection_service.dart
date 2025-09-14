import 'package:fashionista/core/repository/hive_repository.dart';
import 'package:fashionista/core/service_locator/hive_service.dart';
import 'package:fashionista/data/models/designers/design_collection_model.dart';
import 'package:flutter/material.dart';

class HiveDesignCollectionService
    implements HiveRepository<DesignCollectionModel> {
  //late final Box designCollectionsBox;
  final hive = HiveService();

  @override
  Future<List<DesignCollectionModel>> getItems(String key) async {
    try {
      final data = hive.designCollectionsBox.get(key);
      if (data == null) {
        return ([]);
      }
      final List<DesignCollectionModel> designCollectionList = data
          .cast<DesignCollectionModel>();
      return (designCollectionList);
    } catch (e) {
      debugPrint(e.toString());
    }
    return [];
  }

  @override
  Future<void> insertItems(
    String key, {
    required List<DesignCollectionModel> items,
  }) async {
    try {
      //await hive.designCollectionsBox.clear();
      await Future.wait([
        hive.designCollectionsBox.put(key, items),
        hive.designCollectionsBox.put(
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
    return hive.designCollectionsBox.isEmpty;
  }

  @override
  Future<void> clearCache() async {
    await hive.designCollectionsBox.clear();
  }

  @override
  Future<DesignCollectionModel> getItem(String key, String identifier) async {
    try {
      final data = hive.designCollectionsBox.get(key);
      if (data == null) {
        return DesignCollectionModel.empty();
      }
      final List<DesignCollectionModel> clientList = data
          .cast<DesignCollectionModel>();
      return (clientList.where((item) => item.uid == identifier).first);
    } catch (e) {
      debugPrint(e.toString());
    }
    return DesignCollectionModel.empty();
  }
}
