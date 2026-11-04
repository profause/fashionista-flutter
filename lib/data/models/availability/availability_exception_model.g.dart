// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'availability_exception_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AvailabilityException _$AvailabilityExceptionFromJson(
        Map<String, dynamic> json) =>
    AvailabilityException(
      date: json['date'] as String? ?? '',
      type: $enumDecodeNullable(
              _$AvailabilityExceptionTypeEnumMap, json['type']) ??
          AvailabilityExceptionType.unavailable,
      sessions: (json['sessions'] as List<dynamic>?)
              ?.map((e) =>
                  AvailabilitySession.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      appointmentDurationMinutes:
          (json['appointment_duration_minutes'] as num?)?.toInt(),
      reason: json['reason'] as String?,
      createdAt:
          const FirestoreTimestampConverter().fromJson(json['created_at']),
      updatedAt:
          const FirestoreTimestampConverter().fromJson(json['updated_at']),
    );

Map<String, dynamic> _$AvailabilityExceptionToJson(
        AvailabilityException instance) =>
    <String, dynamic>{
      'date': instance.date,
      'type': _$AvailabilityExceptionTypeEnumMap[instance.type]!,
      'sessions': instance.sessions.map((e) => e.toJson()).toList(),
      'appointment_duration_minutes': instance.appointmentDurationMinutes,
      'reason': instance.reason,
      'created_at':
          const FirestoreTimestampConverter().toJson(instance.createdAt),
      'updated_at':
          const FirestoreTimestampConverter().toJson(instance.updatedAt),
    };

const _$AvailabilityExceptionTypeEnumMap = {
  AvailabilityExceptionType.unavailable: 'unavailable',
  AvailabilityExceptionType.custom: 'custom',
};
