import 'package:equatable/equatable.dart';
import 'package:fashionista/core/models/hive/featured_media_model_hive_type.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:fashionista/core/models/hive/hive_type.dart' as hive;
import 'package:hive/hive.dart';

part 'featured_media_model.g.dart';

@JsonSerializable(explicitToJson: true)
@HiveType(typeId: hive.HiveType.featuredMediaType)
class FeaturedMediaModel extends Equatable {
  @HiveField(FeaturedMediaModelHiveType.uid)
  final String? uid;

  @HiveField(FeaturedMediaModelHiveType.url)
  final String? url;

  @HiveField(FeaturedMediaModelHiveType.type)
  final String? type;

  @HiveField(FeaturedMediaModelHiveType.aspectRatio)
  @JsonKey(name: 'aspect_ratio')
  final double? aspectRatio;

  @HiveField(FeaturedMediaModelHiveType.thumbnailUrl)
  @JsonKey(name: 'thumbnail_url')
  final String? thumbnailUrl;

  // ---- Video-only metadata (all null for image media) ---------------------

  @HiveField(FeaturedMediaModelHiveType.duration)
  final double? duration;

  @HiveField(FeaturedMediaModelHiveType.width)
  final int? width;

  @HiveField(FeaturedMediaModelHiveType.height)
  final int? height;

  @HiveField(FeaturedMediaModelHiveType.hasAudio)
  @JsonKey(name: 'has_audio')
  final bool? hasAudio;

  @HiveField(FeaturedMediaModelHiveType.format)
  final String? format;

  @HiveField(FeaturedMediaModelHiveType.fileSize)
  @JsonKey(name: 'file_size')
  final int? fileSize;

  const FeaturedMediaModel({
    this.url,
    this.type,
    this.aspectRatio,
    this.thumbnailUrl,
    this.uid,
    this.duration,
    this.width,
    this.height,
    this.hasAudio,
    this.format,
    this.fileSize,
  });

  factory FeaturedMediaModel.fromJson(Map<String, dynamic> json) =>
      _$FeaturedMediaModelFromJson(json);

  Map<String, dynamic> toJson() => _$FeaturedMediaModelToJson(this);

  bool get isVideo => type?.toLowerCase() == 'video';

  @override
  List<Object?> get props => [
    url,
    type,
    aspectRatio,
    thumbnailUrl,
    uid,
    duration,
    width,
    height,
    hasAudio,
    format,
    fileSize,
  ];

  factory FeaturedMediaModel.empty() => const FeaturedMediaModel(
    url: '',
    type: '',
    aspectRatio: 16 / 9,
    thumbnailUrl: '',
    uid: '',
  );

  FeaturedMediaModel copyWith({
    String? url,
    String? type,
    double? aspectRatio,
    String? thumbnailUrl,
    String? uid,
    double? duration,
    int? width,
    int? height,
    bool? hasAudio,
    String? format,
    int? fileSize,
  }) {
    return FeaturedMediaModel(
      url: url ?? this.url,
      type: type ?? this.type,
      aspectRatio: aspectRatio ?? this.aspectRatio,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      uid: uid ?? this.uid,
      duration: duration ?? this.duration,
      width: width ?? this.width,
      height: height ?? this.height,
      hasAudio: hasAudio ?? this.hasAudio,
      format: format ?? this.format,
      fileSize: fileSize ?? this.fileSize,
    );
  }
}
