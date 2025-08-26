// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'design_collection_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DesignCollectionModel _$DesignCollectionModelFromJson(
  Map<String, dynamic> json,
) => DesignCollectionModel(
  uid: json['uid'] as String?,
  createdBy: json['created_by'] as String,
  title: json['title'] as String,
  description: json['description'] as String?,
  tags: json['tags'] as String?,
  visibility: json['visibility'] as String?,
  featuredImages: (json['featured_images'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  author: AuthorModel.fromJson(json['author'] as Map<String, dynamic>),
  createdAt: (json['created_at'] as num?)?.toInt(),
  updatedAt: (json['updated_at'] as num?)?.toInt(),
  credits: json['credits'] as String?,
);

Map<String, dynamic> _$DesignCollectionModelToJson(
  DesignCollectionModel instance,
) => <String, dynamic>{
  'uid': instance.uid,
  'created_by': instance.createdBy,
  'title': instance.title,
  'description': instance.description,
  'tags': instance.tags,
  'visibility': instance.visibility,
  'featured_images': instance.featuredImages,
  'author': instance.author.toJson(),
  'created_at': instance.createdAt,
  'updated_at': instance.updatedAt,
  'credits': instance.credits,
};
