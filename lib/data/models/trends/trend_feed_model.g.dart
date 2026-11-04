// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trend_feed_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TrendFeedModelAdapter extends TypeAdapter<TrendFeedModel> {
  @override
  final int typeId = 6;

  @override
  TrendFeedModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TrendFeedModel(
      uid: fields[0] as String?,
      description: fields[1] as String,
      featuredMedia: (fields[2] as List).cast<FeaturedMediaModel>(),
      createdAt: fields[3] as int?,
      updatedAt: fields[4] as int?,
      createdBy: fields[5] as String,
      isLiked: fields[6] as bool?,
      isFollowed: fields[7] as bool?,
      tags: fields[8] as String?,
      author: fields[9] as AuthorModel,
      numberOfLikes: fields[10] as int?,
      numberOfFollowers: fields[11] as int?,
      numberOfComments: fields[12] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, TrendFeedModel obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.uid)
      ..writeByte(1)
      ..write(obj.description)
      ..writeByte(2)
      ..write(obj.featuredMedia)
      ..writeByte(3)
      ..write(obj.createdAt)
      ..writeByte(4)
      ..write(obj.updatedAt)
      ..writeByte(5)
      ..write(obj.createdBy)
      ..writeByte(6)
      ..write(obj.isLiked)
      ..writeByte(7)
      ..write(obj.isFollowed)
      ..writeByte(8)
      ..write(obj.tags)
      ..writeByte(9)
      ..write(obj.author)
      ..writeByte(10)
      ..write(obj.numberOfLikes)
      ..writeByte(11)
      ..write(obj.numberOfFollowers)
      ..writeByte(12)
      ..write(obj.numberOfComments);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TrendFeedModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TrendFeedModel _$TrendFeedModelFromJson(Map<String, dynamic> json) =>
    TrendFeedModel(
      uid: json['uid'] as String?,
      description: json['description'] as String,
      featuredMedia: (json['featured_media'] as List<dynamic>)
          .map((e) => FeaturedMediaModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: (json['created_at'] as num?)?.toInt(),
      updatedAt: (json['updated_at'] as num?)?.toInt(),
      createdBy: json['created_by'] as String,
      tags: json['tags'] as String?,
      author: AuthorModel.fromJson(json['author'] as Map<String, dynamic>),
      numberOfLikes: (json['number_of_likes'] as num?)?.toInt(),
      numberOfFollowers: (json['number_of_followers'] as num?)?.toInt(),
      numberOfComments: (json['number_of_comments'] as num?)?.toInt(),
    );

Map<String, dynamic> _$TrendFeedModelToJson(TrendFeedModel instance) =>
    <String, dynamic>{
      'uid': instance.uid,
      'description': instance.description,
      'featured_media': instance.featuredMedia.map((e) => e.toJson()).toList(),
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
      'created_by': instance.createdBy,
      'tags': instance.tags,
      'author': instance.author.toJson(),
      'number_of_likes': instance.numberOfLikes,
      'number_of_followers': instance.numberOfFollowers,
      'number_of_comments': instance.numberOfComments,
    };
