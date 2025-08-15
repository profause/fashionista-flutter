
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'settings_model.g.dart';

@JsonSerializable()
class Settings extends Equatable {
  @JsonKey(name: 'display_mode')
  final int? displayMode;
  
  const Settings({
    this.displayMode,
  });

  /// Empty constructor for initial state
  factory Settings.empty() {
    return const Settings(
      displayMode: 1
    );
  }

/// JSON serialization
  factory Settings.fromJson(Map<String, dynamic> json) => _$SettingsFromJson(json);
  Map<String, dynamic> toJson() => _$SettingsToJson(this);

  /// CopyWith method
  Settings copyWith({
    int? displayMode,
  }) {
    return Settings(
      displayMode: displayMode ?? this.displayMode
    );
  }

    @override
  List<Object?> get props => [
        displayMode,
      ];
}
