import 'package:fashionista/core/service_locator/hive_service.dart';
import 'package:fashionista/data/models/notification/notification_model.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/adapters.dart';

class HiveNotificationService {
  //late final Box notificationsBox;

  final hive = HiveService();

  Future<List<NotificationModel>> getItems(String key) async {
    try {
      final data = hive.notificationsBox.values;
      return data.toList();
    } catch (e) {
      debugPrint(e.toString());
    }
    return [];
  }

  Future<void> insertItems(
    String key, {
    required List<NotificationModel> items,
  }) async {
    try {
      await hive.notificationsBox.clear();
      final allI = items.map((e) {
        return hive.notificationsBox.put(e.uid, e);
      });
      await Future.wait(allI);
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> updateItem(NotificationModel item) async {
    try {
      await hive.notificationsBox.put(item.uid, item);
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> deleteItem(String uid) async {
    await hive.notificationsBox.delete(uid);
  }

  Future<bool> isCacheEmpty() async {
    return hive.notificationsBox.isEmpty;
  }

  Future<void> clearCache() async {
    await hive.notificationsBox.clear();
  }

  Future<NotificationModel> getItem(String key, String identifier) async {
    try {
      final data = hive.notificationsBox.get(key);
      if (data == null) {
        return NotificationModel.empty();
      }
      return data;
    } catch (e) {
      debugPrint(e.toString());
    }
    return NotificationModel.empty();
  }

  ValueListenable<Box<NotificationModel>> itemListener() {
    return hive.notificationsBox.listenable();
  }
}
