// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'featured_media_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FeaturedMediaModelAdapter extends TypeAdapter<FeaturedMediaModel> {
  @override
  final int typeId = 7;

  @override
  FeaturedMediaModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FeaturedMediaModel(
      url: fields[0] as String?,
      type: fields[1] as String?,
      aspectRatio: fields[2] as double?,
    );
  }

  @override
  void write(BinaryWriter writer, FeaturedMediaModel obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.url)
      ..writeByte(1)
      ..write(obj.type)
      ..writeByte(2)
      ..write(obj.aspectRatio);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FeaturedMediaModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FeaturedMediaModel _$FeaturedMediaModelFromJson(Map<String, dynamic> json) =>
    FeaturedMediaModel(
      url: json['url'] as String?,
      type: json['type'] as String?,
      aspectRatio: (json['aspect_ratio'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$FeaturedMediaModelToJson(FeaturedMediaModel instance) =>
    <String, dynamic>{
      'url': instance.url,
      'type': instance.type,
      'aspect_ratio': instance.aspectRatio,
    };
