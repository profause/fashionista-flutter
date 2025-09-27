import 'package:fashionista/core/repository/hive_repository.dart';
import 'package:fashionista/core/service_locator/hive_service.dart';
import 'package:fashionista/data/models/work_order/work_order_status_progress_model.dart';
import 'package:flutter/foundation.dart';

class HiveWorkOrderStatusProgressService
    implements HiveRepository<WorkOrderStatusProgressModel> {
  //late final Box closetBox;
  final hive = HiveService();
  @override
  Future<void> clearCache() {
    return hive.workOrderStatusProgressBox.clear();
  }

  @override
  Future<WorkOrderStatusProgressModel> getItem(
    String key,
    String identifier,
  ) async {
    try {
      final data = hive.closetBox.get(key);
      if (data == null) {
        return WorkOrderStatusProgressModel.empty();
      }
      final List<WorkOrderStatusProgressModel> clientList = data
          .cast<WorkOrderStatusProgressModel>();
      return (clientList.where((item) => item.uid == identifier).first);
    } catch (e) {
      debugPrint(e.toString());
    }
    return WorkOrderStatusProgressModel.empty();
  }

  @override
  Future<List<WorkOrderStatusProgressModel>> getItems(String key) async {
    try {
      final data = hive.workOrderStatusProgressBox.get(key);
      if (data == null) {
        return ([]);
      }
      final List<WorkOrderStatusProgressModel> clientList = data
          .cast<WorkOrderStatusProgressModel>();
      return (clientList);
    } catch (e) {
      debugPrint(e.toString());
    }
    return [];
  }

  @override
  Future<void> insertItems(
    String key, {
    required List<WorkOrderStatusProgressModel> items,
  }) async {
    try {
      //await hive.workOrderStatusProgressBox.clear();
      await Future.wait([
        hive.workOrderStatusProgressBox.put(key, items),
        hive.workOrderStatusProgressBox.put(
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
    return hive.workOrderStatusProgressBox.isEmpty;
  }
}
