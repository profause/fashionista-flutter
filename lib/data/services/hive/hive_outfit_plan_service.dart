import 'package:fashionista/core/repository/hive_repository.dart';
import 'package:fashionista/core/service_locator/hive_service.dart';
import 'package:fashionista/data/models/closet/outfit_plan_model.dart';
import 'package:flutter/material.dart';

class HiveOutfitPlanService implements HiveRepository<OutfitPlanModel> {
  //late final Box closetBox;
  final hive = HiveService();

  @override
  Future<List<OutfitPlanModel>> getItems(String key) async {
    try {
      final data = hive.closetBox.get('outfit_plans');
      if (data == null) {
        return ([]);
      }
      final List<OutfitPlanModel> clientList = data.cast<OutfitPlanModel>();
      return (clientList);
    } catch (e) {
      debugPrint(e.toString());
    }
    return [];
  }

  @override
  Future<void> insertItems(String key, {required List<OutfitPlanModel> items}) async {
    try {
      //await hive.closetBox.clear();
      await Future.wait([
        hive.closetBox.put('outfit_plans', items),
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
  
  @override
  Future<OutfitPlanModel> getItem(String key, String identifier) async {
    try {
      final data = hive.closetBox.get('outfit_plans');
      if (data == null) {
        return OutfitPlanModel.empty();
      }
      final List<OutfitPlanModel> clientList = data.cast<OutfitPlanModel>();
      return (clientList.where((item) => item.uid == identifier).first);
    } catch (e) {
      debugPrint(e.toString());
    }
    return OutfitPlanModel.empty();
  }
}
