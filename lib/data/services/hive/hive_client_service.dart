import 'package:fashionista/core/service_locator/hive_service.dart';
import 'package:fashionista/data/models/clients/client_model.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

class HiveClientService  {
  //late final Box clientsBox;
  final hive = HiveService();

  Future<List<Client>> getItems(String key) async {
    try {
      final data = hive.clientsBox.values;
      return data.toList();
    } catch (e) {
      debugPrint(e.toString());
    }
    return [];
  }

  Future<void> insertItems(List<Client> items) async {
    try {
      await hive.clientsBox.clear();
      final allI = items.map((e) {
        return hive.clientsBox.put(e.uid, e);
      });
      await Future.wait(allI);
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> updateItem(Client item) async {
    try {
      await hive.clientsBox.put(item.uid, item);
    } catch (e) {
      debugPrint(e.toString());
    }
  }

    Future<void> addItem(Client item) async {
    try {
      await hive.clientsBox.put(item.uid, item);
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> deleteItem(String uid) async {
    await hive.clientsBox.delete(uid);
  }

  Future<bool> isCacheEmpty() async {
    return hive.clientsBox.isEmpty;
  }

  Future<void> clearCache() async {
    await hive.clientsBox.clear();
  }

  Future<Client> getItem(String key) async {
    try {
      final data = hive.clientsBox.get(key);
      if (data == null) {
        return Client.empty();
      }
      return data;
    } catch (e) {
      debugPrint(e.toString());
    }
    return Client.empty();
  }

  ValueListenable<Box<Client>> itemListener() {
    return hive.clientsBox.listenable();
  }
}
