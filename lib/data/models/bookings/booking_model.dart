import 'package:equatable/equatable.dart';
import 'package:fashionista/core/utils/firestore_timestamp_converter.dart';
import 'package:fashionista/data/models/bookings/booking_client_model.dart';
import 'package:fashionista/data/models/bookings/booking_status.dart';
import 'package:json_annotation/json_annotation.dart';

part 'booking_model.g.dart';

/// A client's appointment request with a specific designer.
///
/// Stored in the top-level `bookings` collection. `clientId` is the
/// designer-scoped client record, while `userId` is the Firebase Auth user.
@JsonSerializable(explicitToJson: true)
class Booking extends Equatable {
  @JsonKey(name: 'uid')
  final String? uid;

  @JsonKey(name: 'designer_id', defaultValue: '')
  final String designerId;

  @JsonKey(name: 'user_id', defaultValue: '')
  final String userId;

  @JsonKey(name: 'client_id', defaultValue: '')
  final String clientId;

  /// Designer-local calendar date (`yyyy-MM-dd`).
  @JsonKey(name: 'date', defaultValue: '')
  final String date;

  /// Denormalised weekday (`1` = Monday .. `7` = Sunday) so schedule-conflict
  /// queries stay index-friendly.
  @JsonKey(name: 'day_of_week', defaultValue: 1)
  final int dayOfWeek;

  @FirestoreTimestampConverter()
  @JsonKey(name: 'start_at')
  final DateTime? startAt;

  @FirestoreTimestampConverter()
  @JsonKey(name: 'end_at')
  final DateTime? endAt;

  @JsonKey(name: 'start_time', defaultValue: '')
  final String startTime;

  @JsonKey(name: 'end_time', defaultValue: '')
  final String endTime;

  /// IANA timezone the wall-clock times were authored in.
  @JsonKey(name: 'timezone', defaultValue: '')
  final String timezone;

  @JsonKey(name: 'duration_minutes', defaultValue: 0)
  final int durationMinutes;

  @JsonKey(name: 'status', defaultValue: BookingStatus.pending)
  final BookingStatus status;

  /// Snapshot of the requesting client, used by the appointment cards.
  @JsonKey(name: 'client')
  final BookingClient? client;

  @JsonKey(name: 'notes')
  final String? notes;

  @FirestoreTimestampConverter()
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;

  @FirestoreTimestampConverter()
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  const Booking({
    this.uid,
    required this.designerId,
    required this.userId,
    this.clientId = '',
    required this.date,
    required this.dayOfWeek,
    this.startAt,
    this.endAt,
    required this.startTime,
    required this.endTime,
    this.timezone = '',
    this.durationMinutes = 0,
    this.status = BookingStatus.pending,
    this.client,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  factory Booking.fromJson(Map<String, dynamic> json) =>
      _$BookingFromJson(json);

  Map<String, dynamic> toJson() => _$BookingToJson(this);

  Booking copyWith({
    String? uid,
    String? designerId,
    String? userId,
    String? clientId,
    String? date,
    int? dayOfWeek,
    DateTime? startAt,
    DateTime? endAt,
    String? startTime,
    String? endTime,
    String? timezone,
    int? durationMinutes,
    BookingStatus? status,
    BookingClient? client,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Booking(
      uid: uid ?? this.uid,
      designerId: designerId ?? this.designerId,
      userId: userId ?? this.userId,
      clientId: clientId ?? this.clientId,
      date: date ?? this.date,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      timezone: timezone ?? this.timezone,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      status: status ?? this.status,
      client: client ?? this.client,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// True when the appointment start is still in the future.
  bool get isFuture => startAt?.isAfter(DateTime.now().toUtc()) ?? false;

  bool get isPast => !isFuture;

  @override
  List<Object?> get props => [
    uid,
    designerId,
    userId,
    clientId,
    date,
    dayOfWeek,
    startAt,
    endAt,
    startTime,
    endTime,
    timezone,
    durationMinutes,
    status,
    client,
    notes,
    createdAt,
    updatedAt,
  ];
}
