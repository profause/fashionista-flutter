import 'package:equatable/equatable.dart';
import 'package:fashionista/core/models/hive/closet_item_hive_type.dart';
import 'package:fashionista/data/models/featured_media/featured_media_model.dart';
import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

import 'package:fashionista/core/models/hive/hive_type.dart' as hive;

part 'closet_item_model.g.dart';

@JsonSerializable(explicitToJson: true)
@HiveType(typeId: hive.HiveType.closetItemModelHiveType)
class ClosetItemModel extends Equatable {
  @HiveField(ClosetItemHiveType.uid)
  final String? uid;

  @HiveField(ClosetItemHiveType.createdBy)
  @JsonKey(name: 'created_by')
  final String? createdBy;

  @JsonKey(name: 'description')
  @HiveField(ClosetItemHiveType.description)
  final String description;

  @JsonKey(name: 'brand')
  @HiveField(ClosetItemHiveType.brand)
  final String? brand;

  @JsonKey(name: 'category')
  @HiveField(ClosetItemHiveType.category)
  final String category;

  @JsonKey(name: 'colors')
  @HiveField(ClosetItemHiveType.colors)
  final List<int>? colors;

  @JsonKey(name: 'featured_media')
  @HiveField(ClosetItemHiveType.featuredMedia)
  final List<FeaturedMediaModel> featuredMedia;

  @JsonKey(name: 'created_at')
  @HiveField(ClosetItemHiveType.createdAt)
  final int? createdAt;

  @JsonKey(name: 'updated_at')
  @HiveField(ClosetItemHiveType.updatedAt)
  final int? updatedAt;

  @JsonKey(name: 'is_favourite')
  @HiveField(ClosetItemHiveType.isFavourite)
  final bool? isFavourite;

  @JsonKey(includeFromJson: false, includeToJson: false)
  @HiveField(ClosetItemHiveType.isSelected)
  final bool? isSelected;

  const ClosetItemModel({
    this.uid,
    this.createdBy,
    required this.description,
    this.brand,
    required this.category,
    this.colors,
    required this.featuredMedia,
    this.createdAt,
    this.updatedAt,
    this.isFavourite,
    this.isSelected,
  });

  factory ClosetItemModel.fromJson(Map<String, dynamic> json) =>
      _$ClosetItemModelFromJson(json);

  Map<String, dynamic> toJson() => _$ClosetItemModelToJson(this);

  @override
  List<Object?> get props => [
    uid,
    createdBy,
    description,
    brand,
    createdBy,
    category,
    colors,
    createdAt,
    updatedAt,
    isFavourite,
    featuredMedia,
    isSelected,
  ];

  factory ClosetItemModel.empty() {
    return const ClosetItemModel(
      uid: '',
      description: '',
      category: '',
      featuredMedia: [],
    );
  }

  ClosetItemModel copyWith({
    String? uid,
    String? createdBy,
    String? description,
    String? brand,
    String? category,
    List<int>? colors,
    List<FeaturedMediaModel>? featuredMedia,
    int? createdAt,
    int? updatedAt,
    bool? isFavourite,
    bool? isSelected,
  }) {
    return ClosetItemModel(
      uid: uid ?? this.uid,
      createdBy: createdBy ?? this.createdBy,
      description: description ?? this.description,
      brand: brand ?? this.brand,
      category: category ?? this.category,
      colors: colors ?? this.colors,
      featuredMedia: featuredMedia ?? this.featuredMedia,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isFavourite: isFavourite ?? this.isFavourite,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}
