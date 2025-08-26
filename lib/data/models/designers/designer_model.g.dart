// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'designer_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Designer _$DesignerFromJson(Map<String, dynamic> json) => Designer(
  uid: json['uid'] as String,
  name: json['name'] as String,
  location: json['location'] as String,
  bio: json['bio'] as String?,
  mobileNumber: json['mobile_number'] as String,
  profileImage: json['profile_image'] as String?,
  featuredImages: (json['featured_images'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  tags: json['tags'] as String,
  businessName: json['business_name'] as String,
  socialHandles: (json['social_handles'] as List<dynamic>?)
      ?.map((e) => SocialHandle.fromJson(e as Map<String, dynamic>))
      .toList(),
  ratings: (json['ratings'] as num?)?.toDouble() ?? 0.0,
  bannerImage: json['banner_image'] as String?,
  createdDate: json['created_date'] == null
      ? null
      : DateTime.parse(json['created_date'] as String),
);

Map<String, dynamic> _$DesignerToJson(Designer instance) => <String, dynamic>{
  'uid': instance.uid,
  'name': instance.name,
  'location': instance.location,
  'bio': instance.bio,
  'profile_image': instance.profileImage,
  'banner_image': instance.bannerImage,
  'mobile_number': instance.mobileNumber,
  'featured_images': instance.featuredImages,
  'tags': instance.tags,
  'business_name': instance.businessName,
  'social_handles': instance.socialHandles?.map((e) => e.toJson()).toList(),
  'ratings': instance.ratings,
  'created_date': instance.createdDate?.toIso8601String(),
};
