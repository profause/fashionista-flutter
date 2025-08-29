import 'package:fashionista/core/repository/hive_repository.dart';
import 'package:fashionista/core/service_locator/hive_service.dart';
import 'package:fashionista/data/models/designers/designer_model.dart';
import 'package:flutter/material.dart';

class HiveDesignersService implements HiveRepository<Designer> {
  //late final Box designersBox;
  static const _key = 'designers';

  final hive = HiveService();

  @override
  Future<List<Designer>> getItems(String key) async {
    try {
      final data = hive.designersBox.get(_key);
      if (data == null) {
        return ([]);
      }
      final List<Designer> designerList = data.cast<Designer>();
      return (designerList);
    } catch (e) {
      debugPrint(e.toString());
    }
    return [];
  }

  @override
  Future<void> insertItems(String key, {required List<Designer> items}) async {
    try {
      await hive.designersBox.clear();
      await hive.designersBox.put('designers', items);
      await hive.designersBox.put(
        'cacheTimestamp',
        DateTime.now().millisecondsSinceEpoch,
      );
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
    final r = await hive.designersBox.clear();
    debugPrint('clearCache: $r');
  }
}
