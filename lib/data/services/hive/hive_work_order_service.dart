import 'package:fashionista/core/service_locator/hive_service.dart';
import 'package:fashionista/data/models/work_order/work_order_model.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

class HiveWorkOrderService {
  //late final Box closetBox;
  final hive = HiveService();

  Future<void> clearCache() {
    return hive.workOrderBox.clear();
  }

  Future<WorkOrderModel> getItem(String key) async {
    try {
      final data = hive.workOrderBox.get(key);
      if (data == null) {
        return WorkOrderModel.empty();
      }
      return data;
    } catch (e) {
      debugPrint(e.toString());
    }
    return WorkOrderModel.empty();
  }

  Future<List<WorkOrderModel>> getItems(String key) async {
    try {
      final data = hive.workOrderBox.values;
      return data.toList();
    } catch (e) {
      debugPrint(e.toString());
    }
    return [];
  }

  Future<void> insertItems(List<WorkOrderModel> items) async {
    try {
      //await hive.workOrderBox.clear();
      final allI = items.map((e) {
        return hive.workOrderBox.put(e.uid, e);
      });
      await Future.wait(allI);
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> updateItem(WorkOrderModel item) async {
    try {
      await hive.workOrderBox.put(item.uid, item);
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> addItem(WorkOrderModel item) async {
    try {
      await hive.workOrderBox.put(item.uid, item);
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> deleteItem(String uid) async {
    await hive.workOrderBox.delete(uid);
  }

  Future<bool> isCacheEmpty() async {
    return hive.workOrderBox.isEmpty;
  }

  ValueListenable<Box<WorkOrderModel>> itemListener() {
    return hive.workOrderBox.listenable();
  }
}
