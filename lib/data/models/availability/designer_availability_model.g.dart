// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'designer_availability_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DesignerAvailability _$DesignerAvailabilityFromJson(
        Map<String, dynamic> json) =>
    DesignerAvailability(
      dayOfWeek: (json['day_of_week'] as num?)?.toInt() ?? 1,
      isAvailable: json['is_available'] as bool? ?? false,
      appointmentDurationMinutes:
          (json['appointment_duration_minutes'] as num?)?.toInt() ?? 30,
      sessions: (json['sessions'] as List<dynamic>?)
              ?.map((e) =>
                  AvailabilitySession.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      updatedAt:
          const FirestoreTimestampConverter().fromJson(json['updated_at']),
    );

Map<String, dynamic> _$DesignerAvailabilityToJson(
        DesignerAvailability instance) =>
    <String, dynamic>{
      'day_of_week': instance.dayOfWeek,
      'is_available': instance.isAvailable,
      'appointment_duration_minutes': instance.appointmentDurationMinutes,
      'sessions': instance.sessions.map((e) => e.toJson()).toList(),
      'updated_at':
          const FirestoreTimestampConverter().toJson(instance.updatedAt),
    };
