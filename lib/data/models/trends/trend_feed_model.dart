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

  /// [TrendAudience.value]: `public` or `draft`.
  ///
  /// Nullable because documents written before audiences existed have no such
  /// field; both Hive and JSON read them back as public.
  @HiveField(TrendFeedModelHiveType.audience)
  @JsonKey(name: 'audience', defaultValue: TrendFeedModel.audiencePublic)
  final String? audience;

  /// Moderation status. A missing value means the trend is visible; the
  /// reporting function sets `reported` once the threshold is reached.
  @HiveField(TrendFeedModelHiveType.status)
  @JsonKey(name: 'status', includeIfNull: false)
  final String? status;

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
    this.audience,
    this.status,
  });

  factory TrendFeedModel.fromJson(Map<String, dynamic> json) =>
      _$TrendFeedModelFromJson(json);

  Map<String, dynamic> toJson() => _$TrendFeedModelToJson(this);

  static const String audiencePublic = 'public';
  static const String audienceDraft = 'draft';
  static const String statusReported = 'reported';

  /// Excluded from the public feed; the author still sees it in their posts.
  bool get isDraft => audience == audienceDraft;

  /// Hidden from every public surface once moderation reports cross the
  /// threshold. Missing status (legacy documents) is visible.
  bool get isReported => status == statusReported;

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
    audience,
    status,
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
    audience: audiencePublic,
    status: null,
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
    int? numberOfLikes,
    int? numberOfFollowers,
    int? numberOfComments,
    String? audience,
    String? status,
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
      audience: audience ?? this.audience,
      status: status ?? this.status,
    );
  }
}
