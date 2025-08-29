// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'client_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ClientAdapter extends TypeAdapter<Client> {
  @override
  final int typeId = 0;

  @override
  Client read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Client(
      uid: fields[0] as String,
      createdBy: fields[1] as String,
      fullName: fields[2] as String,
      mobileNumber: fields[3] as String,
      imageUrl: fields[4] as String?,
      gender: fields[5] as String,
      createdDate: fields[6] as DateTime?,
      measurements: (fields[7] as List).cast<ClientMeasurement>(),
    );
  }

  @override
  void write(BinaryWriter writer, Client obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.uid)
      ..writeByte(1)
      ..write(obj.createdBy)
      ..writeByte(2)
      ..write(obj.fullName)
      ..writeByte(3)
      ..write(obj.mobileNumber)
      ..writeByte(4)
      ..write(obj.imageUrl)
      ..writeByte(5)
      ..write(obj.gender)
      ..writeByte(6)
      ..write(obj.createdDate)
      ..writeByte(7)
      ..write(obj.measurements);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClientAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Client _$ClientFromJson(Map<String, dynamic> json) => Client(
      uid: json['uid'] as String,
      createdBy: json['created_by'] as String,
      fullName: json['full_name'] as String,
      mobileNumber: json['mobile_number'] as String,
      imageUrl: json['image_url'] as String?,
      gender: json['gender'] as String,
      createdDate: json['created_date'] == null
          ? null
          : DateTime.parse(json['created_date'] as String),
      measurements: (json['measurements'] as List<dynamic>)
          .map((e) => ClientMeasurement.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ClientToJson(Client instance) => <String, dynamic>{
      'uid': instance.uid,
      'created_by': instance.createdBy,
      'full_name': instance.fullName,
      'mobile_number': instance.mobileNumber,
      'image_url': instance.imageUrl,
      'gender': instance.gender,
      'created_date': instance.createdDate?.toIso8601String(),
      'measurements': instance.measurements.map((e) => e.toJson()).toList(),
    };
