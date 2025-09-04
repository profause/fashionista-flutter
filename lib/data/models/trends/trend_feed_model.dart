import 'package:equatable/equatable.dart';
import 'package:fashionista/core/models/hive/trend_feed_model_hive_type.dart';
import 'package:fashionista/data/models/author/author_model.dart';
import 'package:fashionista/data/models/featured_media/featured_media_model.dart';
import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:fashionista/core/models/hive/hive_type.dart' as hive;

part 'trend_feed_model.g.dart';

@JsonSerializable(explicitToJson: true)
@HiveType(typeId: hive.HiveType.trendFeedType)
class TrendFeedModel extends Equatable {
  @HiveField(TrendFeedModelHiveType.uid)
  final String? uid;

  @HiveField(TrendFeedModelHiveType.description)
  final String description;

  @HiveField(TrendFeedModelHiveType.featuredMedia)
  @JsonKey(name: 'featured_media')
  final List<FeaturedMediaModel> featuredMedia;

  @JsonKey(name: 'created_at')
  @HiveField(TrendFeedModelHiveType.createdAt)
  final int? createdAt;

  @JsonKey(name: 'updated_at')
  @HiveField(TrendFeedModelHiveType.updatedAt)
  final int? updatedAt;

  @HiveField(TrendFeedModelHiveType.createdBy)
  @JsonKey(name: 'created_by')
  final String createdBy;

  @JsonKey(includeFromJson: false, includeToJson: false)
  @HiveField(TrendFeedModelHiveType.isLiked)
  final bool? isLiked;

  @JsonKey(includeFromJson: false, includeToJson: false)
  @HiveField(TrendFeedModelHiveType.isFollowed)
  final bool? isFollowed;

  @HiveField(TrendFeedModelHiveType.tags)
  final String? tags;

  @HiveField(TrendFeedModelHiveType.author)
  final AuthorModel author;

  @HiveField(TrendFeedModelHiveType.numberOfLikes)
  @JsonKey(name: 'number_of_likes')
  final int? numberOfLikes;

  @HiveField(TrendFeedModelHiveType.numberOfFollowers)
  @JsonKey(name: 'number_of_followers')
  final int? numberOfFollowers;

  @HiveField(TrendFeedModelHiveType.numberOfComments)
  @JsonKey(name: 'number_of_comments')
  final int? numberOfComments;

  const TrendFeedModel({
    this.uid,
    required this.description,
    required this.featuredMedia,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    this.isLiked = false,
    this.isFollowed = false,
    required this.tags,
    required this.author,
    this.numberOfLikes,
    this.numberOfFollowers,
    this.numberOfComments,
  });

  factory TrendFeedModel.fromJson(Map<String, dynamic> json) =>
      _$TrendFeedModelFromJson(json);

  Map<String, dynamic> toJson() => _$TrendFeedModelToJson(this);

  @override
  List<Object?> get props => [
    uid,
    description,
    featuredMedia,
    createdAt,
    updatedAt,
    createdBy,
    isLiked,
    isFollowed,
    tags,
    author,
    numberOfLikes,
    numberOfFollowers,
    numberOfComments,
  ];

  factory TrendFeedModel.empty() => TrendFeedModel(
    description: '',
    featuredMedia: [],
    createdAt: DateTime.now().millisecondsSinceEpoch,
    updatedAt: DateTime.now().millisecondsSinceEpoch,
    createdBy: '',
    isLiked: false,
    isFollowed: false,
    tags: '',
    author: AuthorModel.empty(),
    numberOfLikes: 0,
    numberOfFollowers: 0,
    numberOfComments: 0,
  );

  TrendFeedModel copyWith({
    String? uid,
    String? description,
    List<FeaturedMediaModel>? featuredMedia,
    int? createdAt,
    int? updatedAt,
    String? createdBy,
    bool? isLiked,
    bool? isFollowed,
    String? tags,
    AuthorModel? author,
    int ? numberOfLikes,
    int ? numberOfFollowers,
    int ? numberOfComments,
  }) {
    return TrendFeedModel(
      uid: uid ?? this.uid,
      description: description ?? this.description,
      featuredMedia: featuredMedia ?? this.featuredMedia,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      isLiked: isLiked ?? this.isLiked,
      isFollowed: isFollowed ?? this.isFollowed,
      tags: tags ?? this.tags,
      author: author ?? this.author,
      numberOfLikes: numberOfLikes ?? this.numberOfLikes,
      numberOfFollowers: numberOfFollowers ?? this.numberOfFollowers,
      numberOfComments: numberOfComments ?? this.numberOfComments,
    );
  }
}
