import 'package:fashionista/core/repository/hive_repository.dart';
import 'package:fashionista/core/service_locator/hive_service.dart';
import 'package:fashionista/data/models/work_order/work_order_model.dart';
import 'package:flutter/foundation.dart';

class HiveWorkOrderService implements HiveRepository<WorkOrderModel> {
  //late final Box closetBox;
  final hive = HiveService();
  @override
  Future<void> clearCache() {
    return hive.workOrderBox.clear();
  }

  @override
  Future<WorkOrderModel> getItem(String key, String identifier) async {
    try {
      final data = hive.closetBox.get('work_orders');
      if (data == null) {
        return WorkOrderModel.empty();
      }
      final List<WorkOrderModel> clientList = data.cast<WorkOrderModel>();
      return (clientList.where((item) => item.uid == identifier).first);
    } catch (e) {
      debugPrint(e.toString());
    }
    return WorkOrderModel.empty();
  }

  @override
  Future<List<WorkOrderModel>> getItems(String key) async {
    try {
      final data = hive.workOrderBox.get('work_orders');
      if (data == null) {
        return ([]);
      }
      final List<WorkOrderModel> clientList = data.cast<WorkOrderModel>();
      return (clientList);
    } catch (e) {
      debugPrint(e.toString());
    }
    return [];
  }

  @override
  Future<void> insertItems(
    String key, {
    required List<WorkOrderModel> items,
  }) async {
    try {
      //await hive.workOrderBox.clear();
      await Future.wait([
        hive.workOrderBox.put('work_orders', items),
        hive.workOrderBox.put(
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
    return hive.workOrderBox.isEmpty;
  }
}
