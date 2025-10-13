// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class NotificationModelAdapter extends TypeAdapter<NotificationModel> {
  @override
  final int typeId = 17;

  @override
  NotificationModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return NotificationModel(
      uid: fields[0] as String?,
      refId: fields[10] as String?,
      refType: fields[9] as String?,
      title: fields[1] as String,
      description: fields[2] as String,
      type: fields[8] as String,
      author: fields[7] as AuthorModel?,
      createdAt: fields[4] as int,
      status: fields[3] as String?,
      to: fields[5] as String,
    );
  }

  @override
  void write(BinaryWriter writer, NotificationModel obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.uid)
      ..writeByte(10)
      ..write(obj.refId)
      ..writeByte(9)
      ..write(obj.refType)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(8)
      ..write(obj.type)
      ..writeByte(7)
      ..write(obj.author)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(3)
      ..write(obj.status)
      ..writeByte(5)
      ..write(obj.to);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NotificationModel _$NotificationModelFromJson(Map<String, dynamic> json) =>
    NotificationModel(
      uid: json['uid'] as String?,
      refId: json['ref_id'] as String?,
      refType: json['ref_type'] as String?,
      title: json['title'] as String,
      description: json['description'] as String,
      type: json['type'] as String,
      author: json['author'] == null
          ? null
          : AuthorModel.fromJson(json['author'] as Map<String, dynamic>),
      createdAt: (json['created_at'] as num?)?.toInt() ?? 0,
      status: json['status'] as String?,
      from: json['from'] as String?,
      to: json['to'] as String,
    );

Map<String, dynamic> _$NotificationModelToJson(NotificationModel instance) =>
    <String, dynamic>{
      'uid': instance.uid,
      'ref_id': instance.refId,
      'ref_type': instance.refType,
      'title': instance.title,
      'description': instance.description,
      'type': instance.type,
      'author': instance.author?.toJson(),
      'created_at': instance.createdAt,
      'status': instance.status,
      'from': instance.from,
      'to': instance.to,
    };
