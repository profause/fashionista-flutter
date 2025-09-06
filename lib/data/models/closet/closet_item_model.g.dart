// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'closet_item_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ClosetItemModelAdapter extends TypeAdapter<ClosetItemModel> {
  @override
  final int typeId = 10;

  @override
  ClosetItemModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ClosetItemModel(
      uid: fields[0] as String?,
      createdBy: fields[1] as String,
      description: fields[2] as String,
      brand: fields[3] as String?,
      category: fields[4] as String,
      colors: (fields[5] as List?)?.cast<int>(),
      featureMedia: (fields[6] as List).cast<FeaturedMediaModel>(),
      createdAt: fields[7] as int?,
      updatedAt: fields[8] as int?,
      isFavourite: fields[9] as bool?,
    );
  }

  @override
  void write(BinaryWriter writer, ClosetItemModel obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.uid)
      ..writeByte(1)
      ..write(obj.createdBy)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.brand)
      ..writeByte(4)
      ..write(obj.category)
      ..writeByte(5)
      ..write(obj.colors)
      ..writeByte(6)
      ..write(obj.featureMedia)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.updatedAt)
      ..writeByte(9)
      ..write(obj.isFavourite);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClosetItemModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ClosetItemModel _$ClosetItemModelFromJson(Map<String, dynamic> json) =>
    ClosetItemModel(
      uid: json['uid'] as String?,
      createdBy: json['created_by'] as String,
      description: json['description'] as String,
      brand: json['brand'] as String?,
      category: json['category'] as String,
      colors: (json['colors'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList(),
      featureMedia: (json['feature_media'] as List<dynamic>)
          .map((e) => FeaturedMediaModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: (json['created_at'] as num?)?.toInt(),
      updatedAt: (json['updated_at'] as num?)?.toInt(),
      isFavourite: json['is_favourite'] as bool?,
    );

Map<String, dynamic> _$ClosetItemModelToJson(ClosetItemModel instance) =>
    <String, dynamic>{
      'uid': instance.uid,
      'created_by': instance.createdBy,
      'description': instance.description,
      'brand': instance.brand,
      'category': instance.category,
      'colors': instance.colors,
      'feature_media': instance.featureMedia.map((e) => e.toJson()).toList(),
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
      'is_favourite': instance.isFavourite,
    };
