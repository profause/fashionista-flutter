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
      thumbnailUrl: fields[3] as String?,
      uid: fields[4] as String?,
      duration: fields[5] as double?,
      width: fields[6] as int?,
      height: fields[7] as int?,
      hasAudio: fields[8] as bool?,
      format: fields[9] as String?,
      fileSize: fields[10] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, FeaturedMediaModel obj) {
    writer
      ..writeByte(11)
      ..writeByte(4)
      ..write(obj.uid)
      ..writeByte(0)
      ..write(obj.url)
      ..writeByte(1)
      ..write(obj.type)
      ..writeByte(2)
      ..write(obj.aspectRatio)
      ..writeByte(3)
      ..write(obj.thumbnailUrl)
      ..writeByte(5)
      ..write(obj.duration)
      ..writeByte(6)
      ..write(obj.width)
      ..writeByte(7)
      ..write(obj.height)
      ..writeByte(8)
      ..write(obj.hasAudio)
      ..writeByte(9)
      ..write(obj.format)
      ..writeByte(10)
      ..write(obj.fileSize);
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
      thumbnailUrl: json['thumbnail_url'] as String?,
      uid: json['uid'] as String?,
      duration: (json['duration'] as num?)?.toDouble(),
      width: (json['width'] as num?)?.toInt(),
      height: (json['height'] as num?)?.toInt(),
      hasAudio: json['has_audio'] as bool?,
      format: json['format'] as String?,
      fileSize: (json['file_size'] as num?)?.toInt(),
    );

Map<String, dynamic> _$FeaturedMediaModelToJson(FeaturedMediaModel instance) =>
    <String, dynamic>{
      'uid': instance.uid,
      'url': instance.url,
      'type': instance.type,
      'aspect_ratio': instance.aspectRatio,
      'thumbnail_url': instance.thumbnailUrl,
      'duration': instance.duration,
      'width': instance.width,
      'height': instance.height,
      'has_audio': instance.hasAudio,
      'format': instance.format,
      'file_size': instance.fileSize,
    };
