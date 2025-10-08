import 'package:fashionista/core/models/hive/designer_review_hive_type.dart';
import 'package:fashionista/data/models/comment/comment_model.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:fashionista/core/models/hive/hive_type.dart' as hive;
import 'package:hive/hive.dart';
import 'package:equatable/equatable.dart';

part 'designer_review_model.g.dart';

@JsonSerializable(explicitToJson: true)
@HiveType(typeId: hive.HiveType.designerReviewType)
class DesignerReviewModel extends Equatable {
  @HiveField(DesignerReviewHiveType.uid)
  final String? uid;
  @JsonKey(name: 'created_at')
  @HiveField(DesignerReviewHiveType.createdAt)
  final int? createdAt;

  @HiveField(DesignerReviewHiveType.comment)
  final CommentModel comment;

  @JsonKey(name: 'rating')
  @HiveField(DesignerReviewHiveType.rating)
  final int? rating;

  @JsonKey(name: 'ref_id')
  @HiveField(DesignerReviewHiveType.refId)
  final String refId;

  const DesignerReviewModel({
    this.uid,
    this.createdAt,
    required this.comment,
    this.rating = 0,
    this.refId = '',
  });

  @override
  List<Object?> get props => [uid, createdAt, comment, rating, refId];

  factory DesignerReviewModel.fromJson(Map<String, dynamic> json) =>
      _$DesignerReviewModelFromJson(json);

  Map<String, dynamic> toJson() => _$DesignerReviewModelToJson(this);

  factory DesignerReviewModel.empty() {
    return DesignerReviewModel(
      uid: '',
      createdAt: 0,
      comment: CommentModel.empty(),
      rating: 0,
      refId: '',
    );
  }

  DesignerReviewModel copyWith({
    String? uid,
    int? createdAt,
    CommentModel? comment,
    int? rating,
    String? refId,
  }) {
    return DesignerReviewModel(
      uid: uid ?? this.uid,
      createdAt: createdAt ?? this.createdAt,
      comment: comment ?? this.comment,
      rating: rating ?? this.rating,
      refId: refId ?? this.refId,
    );
  }
}
