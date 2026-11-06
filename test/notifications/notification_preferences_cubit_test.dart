import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:fashionista/data/models/notification/bloc/notification_preferences_cubit.dart';
import 'package:fashionista/data/models/notification/notification_preferences.dart';
import 'package:fashionista/domain/usecases/notification_preferences/load_notification_preferences_usecase.dart';
import 'package:fashionista/domain/usecases/notification_preferences/update_notification_preference_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeLoadUsecase extends LoadNotificationPreferencesUsecase {
  FakeLoadUsecase(this.result);

  Either<String, NotificationPreferences> result;
  int calls = 0;

  @override
  Future<Either> call(String params) async {
    calls += 1;
    return result;
  }
}

class FakeUpdateUsecase extends UpdateNotificationPreferenceUsecase {
  FakeUpdateUsecase({this.result = const Right(null)});

  Either<String, void> result;
  final List<UpdateNotificationPreferenceParams> calls = [];
  Completer<void>? gate;

  @override
  Future<Either> call(UpdateNotificationPreferenceParams params) async {
    calls.add(params);
    if (gate != null) await gate!.future;
    return result;
  }
}

NotificationPreferencesCubit buildCubit({
  FakeLoadUsecase? load,
  FakeUpdateUsecase? update,
  String? userId = 'user_1',
}) {
  return NotificationPreferencesCubit(
    loadUsecase: load ?? FakeLoadUsecase(Right(NotificationPreferences.defaults())),
    updateUsecase: update ?? FakeUpdateUsecase(),
    userIdProvider: () => userId,
  );
}

void main() {
  group('NotificationPreferencesCubit', () {
    test('loads the document and marks itself initialised', () async {
      final load = FakeLoadUsecase(
        Right(const NotificationPreferences(trendComment: false)),
      );
      final cubit = buildCubit(load: load);

      await cubit.load();

      expect(cubit.state.isInitialized, isTrue);
      expect(cubit.state.isLoading, isFalse);
      expect(cubit.state.error, isNull);
      expect(cubit.state.isEnabled(NotificationPreferenceKey.trendComment), isFalse);
      expect(load.calls, 1);
    });

    test('does not reload once initialised unless forced', () async {
      final load = FakeLoadUsecase(Right(NotificationPreferences.defaults()));
      final cubit = buildCubit(load: load);

      await cubit.load();
      await cubit.load();
      expect(load.calls, 1);

      await cubit.load(force: true);
      expect(load.calls, 2);
    });

    test('surfaces a load error and stays uninitialised', () async {
      final cubit = buildCubit(
        load: FakeLoadUsecase(const Left('permission denied')),
      );

      await cubit.load();

      expect(cubit.state.error, 'permission denied');
      expect(cubit.state.isInitialized, isFalse);
      expect(cubit.state.hasPreferences, isFalse);
    });

    test('reports a missing signed-in user without calling Firestore', () async {
      final load = FakeLoadUsecase(Right(NotificationPreferences.defaults()));
      final cubit = buildCubit(load: load, userId: null);

      await cubit.load();

      expect(load.calls, 0);
      expect(cubit.state.error, contains('Sign in'));
    });

    test('applies the toggle optimistically before the write resolves', () async {
      final update = FakeUpdateUsecase()..gate = Completer<void>();
      final cubit = buildCubit(update: update);
      await cubit.load();

      final pending = cubit.setPreference(
        NotificationPreferenceKey.trendLike,
        false,
      );

      // Write is still in flight, the UI already shows the new value.
      expect(cubit.state.isEnabled(NotificationPreferenceKey.trendLike), isFalse);
      expect(cubit.state.isSaving(NotificationPreferenceKey.trendLike), isTrue);

      update.gate!.complete();
      await pending;

      expect(cubit.state.isSaving(NotificationPreferenceKey.trendLike), isFalse);
      expect(update.calls.single.userId, 'user_1');
    });

    test('rolls back when persistence fails', () async {
      final update = FakeUpdateUsecase(result: const Left('network down'));
      final cubit = buildCubit(update: update);
      await cubit.load();

      await cubit.setPreference(NotificationPreferenceKey.appointments, false);

      expect(cubit.state.isEnabled(NotificationPreferenceKey.appointments), isTrue);
      expect(cubit.state.error, 'network down');
      expect(cubit.state.isSaving(NotificationPreferenceKey.appointments), isFalse);
    });

    test('persists the last value when a key is toggled rapidly', () async {
      final update = FakeUpdateUsecase();
      final firstGate = Completer<void>();
      update.gate = firstGate;
      final cubit = buildCubit(update: update);
      await cubit.load();

      // Two taps: the first write is held, the second resolves immediately.
      final first = cubit.setPreference(
        NotificationPreferenceKey.trendLike,
        false,
      );
      update.gate = null;
      final second = cubit.setPreference(
        NotificationPreferenceKey.trendLike,
        true,
      );

      await second;
      firstGate.complete();
      await first;

      // The newer value wins and the stale response did not overwrite it.
      expect(cubit.state.isEnabled(NotificationPreferenceKey.trendLike), isTrue);
      expect(update.calls.map((call) => call.value), [false, true]);
    });

    test('a stale failure does not roll back a newer value', () async {
      final update = FakeUpdateUsecase();
      final firstGate = Completer<void>();
      update.gate = firstGate;
      final cubit = buildCubit(update: update);
      await cubit.load();

      final first = cubit.setPreference(
        NotificationPreferenceKey.clients,
        false,
      );

      update.result = const Right(null);
      update.gate = null;
      await cubit.setPreference(NotificationPreferenceKey.clients, true);

      // The first write now fails, after the second already succeeded.
      update.result = const Left('too late');
      firstGate.complete();
      await first;

      expect(cubit.state.isEnabled(NotificationPreferenceKey.clients), isTrue);
    });

    test('keeps an in-flight toggle when a reload returns stale data', () async {
      final load = FakeLoadUsecase(Right(NotificationPreferences.defaults()));
      final update = FakeUpdateUsecase()..gate = Completer<void>();
      final cubit = buildCubit(load: load, update: update);
      await cubit.load();

      final pending = cubit.setPreference(
        NotificationPreferenceKey.orderUpdates,
        false,
      );

      // Reload while the write is in flight: the server still says true.
      await cubit.load(force: true);
      expect(cubit.state.isEnabled(NotificationPreferenceKey.orderUpdates), isFalse);

      update.gate!.complete();
      await pending;
    });

    test('clears an error on the next successful toggle', () async {
      final update = FakeUpdateUsecase(result: const Left('nope'));
      final cubit = buildCubit(update: update);
      await cubit.load();

      await cubit.setPreference(NotificationPreferenceKey.clients, false);
      expect(cubit.state.error, 'nope');

      update.result = const Right(null);
      await cubit.setPreference(NotificationPreferenceKey.clients, true);
      expect(cubit.state.error, isNull);
    });

    test('dismissError clears the message without touching values', () async {
      final cubit = buildCubit(load: FakeLoadUsecase(const Left('boom')));
      await cubit.load();

      cubit.dismissError();

      expect(cubit.state.error, isNull);
    });
  });
}
