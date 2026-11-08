import 'dart:convert';

import 'package:fashionista/core/service_locator/hive_service.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

/// Keeps Cloudinary `delete_token` values so a freshly uploaded video can be
/// removed from the device without any backend call.
///
/// Cloudinary only honours the token for **10 minutes** after the upload; after
/// that the asset can only be destroyed with the Admin API (the
/// `deleteCloudinaryAsset` callable). Stored in Hive and never in Firestore:
/// the token is a deletion credential.
class HiveVideoDeleteTokenService {
  HiveVideoDeleteTokenService({HiveService? hive, Box<String>? box})
    : _hive = hive,
      _providedBox = box;

  final HiveService? _hive;
  final Box<String>? _providedBox;

  /// Injectable for tests; otherwise the app-wide Hive box.
  Box<String> get _box =>
      _providedBox ?? (_hive ?? HiveService()).videoDeleteTokensBox;

  static const Duration tokenLifetime = Duration(minutes: 10);

  /// Stores the token, pruning anything already expired so the box cannot grow
  /// without bound.
  Future<void> save({required String assetId, required String token}) async {
    if (assetId.isEmpty || token.isEmpty) return;

    try {
      await _pruneExpired();
      await _box.put(
        assetId,
        jsonEncode({
          'token': token,
          'uploadedAt': DateTime.now().toUtc().toIso8601String(),
        }),
      );
    } catch (error) {
      debugPrint('Delete token save failed: $error');
    }
  }

  /// The token for [assetId], or `null` when it is missing or already expired.
  Future<String?> tokenFor(String assetId) async {
    try {
      final raw = _box.get(assetId);
      if (raw == null) return null;

      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;

      final token = decoded['token'];
      final uploadedAt = DateTime.tryParse('${decoded['uploadedAt'] ?? ''}');
      if (token is! String || token.isEmpty || uploadedAt == null) return null;

      if (_isExpired(uploadedAt)) {
        await _box.delete(assetId);
        return null;
      }

      return token;
    } catch (error) {
      debugPrint('Delete token read failed: $error');
      return null;
    }
  }

  Future<void> remove(String assetId) async {
    try {
      await _box.delete(assetId);
    } catch (error) {
      debugPrint('Delete token delete failed: $error');
    }
  }

  Future<void> clearCache() async {
    try {
      await _box.clear();
    } catch (error) {
      debugPrint('Delete token clear failed: $error');
    }
  }

  Future<void> _pruneExpired() async {
    final expired = <dynamic>[];

    for (final key in _box.keys) {
      final raw = _box.get(key);
      if (raw == null) continue;

      try {
        final decoded = jsonDecode(raw);
        final uploadedAt = decoded is Map
            ? DateTime.tryParse('${decoded['uploadedAt'] ?? ''}')
            : null;
        if (uploadedAt == null || _isExpired(uploadedAt)) expired.add(key);
      } catch (_) {
        expired.add(key);
      }
    }

    if (expired.isNotEmpty) {
      await _box.deleteAll(expired);
    }
  }

  bool _isExpired(DateTime uploadedAt) =>
      DateTime.now().toUtc().difference(uploadedAt.toUtc()) > tokenLifetime;
}
