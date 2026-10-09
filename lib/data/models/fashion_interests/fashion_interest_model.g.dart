// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fashion_interest_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FashionInterestModel _$FashionInterestModelFromJson(
        Map<String, dynamic> json) =>
    FashionInterestModel(
      category: json['category'] as String? ?? '',
      name: json['name'] as String? ?? '',
      numberOfPosts: json['number_of_posts'] == null
          ? 0
          : FashionInterestModel._parsePostCount(json['number_of_posts']),
    );

Map<String, dynamic> _$FashionInterestModelToJson(
        FashionInterestModel instance) =>
    <String, dynamic>{
      'category': instance.category,
      'name': instance.name,
      'number_of_posts': instance.numberOfPosts,
    };
