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
      occassion: fields[4] as String,
      tags: (fields[3] as List?)?.cast<String>(),
      createdAt: fields[7] as int?,
      updatedAt: fields[8] as int?,
      isFavourite: fields[9] as bool?,
    );
  }

  @override
  void write(BinaryWriter writer, OutfitModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.uid)
      ..writeByte(6)
      ..write(obj.createdBy)
      ..writeByte(5)
      ..write(obj.style)
      ..writeByte(4)
      ..write(obj.occassion)
      ..writeByte(3)
      ..write(obj.tags)
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
      occassion: json['occassion'] as String,
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList(),
      createdAt: (json['created_at'] as num?)?.toInt(),
      updatedAt: (json['updated_at'] as num?)?.toInt(),
      isFavourite: json['is_favourite'] as bool?,
    );

Map<String, dynamic> _$OutfitModelToJson(OutfitModel instance) =>
    <String, dynamic>{
      'uid': instance.uid,
      'created_by': instance.createdBy,
      'style': instance.style,
      'occassion': instance.occassion,
      'tags': instance.tags,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
      'is_favourite': instance.isFavourite,
    };
