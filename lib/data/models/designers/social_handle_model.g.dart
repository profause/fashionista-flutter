// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'social_handle_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SocialHandleAdapter extends TypeAdapter<SocialHandle> {
  @override
  final int typeId = 5;

  @override
  SocialHandle read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SocialHandle(
      handle: fields[0] as String,
      url: fields[1] as String,
      provider: fields[2] as String,
    );
  }

  @override
  void write(BinaryWriter writer, SocialHandle obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.handle)
      ..writeByte(1)
      ..write(obj.url)
      ..writeByte(2)
      ..write(obj.provider);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SocialHandleAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SocialHandle _$SocialHandleFromJson(Map<String, dynamic> json) => SocialHandle(
      handle: json['handle'] as String,
      url: json['url'] as String,
      provider: json['provider'] as String,
    );

Map<String, dynamic> _$SocialHandleToJson(SocialHandle instance) =>
    <String, dynamic>{
      'handle': instance.handle,
      'url': instance.url,
      'provider': instance.provider,
    };
