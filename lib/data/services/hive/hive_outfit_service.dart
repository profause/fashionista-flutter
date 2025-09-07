import 'package:fashionista/core/repository/hive_repository.dart';
import 'package:fashionista/core/service_locator/hive_service.dart';
import 'package:fashionista/data/models/closet/outfit_model.dart';
import 'package:flutter/material.dart';

class HiveOutfitService implements HiveRepository<OutfitModel> {
  //late final Box closetBox;
  final hive = HiveService();

  @override
  Future<List<OutfitModel>> getItems(String key) async {
    try {
      final data = hive.closetBox.get('outfits');
      if (data == null) {
        return ([]);
      }
      final List<OutfitModel> clientList = data.cast<OutfitModel>();
      return (clientList);
    } catch (e) {
      debugPrint(e.toString());
    }
    return [];
  }

  @override
  Future<void> insertItems(String key, {required List<OutfitModel> items}) async {
    try {
      //await hive.closetBox.clear();
      await Future.wait([
        hive.closetBox.put('outfits', items),
        hive.closetBox.put(
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
    return hive.closetBox.isEmpty;
  }

  @override
  Future<void> clearCache() {
    return hive.closetBox.clear();
  }
}
