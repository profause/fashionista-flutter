// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'designer_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DesignerAdapter extends TypeAdapter<Designer> {
  @override
  final int typeId = 2;

  @override
  Designer read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Designer(
      uid: fields[0] as String,
      name: fields[1] as String,
      location: fields[2] as String,
      bio: fields[3] as String?,
      mobileNumber: fields[4] as String,
      profileImage: fields[5] as String?,
      featuredImages: (fields[6] as List?)?.cast<String>(),
      tags: fields[7] as String,
      businessName: fields[8] as String,
      socialHandles: (fields[9] as List?)?.cast<SocialHandle>(),
      ratings: (fields[10] as Map?)?.cast<String, double>(),
      bannerImage: fields[11] as String?,
      isFavourite: fields[12] as bool?,
      createdDate: fields[13] as DateTime?,
      averageRating: fields[14] as double?,
      reviewCount: fields[15] as int?,
      totalRating: fields[16] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, Designer obj) {
    writer
      ..writeByte(17)
      ..writeByte(0)
      ..write(obj.uid)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.location)
      ..writeByte(3)
      ..write(obj.bio)
      ..writeByte(5)
      ..write(obj.profileImage)
      ..writeByte(11)
      ..write(obj.bannerImage)
      ..writeByte(4)
      ..write(obj.mobileNumber)
      ..writeByte(6)
      ..write(obj.featuredImages)
      ..writeByte(7)
      ..write(obj.tags)
      ..writeByte(8)
      ..write(obj.businessName)
      ..writeByte(9)
      ..write(obj.socialHandles)
      ..writeByte(10)
      ..write(obj.ratings)
      ..writeByte(14)
      ..write(obj.averageRating)
      ..writeByte(16)
      ..write(obj.totalRating)
      ..writeByte(15)
      ..write(obj.reviewCount)
      ..writeByte(12)
      ..write(obj.isFavourite)
      ..writeByte(13)
      ..write(obj.createdDate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DesignerAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

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
      ratings: (json['ratings'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, (e as num).toDouble()),
      ),
      bannerImage: json['banner_image'] as String?,
      createdDate: json['created_date'] == null
          ? null
          : DateTime.parse(json['created_date'] as String),
      averageRating: (json['average_rating'] as num?)?.toDouble(),
      reviewCount: (json['review_count'] as num?)?.toInt(),
      totalRating: (json['total_rating'] as num?)?.toInt(),
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
      'average_rating': instance.averageRating,
      'total_rating': instance.totalRating,
      'review_count': instance.reviewCount,
      'created_date': instance.createdDate?.toIso8601String(),
    };
