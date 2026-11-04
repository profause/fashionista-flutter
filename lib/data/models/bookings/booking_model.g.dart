// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'booking_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Booking _$BookingFromJson(Map<String, dynamic> json) => Booking(
      uid: json['uid'] as String?,
      designerId: json['designer_id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      clientId: json['client_id'] as String? ?? '',
      date: json['date'] as String? ?? '',
      dayOfWeek: (json['day_of_week'] as num?)?.toInt() ?? 1,
      startAt: const FirestoreTimestampConverter().fromJson(json['start_at']),
      endAt: const FirestoreTimestampConverter().fromJson(json['end_at']),
      startTime: json['start_time'] as String? ?? '',
      endTime: json['end_time'] as String? ?? '',
      timezone: json['timezone'] as String? ?? '',
      durationMinutes: (json['duration_minutes'] as num?)?.toInt() ?? 0,
      status: $enumDecodeNullable(_$BookingStatusEnumMap, json['status']) ??
          BookingStatus.pending,
      client: json['client'] == null
          ? null
          : BookingClient.fromJson(json['client'] as Map<String, dynamic>),
      notes: json['notes'] as String?,
      createdAt:
          const FirestoreTimestampConverter().fromJson(json['created_at']),
      updatedAt:
          const FirestoreTimestampConverter().fromJson(json['updated_at']),
    );

Map<String, dynamic> _$BookingToJson(Booking instance) => <String, dynamic>{
      'uid': instance.uid,
      'designer_id': instance.designerId,
      'user_id': instance.userId,
      'client_id': instance.clientId,
      'date': instance.date,
      'day_of_week': instance.dayOfWeek,
      'start_at': const FirestoreTimestampConverter().toJson(instance.startAt),
      'end_at': const FirestoreTimestampConverter().toJson(instance.endAt),
      'start_time': instance.startTime,
      'end_time': instance.endTime,
      'timezone': instance.timezone,
      'duration_minutes': instance.durationMinutes,
      'status': _$BookingStatusEnumMap[instance.status]!,
      'client': instance.client?.toJson(),
      'notes': instance.notes,
      'created_at':
          const FirestoreTimestampConverter().toJson(instance.createdAt),
      'updated_at':
          const FirestoreTimestampConverter().toJson(instance.updatedAt),
    };

const _$BookingStatusEnumMap = {
  BookingStatus.pending: 'pending',
  BookingStatus.confirmed: 'confirmed',
  BookingStatus.declined: 'declined',
  BookingStatus.cancelled: 'cancelled',
  BookingStatus.completed: 'completed',
  BookingStatus.noShow: 'no_show',
};
