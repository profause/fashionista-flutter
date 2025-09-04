import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'settings_model.g.dart';

@JsonSerializable()
class Settings extends Equatable {
  @JsonKey(name: 'display_mode')
  final int? displayMode;

  final bool? autoPlayVideos;

  const Settings({this.displayMode, this.autoPlayVideos});

  /// Empty constructor for initial state
  factory Settings.empty() {
    return const Settings(displayMode: 1, autoPlayVideos: false);
  }

  /// JSON serialization
  factory Settings.fromJson(Map<String, dynamic> json) =>
      _$SettingsFromJson(json);
  Map<String, dynamic> toJson() => _$SettingsToJson(this);

  /// CopyWith method
  Settings copyWith({int? displayMode, bool? autoPlayVideos}) {
    return Settings(
      displayMode: displayMode ?? this.displayMode,
      autoPlayVideos: autoPlayVideos ?? this.autoPlayVideos,
    );
  }

  @override
  List<Object?> get props => [displayMode, autoPlayVideos];
}
