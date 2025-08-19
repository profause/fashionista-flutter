import 'package:equatable/equatable.dart';
import 'package:fashionista/data/models/designers/social_handle_model.dart';
import 'package:json_annotation/json_annotation.dart';

part 'designer_model.g.dart';

@JsonSerializable(explicitToJson: true)
class Designer extends Equatable {
  final String uid;
  final String name;
  final String location;

  @JsonKey(name: 'mobile_number')
  final String mobileNumber;
  final List<String>? images;
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
    required this.mobileNumber,
    this.images,
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
    String? mobileNumber,
    List<String>? images,
    String? tags,
    String? businessName,
    List<SocialHandle>? socialHandles,
    double? ratings,
  }) {
    return Designer(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      location: location ?? this.location,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      images: images ?? this.images,
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
      mobileNumber: '',
      tags: '',
      businessName: '',
    );
  }

  @override
  List<Object?> get props => [
    uid,
    name,
    location,
    mobileNumber,
    images,
    tags,
    businessName,
    socialHandles,
    ratings,
  ];
}
