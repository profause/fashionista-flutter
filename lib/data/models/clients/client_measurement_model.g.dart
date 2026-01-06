// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'client_measurement_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ClientMeasurementAdapter extends TypeAdapter<ClientMeasurement> {
  @override
  final int typeId = 1;

  @override
  ClientMeasurement read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ClientMeasurement(
      uid: fields[7] as String,
      bodyPart: fields[0] as String,
      measuredValue: fields[1] as double,
      measuringUnit: fields[2] as String,
      updatedDate: fields[3] as DateTime?,
      notes: fields[4] as String?,
      previousValues: (fields[5] as List).cast<double>(),
      tags: fields[6] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ClientMeasurement obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.bodyPart)
      ..writeByte(1)
      ..write(obj.measuredValue)
      ..writeByte(2)
      ..write(obj.measuringUnit)
      ..writeByte(3)
      ..write(obj.updatedDate)
      ..writeByte(4)
      ..write(obj.notes)
      ..writeByte(5)
      ..write(obj.previousValues)
      ..writeByte(6)
      ..write(obj.tags)
      ..writeByte(7)
      ..write(obj.uid);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClientMeasurementAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ClientMeasurement _$ClientMeasurementFromJson(Map<String, dynamic> json) =>
    ClientMeasurement(
      uid: json['uid'] as String,
      bodyPart: json['body_part'] as String,
      measuredValue: (json['measured_value'] as num).toDouble(),
      measuringUnit: json['measuring_unit'] as String,
      updatedDate: json['updated_date'] == null
          ? null
          : DateTime.parse(json['updated_date'] as String),
      notes: json['notes'] as String?,
      previousValues: (json['previous_values'] as List<dynamic>)
          .map((e) => (e as num).toDouble())
          .toList(),
      tags: json['tags'] as String?,
    );

Map<String, dynamic> _$ClientMeasurementToJson(ClientMeasurement instance) =>
    <String, dynamic>{
      'body_part': instance.bodyPart,
      'measured_value': instance.measuredValue,
      'measuring_unit': instance.measuringUnit,
      'updated_date': instance.updatedDate?.toIso8601String(),
      'notes': instance.notes,
      'previous_values': instance.previousValues,
      'tags': instance.tags,
      'uid': instance.uid,
    };
