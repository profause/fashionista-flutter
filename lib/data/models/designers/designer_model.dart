import 'package:equatable/equatable.dart';
import 'package:fashionista/core/models/hive/designer_model_hive_type.dart';
import 'package:fashionista/core/models/hive/hive_type.dart' as hive;
import 'package:fashionista/data/models/designers/social_handle_model.dart';
import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'designer_model.g.dart';

@JsonSerializable(explicitToJson: true)
@HiveType(typeId: hive.HiveType.designerType)
class Designer extends Equatable {
  @HiveField(DesignerModelHiveType.uid)
  final String uid;

  @HiveField(DesignerModelHiveType.name)
  final String name;

  @HiveField(DesignerModelHiveType.location)
  final String location;

  @HiveField(DesignerModelHiveType.bio)
  final String? bio;

  @JsonKey(name: 'profile_image')
  @HiveField(DesignerModelHiveType.profileImage)
  final String? profileImage;

  @JsonKey(name: 'banner_image')
  @HiveField(DesignerModelHiveType.bannerImage)
  final String? bannerImage;

  @JsonKey(name: 'mobile_number')
  @HiveField(DesignerModelHiveType.mobileNumber)
  final String mobileNumber;

  @JsonKey(name: 'featured_images')
  @HiveField(DesignerModelHiveType.featuredImages)
  final List<String>? featuredImages;

  @HiveField(DesignerModelHiveType.tags)
  final String tags;

  @JsonKey(name: 'business_name')
  @HiveField(DesignerModelHiveType.businessName)
  final String businessName;

  @JsonKey(name: 'social_handles')
  @HiveField(DesignerModelHiveType.socialHandles)
  final List<SocialHandle>? socialHandles;

  @HiveField(DesignerModelHiveType.ratings)
  final Map<String, double>? ratings;

  @JsonKey(name: 'average_rating')
  @HiveField(DesignerModelHiveType.averageRating)
  final double? averageRating;

  @JsonKey(name: 'total_rating')
  @HiveField(DesignerModelHiveType.totalRating)
  final int? totalRating;

  @JsonKey(name: 'review_count')
  @HiveField(DesignerModelHiveType.reviewCount)
  final int? reviewCount;

  @JsonKey(includeFromJson: false, includeToJson: false)
  @HiveField(DesignerModelHiveType.isFavourite)
  final bool? isFavourite;

  @JsonKey(name: 'created_date')
  @HiveField(DesignerModelHiveType.createdDate)
  final DateTime? createdDate;

  const Designer({
    required this.uid,
    required this.name,
    required this.location,
    this.bio,
    required this.mobileNumber,
    this.profileImage,
    this.featuredImages,
    required this.tags,
    required this.businessName,
    this.socialHandles,
    this.ratings,
    this.bannerImage,
    this.isFavourite = false,
    this.createdDate,
    this.averageRating,
    this.reviewCount,
    this.totalRating,
  });

  factory Designer.fromJson(Map<String, dynamic> json) =>
      _$DesignerFromJson(json);

  Map<String, dynamic> toJson() => _$DesignerToJson(this);

  Designer copyWith({
    String? uid,
    String? name,
    String? location,
    String? bio,
    String? mobileNumber,
    String? profileImage,
    List<String>? featuredImages,
    String? tags,
    String? businessName,
    List<SocialHandle>? socialHandles,
    Map<String, double>? ratings,
    String? bannerImage,
    bool? isFavourite,
    DateTime? createdDate,
    double? averageRating,
    int? reviewCount,
    int? totalRating,
  }) {
    return Designer(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      location: location ?? this.location,
      bio: bio ?? this.bio,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      profileImage: profileImage ?? this.profileImage,
      featuredImages: featuredImages ?? this.featuredImages,
      tags: tags ?? this.tags,
      businessName: businessName ?? this.businessName,
      socialHandles: socialHandles ?? this.socialHandles,
      ratings: ratings ?? this.ratings,
      bannerImage: bannerImage ?? this.bannerImage,
      isFavourite: isFavourite ?? this.isFavourite,
      createdDate: createdDate ?? this.createdDate,
      averageRating: averageRating ?? this.averageRating,
      reviewCount: reviewCount ?? this.reviewCount,
      totalRating: totalRating ?? this.totalRating,
    );
  }

  factory Designer.empty() {
    return Designer(
      uid: '',
      name: '',
      location: '',
      bio: '',
      mobileNumber: '',
      profileImage: '',
      featuredImages: [],
      tags: '',
      businessName: '',
      socialHandles: [],
      ratings: {'5': 0.0, '4': 0.0, '3': 0.0, '2': 0.0, '1': 0.0},
      bannerImage: '',
      isFavourite: false,
      createdDate: DateTime.now(),
      averageRating: 0.0,
      reviewCount: 0,
      totalRating: 0,
    );
  }

  @override
  List<Object?> get props => [
    uid,
    name,
    location,
    bio,
    mobileNumber,
    profileImage,
    featuredImages,
    tags,
    businessName,
    socialHandles,
    ratings,
    bannerImage,
    isFavourite,
    createdDate,
    averageRating,
    reviewCount,
    totalRating,
  ];
}
