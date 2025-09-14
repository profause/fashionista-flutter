import 'package:fashionista/core/repository/hive_repository.dart';
import 'package:fashionista/core/service_locator/hive_service.dart';
import 'package:fashionista/data/models/comment/comment_model.dart';
import 'package:flutter/material.dart';

class HiveTrendCommentService
    implements HiveRepository<CommentModel> {
  //late final Box designCollectionsBox;
  final hive = HiveService();

  @override
  Future<List<CommentModel>> getItems(String key) async {
    try {
      final data = hive.designCollectionsBox.get(key);
      if (data == null) {
        return ([]);
      }
      final List<CommentModel> designCollectionList = data
          .cast<CommentModel>();
      return (designCollectionList);
    } catch (e) {
      debugPrint(e.toString());
    }
    return [];
  }

  @override
  Future<void> insertItems(
    String key, {
    required List<CommentModel> items,
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
  Future<CommentModel> getItem(String key, String identifier) async {
    try {
      final data = hive.designCollectionsBox.get(key);
      if (data == null) {
        return CommentModel.empty();
      }
      final List<CommentModel> clientList = data
          .cast<CommentModel>();
      return (clientList.where((item) => item.uid == identifier).first);
    } catch (e) {
      debugPrint(e.toString());
    }
    return CommentModel.empty();
  }
}
