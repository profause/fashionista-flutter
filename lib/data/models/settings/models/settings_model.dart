import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'settings_model.g.dart';

@JsonSerializable()
class Settings extends Equatable {
  /// Bumped when a stored default must be re-applied once.
  ///
  /// v2 flipped `autoPlayVideos` from `false` to `true`. HydratedBloc persists
  /// the state it was given, so every install made before v2 has `false`
  /// stored as if the user had chosen it — only a version bump can tell the
  /// two apart (plan §9 T20).
  static const int currentVersion = 2;

  @JsonKey(name: 'display_mode')
  final int? displayMode;

  final bool? autoPlayVideos;

  @JsonKey(name: 'image_quality')
  final String? imageQuality;

  @JsonKey(name: 'settings_version')
  final int? version;

  const Settings({
    this.displayMode,
    this.autoPlayVideos,
    this.imageQuality,
    this.version,
  });

  /// Empty constructor for initial state
  factory Settings.empty() {
    return const Settings(
      displayMode: 1,
      autoPlayVideos: true,
      imageQuality: 'SD',
      version: currentVersion,
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
    int? version,
  }) {
    return Settings(
      displayMode: displayMode ?? this.displayMode,
      autoPlayVideos: autoPlayVideos ?? this.autoPlayVideos,
      imageQuality: imageQuality ?? this.imageQuality,
      version: version ?? this.version,
    );
  }

  /// Applies one-time default changes to a payload restored from disk.
  ///
  /// An unversioned payload still carries the pre-v2 default, so `false` there
  /// means "never chose" rather than "chose off". After this upgrade an
  /// explicit off is preserved by the version stamp.
  Settings migrated() {
    final storedVersion = version ?? 1;
    if (storedVersion >= currentVersion) return this;

    // Pre-v2, `false` was simply the default, so it cannot be distinguished
    // from a choice: the upgrade wins once, then the version stamp protects an
    // explicit off forever after.
    return copyWith(autoPlayVideos: true, version: currentVersion);
  }

  @override
  List<Object?> get props => [
    displayMode,
    autoPlayVideos,
    imageQuality,
    version,
  ];
}
