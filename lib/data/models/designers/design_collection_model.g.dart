// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'design_collection_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DesignCollectionModelAdapter extends TypeAdapter<DesignCollectionModel> {
  @override
  final int typeId = 3;

  @override
  DesignCollectionModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DesignCollectionModel(
      uid: fields[0] as String?,
      createdBy: fields[6] as String,
      title: fields[1] as String,
      description: fields[2] as String?,
      tags: fields[8] as String?,
      visibility: fields[3] as String?,
      featuredImages: (fields[9] as List).cast<String>(),
      author: fields[10] as AuthorModel,
      createdAt: fields[4] as int?,
      updatedAt: fields[5] as int?,
      credits: fields[11] as String?,
      isBookmarked: fields[7] as bool?,
    );
  }

  @override
  void write(BinaryWriter writer, DesignCollectionModel obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.uid)
      ..writeByte(6)
      ..write(obj.createdBy)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(8)
      ..write(obj.tags)
      ..writeByte(3)
      ..write(obj.visibility)
      ..writeByte(9)
      ..write(obj.featuredImages)
      ..writeByte(10)
      ..write(obj.author)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.updatedAt)
      ..writeByte(11)
      ..write(obj.credits)
      ..writeByte(7)
      ..write(obj.isBookmarked);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DesignCollectionModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DesignCollectionModel _$DesignCollectionModelFromJson(
        Map<String, dynamic> json) =>
    DesignCollectionModel(
      uid: json['uid'] as String?,
      createdBy: json['created_by'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      tags: json['tags'] as String?,
      visibility: json['visibility'] as String?,
      featuredImages: (json['featured_images'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      author: AuthorModel.fromJson(json['author'] as Map<String, dynamic>),
      createdAt: (json['created_at'] as num?)?.toInt(),
      updatedAt: (json['updated_at'] as num?)?.toInt(),
      credits: json['credits'] as String?,
    );

Map<String, dynamic> _$DesignCollectionModelToJson(
        DesignCollectionModel instance) =>
    <String, dynamic>{
      'uid': instance.uid,
      'created_by': instance.createdBy,
      'title': instance.title,
      'description': instance.description,
      'tags': instance.tags,
      'visibility': instance.visibility,
      'featured_images': instance.featuredImages,
      'author': instance.author.toJson(),
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
      'credits': instance.credits,
    };
