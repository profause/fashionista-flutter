import 'package:equatable/equatable.dart';
import 'package:fashionista/core/models/hive/outfit_model_hive_type.dart';
import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

import 'package:fashionista/core/models/hive/hive_type.dart' as hive;

part 'outfit_model.g.dart';

@JsonSerializable(explicitToJson: true)
@HiveType(typeId: hive.HiveType.outfitModelHiveType)
class OutfitModel extends Equatable {
  @HiveField(OutfitModelHiveType.uid)
  final String? uid;

  @HiveField(OutfitModelHiveType.createdBy)
  @JsonKey(name: 'created_by')
  final String createdBy;

  @JsonKey(name: 'style')
  @HiveField(OutfitModelHiveType.style)
  final String? style;

  @JsonKey(name: 'occassion')
  @HiveField(OutfitModelHiveType.occasion)
  final String occassion;

  @JsonKey(name: 'tags')
  @HiveField(OutfitModelHiveType.tags)
  final List<String>? tags;

  @JsonKey(name: 'created_at')
  @HiveField(OutfitModelHiveType.createdAt)
  final int? createdAt;

  @JsonKey(name: 'updated_at')
  @HiveField(OutfitModelHiveType.updatedAt)
  final int? updatedAt;

  @JsonKey(name: 'is_favourite')
  @HiveField(OutfitModelHiveType.isFavourite)
  final bool? isFavourite;

  const OutfitModel({
    this.uid,
    required this.createdBy,
    this.style,
    required this.occassion,
    required this.tags,
    this.createdAt,
    this.updatedAt,
    this.isFavourite,
  });

  factory OutfitModel.fromJson(Map<String, dynamic> json) =>
      _$OutfitModelFromJson(json);

  Map<String, dynamic> toJson() => _$OutfitModelToJson(this);

  @override
  List<Object?> get props => [
    uid,
    createdBy,
    createdBy,
    createdAt,
    updatedAt,
    isFavourite,
  ];

  factory OutfitModel.empty() {
    return const OutfitModel(
      uid: '',
      createdBy: '',
      style: '',
      occassion: '',
      tags: [],
      createdAt: 0,
      updatedAt: 0,
      isFavourite: false,
    );
  }

  OutfitModel copyWith({
    String? uid,
    String? createdBy,
    String? style,
    String? occassion,
    List<String>? tags,
    int? createdAt,
    int? updatedAt,
    bool? isFavourite,
  }) {
    return OutfitModel(
      uid: uid ?? this.uid,
      createdBy: createdBy ?? this.createdBy,
      style: style ?? this.style,
      occassion: occassion ?? this.occassion,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isFavourite: isFavourite ?? this.isFavourite,
    );
  }
}
