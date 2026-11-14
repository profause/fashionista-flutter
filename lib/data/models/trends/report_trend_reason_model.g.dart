// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'report_trend_reason_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReportTrendReasonModel _$ReportTrendReasonModelFromJson(
        Map<String, dynamic> json) =>
    ReportTrendReasonModel(
      uid: json['uid'] as String?,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      content: json['content'] as String? ?? '',
      updatedAt: (json['updated_at'] as num?)?.toInt(),
      order: (json['order'] as num?)?.toInt(),
      isActive: json['is_active'] as bool?,
    );

Map<String, dynamic> _$ReportTrendReasonModelToJson(
        ReportTrendReasonModel instance) =>
    <String, dynamic>{
      'uid': instance.uid,
      'title': instance.title,
      'description': instance.description,
      'content': instance.content,
      'updated_at': instance.updatedAt,
      'order': instance.order,
      'is_active': instance.isActive,
    };
