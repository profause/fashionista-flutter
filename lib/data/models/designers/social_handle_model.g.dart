// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'social_handle_model.dart';

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
