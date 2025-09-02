// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'social_interaction_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SocialInteractionModelAdapter
    extends TypeAdapter<SocialInteractionModel> {
  @override
  final int typeId = 9;

  @override
  SocialInteractionModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SocialInteractionModel(
      uid: fields[0] as String?,
      refId: fields[3] as String,
      createdAt: fields[1] as int?,
      author: fields[2] as AuthorModel,
    );
  }

  @override
  void write(BinaryWriter writer, SocialInteractionModel obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.uid)
      ..writeByte(3)
      ..write(obj.refId)
      ..writeByte(1)
      ..write(obj.createdAt)
      ..writeByte(2)
      ..write(obj.author);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SocialInteractionModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SocialInteractionModel _$SocialInteractionModelFromJson(
        Map<String, dynamic> json) =>
    SocialInteractionModel(
      uid: json['uid'] as String?,
      refId: json['ref_id'] as String,
      createdAt: (json['created_at'] as num?)?.toInt(),
      author: AuthorModel.fromJson(json['author'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$SocialInteractionModelToJson(
        SocialInteractionModel instance) =>
    <String, dynamic>{
      'uid': instance.uid,
      'ref_id': instance.refId,
      'created_at': instance.createdAt,
      'author': instance.author.toJson(),
    };
