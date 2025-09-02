import 'package:equatable/equatable.dart';
import 'package:fashionista/core/models/hive/featured_media_model_hive_type.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:fashionista/core/models/hive/hive_type.dart' as hive;
import 'package:hive/hive.dart';

part 'featured_media_model.g.dart';

@JsonSerializable(explicitToJson: true)
@HiveType(typeId: hive.HiveType.featuredMediaType)
class FeaturedMediaModel extends Equatable {
  @HiveField(FeaturedMediaModelHiveType.url)
  final String? url;

  @HiveField(FeaturedMediaModelHiveType.type)
  final String? type;

  const FeaturedMediaModel({this.url, this.type});

  factory FeaturedMediaModel.fromJson(Map<String, dynamic> json) =>
      _$FeaturedMediaModelFromJson(json);

  Map<String, dynamic> toJson() => _$FeaturedMediaModelToJson(this);

  @override
  List<Object?> get props => [url, type];

  factory FeaturedMediaModel.empty() =>
      const FeaturedMediaModel(url: '', type: '');

  FeaturedMediaModel copyWith({String? url, String? type}) {
    return FeaturedMediaModel(url: url ?? this.url, type: type ?? this.type);
  }
}
