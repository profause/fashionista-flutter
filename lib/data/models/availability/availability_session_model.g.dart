// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'availability_session_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AvailabilitySession _$AvailabilitySessionFromJson(Map<String, dynamic> json) =>
    AvailabilitySession(
      startTime: json['start_time'] as String? ?? '',
      endTime: json['end_time'] as String? ?? '',
    );

Map<String, dynamic> _$AvailabilitySessionToJson(
        AvailabilitySession instance) =>
    <String, dynamic>{
      'start_time': instance.startTime,
      'end_time': instance.endTime,
    };
