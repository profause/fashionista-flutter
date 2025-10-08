import 'package:fashionista/core/repository/hive_repository.dart';
import 'package:fashionista/core/service_locator/hive_service.dart';
import 'package:fashionista/data/models/designers/designer_review_model.dart';
import 'package:flutter/material.dart';

class HiveDesignerReviewsService implements HiveRepository<DesignerReviewModel> {
  //late final Box designerReviewsBox;

  final hive = HiveService();

  @override
  Future<List<DesignerReviewModel>> getItems(String key) async {
    try {
      final data = hive.designersBox.get(key);
      if (data == null) {
        return ([]);
      }
      final List<DesignerReviewModel> designerList = data.cast<DesignerReviewModel>();
      return (designerList);
    } catch (e) {
      debugPrint(e.toString());
    }
    return [];
  }

  @override
  Future<void> insertItems(String key, {required List<DesignerReviewModel> items}) async {
    try {
      await hive.designersBox.clear();
      await Future.wait([
        hive.designersBox.put(key, items),
        hive.designersBox.put(
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
    return hive.designersBox.isEmpty;
  }

  @override
  Future<void> clearCache() async{
    await hive.designersBox.clear();
  }
  
  @override
  Future<DesignerReviewModel> getItem(String key, String identifier) async {
    try {
      final data = hive.designersBox.get(key);
      if (data == null) {
        return DesignerReviewModel.empty();
      }
      final List<DesignerReviewModel> designerList = data.cast<DesignerReviewModel>();
      return (designerList.where((designer) => designer.uid == identifier).first);
    } catch (e) {
      debugPrint(e.toString());
    }
    return DesignerReviewModel.empty();
  }
}
