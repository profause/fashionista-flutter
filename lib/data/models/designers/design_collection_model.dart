import 'package:equatable/equatable.dart';
import 'package:fashionista/data/models/author/author_model.dart';
import 'package:json_annotation/json_annotation.dart';

part 'design_collection_model.g.dart';

@JsonSerializable(explicitToJson: true)
class DesignCollectionModel extends Equatable {
  final String? uid;

  @JsonKey(name: 'created_by')
  final String createdBy;
  final String title;
  final String? description;
  final String? tags;
  final String? visibility;

  @JsonKey(name: 'featured_images')
  final List<String> featuredImages;
  final AuthorModel author;

  @JsonKey(name: 'created_at')
  final int? createdAt;

  @JsonKey(name: 'updated_at')
  final int? updatedAt;
  final String credits;

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
    String? title,
    String? description,
    String? tags,
    String? visibility,
    List<String>? featuredImages,
    AuthorModel? author,
    int? createdAt,
    int? updatedAt,
    String? credits,
  }) {
    return DesignCollectionModel(
      uid: uid,
      createdBy: createdBy,
      title: title ?? this.title,
      description: description ?? this.description,
      tags: tags ?? this.tags,
      visibility: visibility ?? this.visibility,
      featuredImages: featuredImages ?? this.featuredImages,
      author: author ?? this.author,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      credits: credits ?? this.credits,
    );
  }
}
