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
    );
  }

  @override
  void write(BinaryWriter writer, FeaturedMediaModel obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.url)
      ..writeByte(1)
      ..write(obj.type);
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
    );

Map<String, dynamic> _$FeaturedMediaModelToJson(FeaturedMediaModel instance) =>
    <String, dynamic>{
      'url': instance.url,
      'type': instance.type,
    };
