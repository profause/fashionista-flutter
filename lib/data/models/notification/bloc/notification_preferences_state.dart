import 'package:equatable/equatable.dart';
import 'package:fashionista/data/models/notification/notification_preferences.dart';

class NotificationPreferencesState extends Equatable {
  final NotificationPreferences? preferences;
  final bool isLoading;

  /// Set once the first successful load has happened.
  final bool isInitialized;

  /// Categories with a write in flight.
  final Set<NotificationPreferenceKey> saving;

  /// Load or save failure, cleared by the next successful action.
  final String? error;

  const NotificationPreferencesState({
    this.preferences,
    this.isLoading = false,
    this.isInitialized = false,
    this.saving = const {},
    this.error,
  });

  bool get hasPreferences => preferences != null;

  bool isEnabled(NotificationPreferenceKey key) =>
      preferences?.isEnabled(key) ?? true;

  bool isSaving(NotificationPreferenceKey key) => saving.contains(key);

  NotificationPreferencesState copyWith({
    NotificationPreferences? preferences,
    bool? isLoading,
    bool? isInitialized,
    Set<NotificationPreferenceKey>? saving,
    String? error,
    bool clearError = false,
  }) {
    return NotificationPreferencesState(
      preferences: preferences ?? this.preferences,
      isLoading: isLoading ?? this.isLoading,
      isInitialized: isInitialized ?? this.isInitialized,
      saving: saving ?? this.saving,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [
    preferences,
    isLoading,
    isInitialized,
    saving,
    error,
  ];
}
