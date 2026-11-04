// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'designer_service_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DesignerServiceModel _$DesignerServiceModelFromJson(
        Map<String, dynamic> json) =>
    DesignerServiceModel(
      uid: json['uid'] as String?,
      createdBy: json['created_by'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      tags: json['tags'] as String?,
      price: (json['price'] as num?)?.toDouble() ?? 0,
      featuredImages: (json['featured_images'] as List<dynamic>?)
              ?.map(
                  (e) => FeaturedMediaModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: (json['created_at'] as num?)?.toInt(),
      updatedAt: (json['updated_at'] as num?)?.toInt(),
    );

Map<String, dynamic> _$DesignerServiceModelToJson(
        DesignerServiceModel instance) =>
    <String, dynamic>{
      'uid': instance.uid,
      'created_by': instance.createdBy,
      'name': instance.name,
      'description': instance.description,
      'tags': instance.tags,
      'price': instance.price,
      'featured_images':
          instance.featuredImages.map((e) => e.toJson()).toList(),
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
    };
