import 'package:equatable/equatable.dart';
import 'package:fashionista/core/models/hive/author_model_hive_type.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:fashionista/core/models/hive/hive_type.dart' as hive;
import 'package:hive/hive.dart';

part 'author_model.g.dart';

@JsonSerializable(explicitToJson: true)
@HiveType(typeId: hive.HiveType.authorType)
class AuthorModel extends Equatable {
  @HiveField(AuthorModelHiveType.name)
  final String? name;

  @HiveField(AuthorModelHiveType.mobileNumber)
  final String? mobileNumber;

  @HiveField(AuthorModelHiveType.uid)
  final String? uid;

  @HiveField(AuthorModelHiveType.avatar)
  final String? avatar;

  const AuthorModel({this.name, this.uid, this.avatar, this.mobileNumber});

  factory AuthorModel.fromJson(Map<String, dynamic> json) =>
      _$AuthorModelFromJson(json);

  Map<String, dynamic> toJson() => _$AuthorModelToJson(this);

  @override
  List<Object?> get props => [name, uid, avatar, mobileNumber];

  factory AuthorModel.empty() =>
      const AuthorModel(name: '', uid: '', avatar: '', mobileNumber: '');

  AuthorModel copyWith({
    String? name,
    String? uid,
    String? avatar,
    String? mobileNumber,
  }) {
    return AuthorModel(
      name: name ?? this.name,
      uid: uid ?? this.uid,
      avatar: avatar ?? this.avatar,
      mobileNumber: mobileNumber ?? this.mobileNumber,
    );
  }
}
