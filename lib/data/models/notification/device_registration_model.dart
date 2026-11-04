import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:fashionista/core/utils/firestore_timestamp_converter.dart';
import 'package:json_annotation/json_annotation.dart';

part 'device_registration_model.g.dart';

/// One push-enabled device belonging to a user.
///
/// Stored at `users/{userId}/devices/{deviceId}`. The document id is a stable
/// UUID persisted on the device, so a token refresh updates the same document
/// instead of piling up registrations.
@JsonSerializable(explicitToJson: true)
class DeviceRegistration extends Equatable {
  @JsonKey(name: 'fcm_token')
  final String fcmToken;

  /// `android` or `ios`.
  final String platform;

  @JsonKey(name: 'device_name')
  final String? deviceName;

  @JsonKey(name: 'app_version')
  final String? appVersion;

  @JsonKey(name: 'is_active', defaultValue: true)
  final bool isActive;

  @FirestoreTimestampConverter()
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;

  @FirestoreTimestampConverter()
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  @FirestoreTimestampConverter()
  @JsonKey(name: 'last_seen_at')
  final DateTime? lastSeenAt;

  const DeviceRegistration({
    required this.fcmToken,
    required this.platform,
    this.deviceName,
    this.appVersion,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
    this.lastSeenAt,
  });

  factory DeviceRegistration.fromJson(Map<String, dynamic> json) =>
      _$DeviceRegistrationFromJson(json);

  Map<String, dynamic> toJson() => _$DeviceRegistrationToJson(this);

  DeviceRegistration copyWith({
    String? fcmToken,
    String? platform,
    String? deviceName,
    String? appVersion,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastSeenAt,
  }) {
    return DeviceRegistration(
      fcmToken: fcmToken ?? this.fcmToken,
      platform: platform ?? this.platform,
      deviceName: deviceName ?? this.deviceName,
      appVersion: appVersion ?? this.appVersion,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
    );
  }

  /// Firestore payload for this device, with server-side timestamps.
  Map<String, dynamic> toFirestore() {
    final now = Timestamp.fromDate(DateTime.now().toUtc());
    return {
      ...toJson(),
      'updated_at': now,
      'last_seen_at': now,
    };
  }

  @override
  List<Object?> get props => [
    fcmToken,
    platform,
    deviceName,
    appVersion,
    isActive,
    createdAt,
    updatedAt,
    lastSeenAt,
  ];
}
