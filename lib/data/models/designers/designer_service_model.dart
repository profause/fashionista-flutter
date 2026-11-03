import 'package:equatable/equatable.dart';
import 'package:fashionista/data/models/featured_media/featured_media_model.dart';
import 'package:json_annotation/json_annotation.dart';

part 'designer_service_model.g.dart';

/// A service offered by a designer, stored in the `designer_services`
/// Firestore collection.
@JsonSerializable(explicitToJson: true)
class DesignerServiceModel extends Equatable {
  @JsonKey(name: 'uid')
  final String? uid;

  /// The designer who owns/offers this service.
  @JsonKey(name: 'created_by', defaultValue: '')
  final String createdBy;

  /// Name of the service (e.g. "Custom Bridal Gown").
  @JsonKey(name: 'name', defaultValue: '')
  final String name;

  @JsonKey(name: 'description')
  final String? description;

  /// Comma separated list of tags.
  @JsonKey(name: 'tags')
  final String? tags;

  @JsonKey(name: 'price', defaultValue: 0)
  final double price;

  /// Images for the service. The first one is used as the card cover.
  @JsonKey(name: 'featured_images', defaultValue: [])
  final List<FeaturedMediaModel> featuredImages;

  @JsonKey(name: 'created_at')
  final int? createdAt;

  @JsonKey(name: 'updated_at')
  final int? updatedAt;

  const DesignerServiceModel({
    this.uid,
    this.createdBy = '',
    this.name = '',
    this.description,
    this.tags,
    this.price = 0,
    this.featuredImages = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory DesignerServiceModel.fromJson(Map<String, dynamic> json) =>
      _$DesignerServiceModelFromJson(json);

  Map<String, dynamic> toJson() => _$DesignerServiceModelToJson(this);

  factory DesignerServiceModel.empty() {
    final now = DateTime.now().millisecondsSinceEpoch;
    return DesignerServiceModel(createdAt: now, updatedAt: now);
  }

  DesignerServiceModel copyWith({
    String? uid,
    String? createdBy,
    String? name,
    String? description,
    String? tags,
    double? price,
    List<FeaturedMediaModel>? featuredImages,
    int? createdAt,
    int? updatedAt,
  }) {
    return DesignerServiceModel(
      uid: uid ?? this.uid,
      createdBy: createdBy ?? this.createdBy,
      name: name ?? this.name,
      description: description ?? this.description,
      tags: tags ?? this.tags,
      price: price ?? this.price,
      featuredImages: featuredImages ?? this.featuredImages,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// The cover image used on the service card, if any.
  FeaturedMediaModel? get coverImage =>
      featuredImages.isEmpty ? null : featuredImages.first;

  /// The tags split into a clean list.
  List<String> get tagList => (tags ?? '')
      .split(',')
      .map((tag) => tag.trim())
      .where((tag) => tag.isNotEmpty)
      .toList();

  @override
  List<Object?> get props => [
    uid,
    createdBy,
    name,
    description,
    tags,
    price,
    featuredImages,
    createdAt,
    updatedAt,
  ];
}
