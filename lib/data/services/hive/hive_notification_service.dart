import 'package:fashionista/core/repository/hive_repository.dart';
import 'package:fashionista/core/service_locator/hive_service.dart';
import 'package:fashionista/data/models/notification/notification_model.dart';
import 'package:flutter/material.dart';

class HiveNotificationService implements HiveRepository<NotificationModel> {
  //late final Box notificationsBox;

  final hive = HiveService();

  @override
  Future<List<NotificationModel>> getItems(String key) async {
    try {
      final data = hive.notificationsBox.get(key);
      if (data == null) {
        return ([]);
      }
      final List<NotificationModel> notificationList = data.cast<NotificationModel>();
      return (notificationList);
    } catch (e) {
      debugPrint(e.toString());
    }
    return [];
  }

  @override
  Future<void> insertItems(String key, {required List<NotificationModel> items}) async {
    try {
      await hive.notificationsBox.clear();
      await Future.wait([
        hive.notificationsBox.put(key, items),
        hive.notificationsBox.put(
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
    return hive.notificationsBox.isEmpty;
  }

  @override
  Future<void> clearCache() async{
    await hive.notificationsBox.clear();
  }
  
  @override
  Future<NotificationModel> getItem(String key, String identifier) async {
    try {
      final data = hive.notificationsBox.get(key);
      if (data == null) {
        return NotificationModel.empty();
      }
      final List<NotificationModel> notificationList = data.cast<NotificationModel>();
      return (notificationList.where((notification) => notification.uid == identifier).first);
    } catch (e) {
      debugPrint(e.toString());
    }
    return NotificationModel.empty();
  }
}
