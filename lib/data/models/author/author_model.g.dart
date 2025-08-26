// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'author_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AuthorModel _$AuthorModelFromJson(Map<String, dynamic> json) => AuthorModel(
  name: json['name'] as String?,
  uid: json['uid'] as String?,
  avatar: json['avatar'] as String?,
);

Map<String, dynamic> _$AuthorModelToJson(AuthorModel instance) =>
    <String, dynamic>{
      'name': instance.name,
      'uid': instance.uid,
      'avatar': instance.avatar,
    };
