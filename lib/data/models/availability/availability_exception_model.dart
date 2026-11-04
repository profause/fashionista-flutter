import 'package:equatable/equatable.dart';
import 'package:fashionista/core/utils/firestore_timestamp_converter.dart';
import 'package:fashionista/data/models/availability/availability_session_model.dart';
import 'package:json_annotation/json_annotation.dart';

part 'availability_exception_model.g.dart';

/// How a date-specific override changes the recurring weekly schedule.
enum AvailabilityExceptionType {
  /// No appointments can be booked on that date.
  unavailable,

  /// The exception's own sessions replace the weekly sessions for that date.
  custom,
}

/// A one-off override of the weekly schedule for a specific date.
///
/// Stored at `designers/{designerId}/availability_exceptions/{yyyy-MM-dd}`.
@JsonSerializable(explicitToJson: true)
class AvailabilityException extends Equatable {
  /// Designer-local calendar date (`yyyy-MM-dd`), also used as document id.
  @JsonKey(name: 'date', defaultValue: '')
  final String date;

  @JsonKey(name: 'type', defaultValue: AvailabilityExceptionType.unavailable)
  final AvailabilityExceptionType type;

  @JsonKey(name: 'sessions', defaultValue: <AvailabilitySession>[])
  final List<AvailabilitySession> sessions;

  /// `null` means "inherit the weekday duration".
  @JsonKey(name: 'appointment_duration_minutes')
  final int? appointmentDurationMinutes;

  @JsonKey(name: 'reason')
  final String? reason;

  @FirestoreTimestampConverter()
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;

  @FirestoreTimestampConverter()
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  const AvailabilityException({
    required this.date,
    required this.type,
    this.sessions = const [],
    this.appointmentDurationMinutes,
    this.reason,
    this.createdAt,
    this.updatedAt,
  });

  factory AvailabilityException.fromJson(Map<String, dynamic> json) =>
      _$AvailabilityExceptionFromJson(json);

  Map<String, dynamic> toJson() => _$AvailabilityExceptionToJson(this);

  factory AvailabilityException.unavailable({
    required String date,
    String? reason,
  }) {
    return AvailabilityException(
      date: date,
      type: AvailabilityExceptionType.unavailable,
      reason: reason,
    );
  }

  factory AvailabilityException.custom({
    required String date,
    required List<AvailabilitySession> sessions,
    int? appointmentDurationMinutes,
    String? reason,
  }) {
    return AvailabilityException(
      date: date,
      type: AvailabilityExceptionType.custom,
      sessions: sessions,
      appointmentDurationMinutes: appointmentDurationMinutes,
      reason: reason,
    );
  }

  bool get isUnavailable => type == AvailabilityExceptionType.unavailable;
  bool get isCustom => type == AvailabilityExceptionType.custom;

  AvailabilityException copyWith({
    String? date,
    AvailabilityExceptionType? type,
    List<AvailabilitySession>? sessions,
    int? appointmentDurationMinutes,
    String? reason,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AvailabilityException(
      date: date ?? this.date,
      type: type ?? this.type,
      sessions: sessions ?? this.sessions,
      appointmentDurationMinutes:
          appointmentDurationMinutes ?? this.appointmentDurationMinutes,
      reason: reason ?? this.reason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    date,
    type,
    sessions,
    appointmentDurationMinutes,
    reason,
    createdAt,
    updatedAt,
  ];
}
