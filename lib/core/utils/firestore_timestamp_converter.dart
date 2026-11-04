import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

/// Normalises the several time representations that exist in this project.
///
/// Firestore returns [Timestamp] for `*_at` fields, but older collections in
/// this app store epoch integers. Both are accepted on read; writes always
/// produce a Firestore [Timestamp].
class FirestoreTimestampConverter
    implements JsonConverter<DateTime?, Object?> {
  const FirestoreTimestampConverter();

  @override
  DateTime? fromJson(Object? json) {
    if (json == null) return null;

    // Always normalise to UTC: booking instants are compared and ordered across
    // designers and clients in different timezones.
    if (json is Timestamp) return json.toDate().toUtc();
    if (json is DateTime) return json.toUtc();
    if (json is int) {
      // Values below ~1973 in milliseconds are far more likely to be seconds.
      final millis = json < 100000000000 ? json * 1000 : json;
      return DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true);
    }
    if (json is num) return fromJson(json.toInt());
    if (json is String) return DateTime.tryParse(json)?.toUtc();
    return null;
  }

  @override
  Object? toJson(DateTime? object) {
    if (object == null) return null;
    return Timestamp.fromDate(object.isUtc ? object : object.toUtc());
  }
}
