import 'package:equatable/equatable.dart';
import 'package:fashionista/core/models/hive/comment_model_hive_type.dart';
import 'package:fashionista/data/models/author/author_model.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:fashionista/core/models/hive/hive_type.dart' as hive;
import 'package:hive/hive.dart';

part 'comment_model.g.dart';

@JsonSerializable(explicitToJson: true)
@HiveType(typeId: hive.HiveType.commentType)
class CommentModel extends Equatable {
  @HiveField(CommentModelHiveType.uid)
  final String? uid;

  @JsonKey(name: 'ref_id')
  @HiveField(CommentModelHiveType.refId)
  final String refId;

  @HiveField(CommentModelHiveType.text)
  final String text;

  @JsonKey(name: 'created_at')
  @HiveField(CommentModelHiveType.createdAt)
  final int? createdAt;

  @HiveField(CommentModelHiveType.author)
  final AuthorModel author;

  const CommentModel({
    this.uid,
    required this.refId,
    this.createdAt,
    required this.text,
    required this.author,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) =>
      _$CommentModelFromJson(json);

  Map<String, dynamic> toJson() => _$CommentModelToJson(this);

  @override
  List<Object?> get props => [uid, refId, text, createdAt, author];

  factory CommentModel.empty() {
    return CommentModel(
      text: '',
      refId: '',
      createdAt: DateTime.now().millisecondsSinceEpoch,
      author: AuthorModel.empty(),
    );
  }

  CommentModel copyWith({
    String? uid,
    String? refId,
    String? text,
    AuthorModel? author,
    int? createdAt,
  }) {
    return CommentModel(
      uid: uid ?? this.uid,
      refId: refId ?? this.refId,
      text: text ?? this.text,
      author: author ?? this.author,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
