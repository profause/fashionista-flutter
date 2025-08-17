// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'client_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Client _$ClientFromJson(Map<String, dynamic> json) => Client(
  uid: json['uid'] as String,
  createdBy: json['created_by'] as String,
  fullName: json['full_name'] as String,
  mobileNumber: json['mobile_number'] as String,
  imageUrl: json['image_url'] as String?,
  gender: json['gender'] as String,
  createdDate: json['created_date'] == null
      ? null
      : DateTime.parse(json['created_date'] as String),
  measurements: (json['measurements'] as List<dynamic>)
      .map((e) => ClientMeasurement.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$ClientToJson(Client instance) => <String, dynamic>{
  'uid': instance.uid,
  'created_by': instance.createdBy,
  'full_name': instance.fullName,
  'mobile_number': instance.mobileNumber,
  'image_url': instance.imageUrl,
  'gender': instance.gender,
  'created_date': instance.createdDate?.toIso8601String(),
  'measurements': instance.measurements.map((e) => e.toJson()).toList(),
};
