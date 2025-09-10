// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'outfit_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class OutfitModelAdapter extends TypeAdapter<OutfitModel> {
  @override
  final int typeId = 11;

  @override
  OutfitModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return OutfitModel(
      uid: fields[0] as String?,
      createdBy: fields[6] as String,
      style: fields[5] as String?,
      closetItems: (fields[1] as List).cast<OutfitClosetItem>(),
      occassion: fields[4] as String,
      tags: fields[3] as String?,
      createdAt: fields[7] as int?,
      updatedAt: fields[8] as int?,
      isFavourite: fields[9] as bool?,
      isSelected: fields[10] as bool?,
    );
  }

  @override
  void write(BinaryWriter writer, OutfitModel obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.uid)
      ..writeByte(6)
      ..write(obj.createdBy)
      ..writeByte(5)
      ..write(obj.style)
      ..writeByte(1)
      ..write(obj.closetItems)
      ..writeByte(4)
      ..write(obj.occassion)
      ..writeByte(3)
      ..write(obj.tags)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.updatedAt)
      ..writeByte(9)
      ..write(obj.isFavourite)
      ..writeByte(10)
      ..write(obj.isSelected);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OutfitModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OutfitModel _$OutfitModelFromJson(Map<String, dynamic> json) => OutfitModel(
      uid: json['uid'] as String?,
      createdBy: json['created_by'] as String,
      style: json['style'] as String?,
      closetItems: (json['closet_items'] as List<dynamic>)
          .map((e) => OutfitClosetItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      occassion: json['occassion'] as String,
      tags: json['tags'] as String?,
      createdAt: (json['created_at'] as num?)?.toInt(),
      updatedAt: (json['updated_at'] as num?)?.toInt(),
      isFavourite: json['is_favourite'] as bool?,
    );

Map<String, dynamic> _$OutfitModelToJson(OutfitModel instance) =>
    <String, dynamic>{
      'uid': instance.uid,
      'created_by': instance.createdBy,
      'style': instance.style,
      'closet_items': instance.closetItems.map((e) => e.toJson()).toList(),
      'occassion': instance.occassion,
      'tags': instance.tags,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
      'is_favourite': instance.isFavourite,
    };
