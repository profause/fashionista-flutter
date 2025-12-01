import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'settings_model.g.dart';

@JsonSerializable()
class Settings extends Equatable {
  @JsonKey(name: 'display_mode')
  final int? displayMode;

  final bool? autoPlayVideos;

  @JsonKey(name: 'image_quality')
  final String? imageQuality;

  const Settings({this.displayMode, this.autoPlayVideos, this.imageQuality});

  /// Empty constructor for initial state
  factory Settings.empty() {
    return const Settings(
      displayMode: 1,
      autoPlayVideos: false,
      imageQuality: 'SD',
    );
  }

  /// JSON serialization
  factory Settings.fromJson(Map<String, dynamic> json) =>
      _$SettingsFromJson(json);
  Map<String, dynamic> toJson() => _$SettingsToJson(this);

  /// CopyWith method
  Settings copyWith({
    int? displayMode,
    bool? autoPlayVideos,
    String? imageQuality,
  }) {
    return Settings(
      displayMode: displayMode ?? this.displayMode,
      autoPlayVideos: autoPlayVideos ?? this.autoPlayVideos,
      imageQuality: imageQuality ?? this.imageQuality,
    );
  }

  @override
  List<Object?> get props => [displayMode, autoPlayVideos, imageQuality];
}
