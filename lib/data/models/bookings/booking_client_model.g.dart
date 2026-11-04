// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'booking_client_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BookingClient _$BookingClientFromJson(Map<String, dynamic> json) =>
    BookingClient(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      avatar: json['avatar'] as String?,
      mobileNumber: json['mobile_number'] as String? ?? '',
    );

Map<String, dynamic> _$BookingClientToJson(BookingClient instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'avatar': instance.avatar,
      'mobile_number': instance.mobileNumber,
    };
