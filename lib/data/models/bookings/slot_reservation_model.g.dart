// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'slot_reservation_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SlotReservation _$SlotReservationFromJson(Map<String, dynamic> json) =>
    SlotReservation(
      designerId: json['designer_id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      bookingId: json['booking_id'] as String? ?? '',
      startAt: const FirestoreTimestampConverter().fromJson(json['start_at']),
      endAt: const FirestoreTimestampConverter().fromJson(json['end_at']),
      status:
          $enumDecodeNullable(_$SlotReservationStatusEnumMap, json['status']) ??
              SlotReservationStatus.reserved,
      expiresAt:
          const FirestoreTimestampConverter().fromJson(json['expires_at']),
      createdAt:
          const FirestoreTimestampConverter().fromJson(json['created_at']),
    );

Map<String, dynamic> _$SlotReservationToJson(SlotReservation instance) =>
    <String, dynamic>{
      'designer_id': instance.designerId,
      'user_id': instance.userId,
      'booking_id': instance.bookingId,
      'start_at': const FirestoreTimestampConverter().toJson(instance.startAt),
      'end_at': const FirestoreTimestampConverter().toJson(instance.endAt),
      'status': _$SlotReservationStatusEnumMap[instance.status]!,
      'expires_at':
          const FirestoreTimestampConverter().toJson(instance.expiresAt),
      'created_at':
          const FirestoreTimestampConverter().toJson(instance.createdAt),
    };

const _$SlotReservationStatusEnumMap = {
  SlotReservationStatus.reserved: 'reserved',
  SlotReservationStatus.released: 'released',
};
