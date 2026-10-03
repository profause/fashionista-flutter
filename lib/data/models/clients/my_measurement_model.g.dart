// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'my_measurement_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MyMeasurementAdapter extends TypeAdapter<MyMeasurement> {
  @override
  final int typeId = 18;

  @override
  MyMeasurement read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MyMeasurement(
      uid: fields[0] as String,
      designer: fields[1] as Designer,
      measurements: (fields[2] as List).cast<ClientMeasurement>(),
      isDefault: fields[3] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, MyMeasurement obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.uid)
      ..writeByte(1)
      ..write(obj.designer)
      ..writeByte(2)
      ..write(obj.measurements)
      ..writeByte(3)
      ..write(obj.isDefault);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MyMeasurementAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MyMeasurement _$MyMeasurementFromJson(Map<String, dynamic> json) =>
    MyMeasurement(
      uid: json['uid'] as String? ?? '',
      designer: MyMeasurement._designerFromJson(json['designer']),
      measurements: json['measurements'] == null
          ? []
          : MyMeasurement._measurementsFromJson(json['measurements']),
      isDefault: json['is_default'] as bool? ?? false,
    );

Map<String, dynamic> _$MyMeasurementToJson(MyMeasurement instance) =>
    <String, dynamic>{
      'uid': instance.uid,
      'designer': instance.designer.toJson(),
      'measurements': instance.measurements.map((e) => e.toJson()).toList(),
      'is_default': instance.isDefault,
    };
