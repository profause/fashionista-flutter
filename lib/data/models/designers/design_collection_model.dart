import 'package:equatable/equatable.dart';
import 'package:fashionista/core/models/hive/design_collection_model_hive_type.dart';
import 'package:fashionista/data/models/author/author_model.dart';
import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:fashionista/core/models/hive/hive_type.dart' as hive;

part 'design_collection_model.g.dart';

@JsonSerializable(explicitToJson: true)
@HiveType(typeId: hive.HiveType.designerCollectionType)
class DesignCollectionModel extends Equatable {
  @HiveField(DesignCollectionModelHiveType.uid)
  final String? uid;

  @HiveField(DesignCollectionModelHiveType.createdBy)
  @JsonKey(name: 'created_by')
  final String createdBy;

    @HiveField(DesignCollectionModelHiveType.title)
  final String title;

    @HiveField(DesignCollectionModelHiveType.description)
  final String? description;

    @HiveField(DesignCollectionModelHiveType.tags)
  final String? tags;

    @HiveField(DesignCollectionModelHiveType.visibility)
  final String? visibility;

  @JsonKey(name: 'featured_images')
    @HiveField(DesignCollectionModelHiveType.featuredImages)
  final List<String> featuredImages;

    @HiveField(DesignCollectionModelHiveType.author)
  final AuthorModel author;

  @JsonKey(name: 'created_at')
    @HiveField(DesignCollectionModelHiveType.createdAt)
  final int? createdAt;

  @JsonKey(name: 'updated_at')
    @HiveField(DesignCollectionModelHiveType.updatedAt)
  final int? updatedAt;

    @HiveField(DesignCollectionModelHiveType.credits)
  final String? credits;

  @JsonKey(includeFromJson: false, includeToJson: false)
  @HiveField(DesignCollectionModelHiveType.isBookmarked)
  final bool? isBookmarked;

  const DesignCollectionModel({
    this.uid,
    required this.createdBy,
    required this.title,
    this.description,
    this.tags,
    this.visibility,
    required this.featuredImages,
    required this.author,
    this.createdAt,
    this.updatedAt,
    required this.credits,
    this.isBookmarked = false,
  });

  factory DesignCollectionModel.fromJson(Map<String, dynamic> json) =>
      _$DesignCollectionModelFromJson(json);

  Map<String, dynamic> toJson() => _$DesignCollectionModelToJson(this);

  @override
  List<Object?> get props => [
    uid,
    createdBy,
    title,
    description,
    tags,
    visibility,
    featuredImages,
    author,
    createdAt,
    updatedAt,
    credits,
    isBookmarked,
  ];

  factory DesignCollectionModel.empty() => DesignCollectionModel(
    createdBy: '',
    title: '',
    description: '',
    tags: '',
    visibility: '',
    featuredImages: [],
    author: AuthorModel.empty(),
    createdAt: DateTime.now().millisecondsSinceEpoch,
    updatedAt: DateTime.now().millisecondsSinceEpoch,
    credits: '',
  );

  DesignCollectionModel copyWith({
    String? uid,
    String? createdBy,
    String? title,
    String? description,
    String? tags,
    String? visibility,
    List<String>? featuredImages,
    AuthorModel? author,
    int? createdAt,
    int? updatedAt,
    String? credits,
    bool? isBookmarked,
  }) {
    return DesignCollectionModel(
      uid: uid ?? this.uid,
      createdBy: createdBy ?? this.createdBy,
      title: title ?? this.title,
      description: description ?? this.description,
      tags: tags ?? this.tags,
      visibility: visibility ?? this.visibility,
      featuredImages: featuredImages ?? this.featuredImages,
      author: author ?? this.author,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      credits: credits ?? this.credits,
      isBookmarked: isBookmarked ?? this.isBookmarked,
    );
  }
}
