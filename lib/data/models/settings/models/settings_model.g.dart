// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Settings _$SettingsFromJson(Map<String, dynamic> json) => Settings(
      displayMode: (json['display_mode'] as num?)?.toInt(),
      autoPlayVideos: json['autoPlayVideos'] as bool?,
      imageQuality: json['image_quality'] as String?,
    );

Map<String, dynamic> _$SettingsToJson(Settings instance) => <String, dynamic>{
      'display_mode': instance.displayMode,
      'autoPlayVideos': instance.autoPlayVideos,
      'image_quality': instance.imageQuality,
    };
