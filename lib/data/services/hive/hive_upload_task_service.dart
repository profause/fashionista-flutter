import 'dart:convert';

import 'package:fashionista/core/service_locator/hive_service.dart';
import 'package:fashionista/data/models/video/pending_publish_task.dart';
import 'package:flutter/foundation.dart';

/// Stores video uploads whose Cloudinary step succeeded but whose Firestore
/// write did not, so publishing can be retried without re-uploading.
class HiveUploadTaskService {
  final hive = HiveService();

  Future<List<PendingPublishTask>> all() async {
    try {
      final tasks = <PendingPublishTask>[];

      for (final raw in hive.uploadTasksBox.values) {
        final decoded = jsonDecode(raw);
        if (decoded is! Map) continue;
        final task = PendingPublishTask.fromJson(
          Map<String, dynamic>.from(decoded),
        );
        if (task != null) tasks.add(task);
      }

      return tasks;
    } catch (error) {
      debugPrint('Pending publish read failed: $error');
      return const [];
    }
  }

  Future<void> save(PendingPublishTask task) async {
    try {
      await hive.uploadTasksBox.put(task.trendId, jsonEncode(task.toJson()));
    } catch (error) {
      debugPrint('Pending publish save failed: $error');
    }
  }

  Future<void> remove(String trendId) async {
    try {
      await hive.uploadTasksBox.delete(trendId);
    } catch (error) {
      debugPrint('Pending publish delete failed: $error');
    }
  }

  Future<void> clearCache() async {
    try {
      await hive.uploadTasksBox.clear();
    } catch (error) {
      debugPrint('Pending publish clear failed: $error');
    }
  }
}
