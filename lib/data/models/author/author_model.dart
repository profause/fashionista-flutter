import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'author_model.g.dart';

@JsonSerializable(explicitToJson: true)
class AuthorModel extends Equatable {
  final String? name;
  final String? uid;
  final String? avatar;

  const AuthorModel({this.name, this.uid, this.avatar});

  factory AuthorModel.fromJson(Map<String, dynamic> json) =>
      _$AuthorModelFromJson(json);

  Map<String, dynamic> toJson() => _$AuthorModelToJson(this);

  @override
  List<Object?> get props => [name, uid, avatar];

  factory AuthorModel.empty() =>
      const AuthorModel(name: '', uid: '', avatar: '');

  AuthorModel copyWith({String? name, String? uid, String? avatar}) {
    return AuthorModel(
      name: name ?? this.name,
      uid: uid ?? this.uid,
      avatar: avatar ?? this.avatar,
    );
  }
}
