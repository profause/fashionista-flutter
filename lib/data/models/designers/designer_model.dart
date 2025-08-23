import 'package:equatable/equatable.dart';
import 'package:fashionista/data/models/designers/social_handle_model.dart';
import 'package:json_annotation/json_annotation.dart';

part 'designer_model.g.dart';

@JsonSerializable(explicitToJson: true)
class Designer extends Equatable {
  final String uid;
  final String name;
  final String location;
  final String? bio;
  @JsonKey(name: 'profile_image')
  final String? profileImage;

  @JsonKey(name: 'mobile_number')
  final String mobileNumber;

  @JsonKey(name: 'featured_images')
  final List<String>? featuredImages;
  final String tags;

  @JsonKey(name: 'business_name')
  final String businessName;

  @JsonKey(name: 'social_handles')
  final List<SocialHandle>? socialHandles;
  final double? ratings;

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
    this.ratings = 0.0,
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
    double? ratings,
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
    );
  }

  factory Designer.empty() {
    return const Designer(
      uid: '',
      name: '',
      location: '',
      bio: '',
      mobileNumber: '',
      profileImage: '',
      featuredImages: [],
      tags: '',
      businessName: '',
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
  ];
}
