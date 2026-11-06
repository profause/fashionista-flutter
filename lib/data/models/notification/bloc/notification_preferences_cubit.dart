import 'package:firebase_auth/firebase_auth.dart';
import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/data/models/notification/bloc/notification_preferences_state.dart';
import 'package:fashionista/data/models/notification/notification_preferences.dart';
import 'package:fashionista/domain/usecases/notification_preferences/load_notification_preferences_usecase.dart';
import 'package:fashionista/domain/usecases/notification_preferences/update_notification_preference_usecase.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Owns the notification preference document for the signed-in user.
///
/// Writes are optimistic: the toggle flips immediately, is persisted with a
/// merge write, and rolls back if Firestore rejects it. Each key carries a
/// sequence number so a slow response for an older tap cannot overwrite a newer
/// value (rapid toggling).
class NotificationPreferencesCubit
    extends Cubit<NotificationPreferencesState> {
  NotificationPreferencesCubit({
    LoadNotificationPreferencesUsecase? loadUsecase,
    UpdateNotificationPreferenceUsecase? updateUsecase,
    String? Function()? userIdProvider,
  }) : _loadUsecase = loadUsecase ?? sl<LoadNotificationPreferencesUsecase>(),
       _updateUsecase =
           updateUsecase ?? sl<UpdateNotificationPreferenceUsecase>(),
       _userIdProvider = userIdProvider ?? _signedInUserId,
       super(const NotificationPreferencesState());

  final LoadNotificationPreferencesUsecase _loadUsecase;
  final UpdateNotificationPreferenceUsecase _updateUsecase;
  final String? Function() _userIdProvider;

  final Map<NotificationPreferenceKey, int> _sequence = {};
  final Set<NotificationPreferenceKey> _inFlight = {};

  static String? _signedInUserId() => FirebaseAuth.instance.currentUser?.uid;

  /// Loads (or reloads) the document. Safe to call every time the sheet opens.
  Future<void> load({bool force = false}) async {
    if (state.isLoading) return;
    if (state.isInitialized && !force) return;

    final userId = _userIdProvider();
    if (userId == null || userId.isEmpty) {
      emit(
        state.copyWith(
          isLoading: false,
          error: 'Sign in to manage notification preferences',
        ),
      );
      return;
    }

    emit(state.copyWith(isLoading: true, clearError: true));

    final result = await _loadUsecase.call(userId);

    result.fold(
      (error) => emit(
        state.copyWith(
          isLoading: false,
          error: error?.toString() ?? 'Unable to load preferences',
        ),
      ),
      (preferences) => emit(
        state.copyWith(
          // A toggle that landed while the read was in flight wins.
          preferences: _mergeInFlight(preferences as NotificationPreferences),
          isLoading: false,
          isInitialized: true,
          clearError: true,
        ),
      ),
    );
  }

  /// Flips a category, persists it, and rolls back when the write fails.
  Future<void> setPreference(NotificationPreferenceKey key, bool value) async {
    final current = state.preferences;
    if (current == null) return;

    final userId = _userIdProvider();
    if (userId == null || userId.isEmpty) {
      emit(state.copyWith(error: 'Sign in to manage notification preferences'));
      return;
    }

    final token = (_sequence[key] ?? 0) + 1;
    _sequence[key] = token;

    emit(
      state.copyWith(
        preferences: current.withValue(key, value),
        saving: {...state.saving, key},
        clearError: true,
      ),
    );

    _inFlight.add(key);
    final result = await _updateUsecase.call(
      UpdateNotificationPreferenceParams(
        userId: userId,
        key: key,
        value: value,
      ),
    );
    _inFlight.remove(key);

    final isStale = _sequence[key] != token;
    final saving = {...state.saving}..remove(key);

    result.fold(
      (error) {
        // Only the newest write may roll back or report, otherwise an older
        // failure would undo a newer successful toggle.
        if (isStale) {
          emit(state.copyWith(saving: saving));
          return;
        }

        emit(
          state.copyWith(
            preferences: state.preferences?.withValue(key, !value),
            saving: saving,
            error: error?.toString() ?? 'Unable to save preference',
          ),
        );
      },
      (_) => emit(state.copyWith(saving: saving, clearError: true)),
    );
  }

  /// Clears an error without touching the loaded values.
  void dismissError() => emit(state.copyWith(clearError: true));

  /// Keeps optimistic edits that landed while the read was in flight.
  NotificationPreferences _mergeInFlight(NotificationPreferences loaded) {
    if (_inFlight.isEmpty) return loaded;

    var merged = loaded;
    for (final key in _inFlight) {
      final optimistic = state.preferences?.isEnabled(key);
      if (optimistic != null) merged = merged.withValue(key, optimistic);
    }
    return merged;
  }
}
