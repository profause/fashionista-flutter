import 'package:equatable/equatable.dart';
import 'package:fashionista/core/utils/firestore_timestamp_converter.dart';
import 'package:fashionista/data/models/availability/availability_session_model.dart';
import 'package:json_annotation/json_annotation.dart';

part 'designer_availability_model.g.dart';

/// Recurring weekly availability for one weekday.
///
/// Stored at `designers/{designerId}/availability/{dayOfWeek}` where the
/// document id is the numeric weekday (`1` = Monday .. `7` = Sunday).
@JsonSerializable(explicitToJson: true)
class DesignerAvailability extends Equatable {
  static const int defaultDurationMinutes = 30;

  @JsonKey(name: 'day_of_week', defaultValue: 1)
  final int dayOfWeek;

  @JsonKey(name: 'is_available', defaultValue: false)
  final bool isAvailable;

  @JsonKey(
    name: 'appointment_duration_minutes',
    defaultValue: defaultDurationMinutes,
  )
  final int appointmentDurationMinutes;

  @JsonKey(name: 'sessions', defaultValue: <AvailabilitySession>[])
  final List<AvailabilitySession> sessions;

  @FirestoreTimestampConverter()
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  const DesignerAvailability({
    required this.dayOfWeek,
    this.isAvailable = false,
    this.appointmentDurationMinutes = defaultDurationMinutes,
    this.sessions = const [],
    this.updatedAt,
  });

  factory DesignerAvailability.fromJson(Map<String, dynamic> json) =>
      _$DesignerAvailabilityFromJson(json);

  Map<String, dynamic> toJson() => _$DesignerAvailabilityToJson(this);

  factory DesignerAvailability.empty(int dayOfWeek) {
    return DesignerAvailability(dayOfWeek: dayOfWeek);
  }

  /// The seven default (disabled) days, used before anything is loaded.
  static List<DesignerAvailability> emptyWeek() {
    return List.generate(7, (index) => DesignerAvailability.empty(index + 1));
  }

  DesignerAvailability copyWith({
    int? dayOfWeek,
    bool? isAvailable,
    int? appointmentDurationMinutes,
    List<AvailabilitySession>? sessions,
    DateTime? updatedAt,
  }) {
    return DesignerAvailability(
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      isAvailable: isAvailable ?? this.isAvailable,
      appointmentDurationMinutes:
          appointmentDurationMinutes ?? this.appointmentDurationMinutes,
      sessions: sessions ?? this.sessions,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get dayName => dayNameOf(dayOfWeek);

  static String dayNameOf(int dayOfWeek) {
    switch (dayOfWeek) {
      case DateTime.monday:
        return 'Monday';
      case DateTime.tuesday:
        return 'Tuesday';
      case DateTime.wednesday:
        return 'Wednesday';
      case DateTime.thursday:
        return 'Thursday';
      case DateTime.friday:
        return 'Friday';
      case DateTime.saturday:
        return 'Saturday';
      case DateTime.sunday:
        return 'Sunday';
      default:
        return 'Unknown';
    }
  }

  static String shortDayNameOf(int dayOfWeek) {
    final name = dayNameOf(dayOfWeek);
    return name == 'Unknown' ? name : name.substring(0, 3);
  }

  @override
  List<Object?> get props => [
    dayOfWeek,
    isAvailable,
    appointmentDurationMinutes,
    sessions,
    updatedAt,
  ];
}
