import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fashionista/core/service_locator/hive_service.dart';
import 'package:fashionista/data/models/bookings/booking_model.dart';
import 'package:flutter/foundation.dart';

/// Offline snapshot of a booking list, so a screen paints instantly instead of
/// showing a spinner while Firestore answers.
///
/// Stored as JSON text rather than a Hive adapter: `Booking` is a Firestore
/// model and its `toJson` emits `Timestamp` values, which Hive cannot persist.
/// Timestamps are stringified on write and parsed back by
/// `FirestoreTimestampConverter`, so the round trip is exact.
class HiveBookingService {
  final hive = HiveService();

  /// Cache keys are namespaced by who owns the list; a user can be both a
  /// designer and a client, and the two lists are different queries.
  static String designerKey(String designerId) => 'designer_$designerId';

  /// Keys of the cached booking fields that hold timestamps.
  static const List<String> _timestampFields = [
    'start_at',
    'end_at',
    'created_at',
    'updated_at',
  ];

  Future<List<Booking>> getDesignerBookings(String designerId) =>
      _read(designerKey(designerId));

  Future<void> saveDesignerBookings(
    String designerId,
    List<Booking> bookings,
  ) => _write(designerKey(designerId), bookings);

  Future<List<Booking>> _read(String key) async {
    try {
      final raw = hive.bookingsBox.get(key);
      if (raw == null || raw.isEmpty) return const [];

      final decoded = jsonDecode(raw);
      if (decoded is! Map) return const [];

      final rows = decoded['bookings'];
      if (rows is! List) return const [];

      return [
        for (final row in rows)
          if (row is Map) Booking.fromJson(Map<String, dynamic>.from(row)),
      ];
    } catch (error) {
      debugPrint('Booking cache read failed: $error');
      return const [];
    }
  }

  Future<void> _write(String key, List<Booking> bookings) async {
    try {
      // An empty list is still written: a designer whose bookings were all
      // cancelled must not keep seeing the old ones on the next cold start.
      await hive.bookingsBox.put(
        key,
        jsonEncode({
          'saved_at': DateTime.now().toUtc().toIso8601String(),
          'bookings': [for (final booking in bookings) _toCacheMap(booking)],
        }),
      );
    } catch (error) {
      debugPrint('Booking cache write failed: $error');
    }
  }

  Map<String, dynamic> _toCacheMap(Booking booking) {
    final json = Map<String, dynamic>.from(booking.toJson());

    for (final field in _timestampFields) {
      final value = json[field];
      if (value is Timestamp) {
        json[field] = value.toDate().toUtc().toIso8601String();
      } else if (value is DateTime) {
        json[field] = value.toUtc().toIso8601String();
      }
    }

    return json;
  }

  Future<void> clearCache() async {
    try {
      await hive.bookingsBox.clear();
    } catch (error) {
      debugPrint('Booking cache clear failed: $error');
    }
  }
}
