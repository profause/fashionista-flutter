import 'dart:convert';

import 'package:fashionista/core/service_locator/hive_service.dart';
import 'package:fashionista/data/models/fashion_interests/fashion_interest_model.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

/// Local snapshot of the fashion interest catalogue.
///
/// The catalogue changes slowly and is display-only, so a one-day snapshot is
/// enough to keep the composer instant and offline-friendly.
class FashionInterestCache {
  FashionInterestCache({Box? box}) : _boxOverride = box;

  /// Test seam; production reads the app's shared Hive box.
  final Box? _boxOverride;

  static const String snapshotKey = 'fashion_interests_snapshot';
  static const String fetchedAtKey = 'fashion_interests_fetched_at';

  static const Duration ttl = Duration(hours: 24);

  Box get _box => _boxOverride ?? HiveService().userInterestsBox;

  /// Cached interests, or `null` when nothing usable is stored.
  List<FashionInterestModel>? read() {
    try {
      final raw = _box.get(snapshotKey);
      if (raw is! String || raw.isEmpty) return null;

      final decoded = jsonDecode(raw);
      if (decoded is! List) return null;

      return [
        for (final item in decoded)
          if (item is Map<String, dynamic>) FashionInterestModel.fromJson(item),
      ];
    } catch (e) {
      debugPrint('⚠️ Fashion interest cache read failed: $e');
      return null;
    }
  }

  /// When the snapshot was written, if it exists.
  DateTime? get fetchedAt {
    try {
      final raw = _box.get(fetchedAtKey);
      if (raw is! int) return null;
      return DateTime.fromMillisecondsSinceEpoch(raw);
    } catch (_) {
      return null;
    }
  }

  bool get isFresh {
    final at = fetchedAt;
    if (at == null) return false;
    return DateTime.now().difference(at) < ttl;
  }

  Future<void> write(List<FashionInterestModel> interests) async {
    try {
      await _box.put(
        snapshotKey,
        jsonEncode([for (final interest in interests) interest.toJson()]),
      );
      await _box.put(fetchedAtKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('⚠️ Fashion interest cache write failed: $e');
    }
  }

  Future<void> clear() async {
    try {
      await _box.delete(snapshotKey);
      await _box.delete(fetchedAtKey);
    } catch (_) {}
  }
}
