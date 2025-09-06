import 'package:fashionista/core/repository/hive_repository.dart';
import 'package:fashionista/core/service_locator/hive_service.dart';
import 'package:fashionista/data/models/closet/closet_item_model.dart';
import 'package:flutter/material.dart';

class HiveClosetItemService implements HiveRepository<ClosetItemModel> {
  //late final Box clientsBox;
  final hive = HiveService();

  @override
  Future<List<ClosetItemModel>> getItems(String key) async {
    try {
      final data = hive.clientsBox.get(key);
      if (data == null) {
        return ([]);
      }
      final List<ClosetItemModel> clientList = data.cast<ClosetItemModel>();
      return (clientList);
    } catch (e) {
      debugPrint(e.toString());
    }
    return [];
  }

  @override
  Future<void> insertItems(String key, {required List<ClosetItemModel> items}) async {
    try {
      //await hive.clientsBox.clear();
      await Future.wait([
        hive.clientsBox.put(key, items),
        hive.clientsBox.put(
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
    return hive.clientsBox.isEmpty;
  }

  @override
  Future<void> clearCache() {
    return hive.clientsBox.clear();
  }
}
