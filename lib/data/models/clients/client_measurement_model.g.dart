// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'client_measurement_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ClientMeasurement _$ClientMeasurementFromJson(Map<String, dynamic> json) =>
    ClientMeasurement(
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
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList(),
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
    };
