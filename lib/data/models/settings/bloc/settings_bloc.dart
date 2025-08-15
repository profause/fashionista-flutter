import 'package:fashionista/data/models/settings/models/settings_model.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

abstract class SettingsEvent {
  const SettingsEvent();
}

class LoadSettings extends SettingsEvent {
  final Settings settings;
  const LoadSettings(this.settings);
}

class UpdateSettings extends SettingsEvent {
  final Settings settings;
  const UpdateSettings(this.settings);
}

class ClearSettings extends SettingsEvent {
  const ClearSettings();
}

class SettingsBloc extends HydratedBloc<SettingsEvent, Settings> {
  SettingsBloc() : super(Settings.empty()) {
    on<LoadSettings>((event, emit) => emit(event.settings));
    on<UpdateSettings>((event, emit) => emit(event.settings));
    on<ClearSettings>((event, emit) => emit(Settings.empty()));
  }

  @override
  Settings? fromJson(Map<String, dynamic> json) {
    try {
      return Settings.fromJson(json);
    } catch (_) {
      return Settings.empty();
    }
  }

  @override
  Map<String, dynamic>? toJson(Settings state) {
    try {
      return state.toJson();
    } catch (_) {
      return null;
    }
  }
}