import 'package:equatable/equatable.dart';
import 'package:fashionista/core/models/hive/social_interaction_model_hive_type.dart';
import 'package:fashionista/data/models/author/author_model.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:fashionista/core/models/hive/hive_type.dart' as hive;
import 'package:hive/hive.dart';

part 'social_interaction_model.g.dart';

@JsonSerializable(explicitToJson: true)
@HiveType(typeId: hive.HiveType.socialInteractionModelHiveType)
class SocialInteractionModel extends Equatable {
  @HiveField(SocialInteractionModelHiveType.uid)
  final String? uid;

  @JsonKey(name: 'ref_id')
  @HiveField(SocialInteractionModelHiveType.refId)
  final String refId;

  @JsonKey(name: 'created_at')
  @HiveField(SocialInteractionModelHiveType.createdAt)
  final int? createdAt;

  @HiveField(SocialInteractionModelHiveType.author)
  final AuthorModel author;

  const SocialInteractionModel({
    this.uid,
    required this.refId,
    this.createdAt,
    required this.author,
  });

  factory SocialInteractionModel.fromJson(Map<String, dynamic> json) =>
      _$SocialInteractionModelFromJson(json);

  Map<String, dynamic> toJson() => _$SocialInteractionModelToJson(this);

  @override
  List<Object?> get props => [uid, refId, createdAt, author];

  factory SocialInteractionModel.empty() {
    return SocialInteractionModel(
      uid: '',
      refId: '',
      createdAt: DateTime.now().millisecondsSinceEpoch,
      author: AuthorModel.empty(),
    );
  }

  SocialInteractionModel copyWith({
    String? uid,
    String? refId,
    int? createdAt,
    AuthorModel? author,
  }) {
    return SocialInteractionModel(
      uid: uid ?? this.uid,
      refId: refId ?? this.refId,
      createdAt: createdAt ?? this.createdAt,
      author: author ?? this.author,
    );
  }
}
