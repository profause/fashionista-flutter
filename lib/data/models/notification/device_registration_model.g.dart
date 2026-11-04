// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_registration_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeviceRegistration _$DeviceRegistrationFromJson(Map<String, dynamic> json) =>
    DeviceRegistration(
      fcmToken: json['fcm_token'] as String,
      platform: json['platform'] as String,
      deviceName: json['device_name'] as String?,
      appVersion: json['app_version'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt:
          const FirestoreTimestampConverter().fromJson(json['created_at']),
      updatedAt:
          const FirestoreTimestampConverter().fromJson(json['updated_at']),
      lastSeenAt:
          const FirestoreTimestampConverter().fromJson(json['last_seen_at']),
    );

Map<String, dynamic> _$DeviceRegistrationToJson(DeviceRegistration instance) =>
    <String, dynamic>{
      'fcm_token': instance.fcmToken,
      'platform': instance.platform,
      'device_name': instance.deviceName,
      'app_version': instance.appVersion,
      'is_active': instance.isActive,
      'created_at':
          const FirestoreTimestampConverter().toJson(instance.createdAt),
      'updated_at':
          const FirestoreTimestampConverter().toJson(instance.updatedAt),
      'last_seen_at':
          const FirestoreTimestampConverter().toJson(instance.lastSeenAt),
    };
