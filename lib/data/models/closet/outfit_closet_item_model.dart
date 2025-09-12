import 'package:equatable/equatable.dart';
import 'package:fashionista/core/models/hive/outfit_closet_item_hive_type.dart';
import 'package:fashionista/data/models/closet/closet_item_model.dart';
import 'package:fashionista/data/models/featured_media/featured_media_model.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:hive/hive.dart';

import 'package:fashionista/core/models/hive/hive_type.dart' as hive;
part 'outfit_closet_item_model.g.dart';

@JsonSerializable(explicitToJson: true)
@HiveType(typeId: hive.HiveType.outfitClosetItemHiveType)
class OutfitClosetItem extends Equatable {
  @HiveField(OutfitClosetItemHiveType.uid)
  final String uid;

  @HiveField(OutfitClosetItemHiveType.featuredMedia)
  @JsonKey(name: 'featured_media')
  final List<FeaturedMediaModel> featuredMedia;

  @HiveField(OutfitClosetItemHiveType.description)
  final String description;

  @HiveField(OutfitClosetItemHiveType.category)
  final String category;

  @JsonKey(name: 'thumbnail_url')
  @HiveField(OutfitClosetItemHiveType.thumbnailUrl)
  final String? thumbnailUrl;

  const OutfitClosetItem({
    required this.uid,
    required this.featuredMedia,
    required this.description,
    required this.category,
    this.thumbnailUrl,
  });

  /// Factory from ClosetItemModel
  factory OutfitClosetItem.fromClosetItem(ClosetItemModel item) {
    return OutfitClosetItem(
      uid: item.uid ?? '',
      featuredMedia: item.featuredMedia,
      description: item.description,
      category: item.category,
    );
  }

  /// JSON serialization

  factory OutfitClosetItem.fromJson(Map<String, dynamic> json) =>
      _$OutfitClosetItemFromJson(json);

  Map<String, dynamic> toJson() => _$OutfitClosetItemToJson(this);

  @override
  List<Object?> get props => [uid, featuredMedia, description, category, thumbnailUrl];

  //empty
  static OutfitClosetItem empty() {
    return const OutfitClosetItem(
      uid: '',
      featuredMedia: [],
      description: '',
      category: '',
      thumbnailUrl: '',
    );
  }

  //copyWith
  OutfitClosetItem copyWith({
    String? uid,
    List<FeaturedMediaModel>? featuredMedia,
    String? description,
    String? category,
    String? thumbnailUrl
  }) {
    return OutfitClosetItem(
      uid: uid ?? this.uid,
      featuredMedia: featuredMedia ?? this.featuredMedia,
      description: description ?? this.description,
      category: category ?? this.category,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl
    );
  }
}
