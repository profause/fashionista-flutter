// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) => User(
  fullName: json['full_name'] as String,
  userName: json['user_name'] as String,
  profileImage: json['profile_image'] as String,
  accountType: json['account_type'] as String,
  gender: json['gender'] as String,
  mobileNumber: json['mobile_number'] as String,
  email: json['email'] as String,
  location: json['location'] as String,
  dateOfBirth: json['date_of_birth'] == null
      ? null
      : DateTime.parse(json['date_of_birth'] as String),
  joinedDate: json['joined_date'] == null
      ? null
      : DateTime.parse(json['joined_date'] as String),
  uid: json['uid'] as String?,
);

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
  'full_name': instance.fullName,
  'user_name': instance.userName,
  'profile_image': instance.profileImage,
  'account_type': instance.accountType,
  'gender': instance.gender,
  'mobile_number': instance.mobileNumber,
  'email': instance.email,
  'location': instance.location,
  'date_of_birth': instance.dateOfBirth?.toIso8601String(),
  'joined_date': instance.joinedDate?.toIso8601String(),
  'uid': instance.uid,
};
