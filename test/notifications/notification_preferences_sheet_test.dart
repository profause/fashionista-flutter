import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:fashionista/core/theme/app.theme.dart';
import 'package:fashionista/data/models/notification/bloc/notification_preferences_cubit.dart';
import 'package:fashionista/data/models/notification/notification_preferences.dart';
import 'package:fashionista/domain/usecases/notification_preferences/load_notification_preferences_usecase.dart';
import 'package:fashionista/domain/usecases/notification_preferences/update_notification_preference_usecase.dart';
import 'package:fashionista/presentation/screens/settings/widgets/notification_preferences_sheet.dart';
import 'package:fashionista/presentation/widgets/round_toggle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeLoadUsecase extends LoadNotificationPreferencesUsecase {
  FakeLoadUsecase(this.result);
  final Either<String, NotificationPreferences> result;

  @override
  Future<Either> call(String params) async => result;
}

class GatedLoadUsecase extends LoadNotificationPreferencesUsecase {
  GatedLoadUsecase(this.result);
  final Future<Either> result;

  @override
  Future<Either> call(String params) => result;
}

class FakeUpdateUsecase extends UpdateNotificationPreferenceUsecase {
  final List<UpdateNotificationPreferenceParams> calls = [];

  @override
  Future<Either> call(UpdateNotificationPreferenceParams params) async {
    calls.add(params);
    return const Right(null);
  }
}

Future<NotificationPreferencesCubit> pumpSheet(
  WidgetTester tester, {
  Either<String, NotificationPreferences>? loadResult,
  FakeUpdateUsecase? update,
}) async {
  final cubit = NotificationPreferencesCubit(
    loadUsecase: FakeLoadUsecase(
      loadResult ?? Right(NotificationPreferences.defaults()),
    ),
    updateUsecase: update ?? FakeUpdateUsecase(),
    userIdProvider: () => 'user_1',
  );
  await cubit.load();

  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      theme: fashionistaLightTheme,
      home: BlocProvider<NotificationPreferencesCubit>.value(
        value: cubit,
        child: const Scaffold(body: NotificationPreferencesSheet()),
      ),
    ),
  );
  await tester.pumpAndSettle();

  return cubit;
}

void main() {
  group('NotificationPreferencesSheet', () {
    testWidgets('renders the sections and the visible toggles', (tester) async {
      await pumpSheet(tester);

      expect(find.text('SOCIAL ACTIVITY'), findsOneWidget);
      expect(find.text('APPOINTMENTS'), findsOneWidget);
      expect(find.text('DESIGNER ACTIVITY'), findsOneWidget);
      expect(find.text('FASHION UPDATES'), findsOneWidget);

      expect(find.text('Likes on my trends'), findsOneWidget);
      expect(find.text('Comments on my trends'), findsOneWidget);
      expect(find.text('Appointment updates'), findsOneWidget);
      expect(find.text('Appointment reminders'), findsOneWidget);
      expect(find.text('Ratings and reviews'), findsOneWidget);
      expect(find.text('Added as a client'), findsOneWidget);
      expect(find.text('Order updates'), findsOneWidget);

      expect(find.byType(RoundToggle), findsNWidgets(7));
    });

    testWidgets('hides the categories that have no producer', (tester) async {
      await pumpSheet(tester);

      // Reminders now have a producer, so the row is shown.
      expect(find.text('Appointment reminders'), findsOneWidget);
      expect(find.text('Measurement updates'), findsNothing);
    });

    testWidgets('reflects the stored values', (tester) async {
      await pumpSheet(
        tester,
        loadResult: const Right(
          NotificationPreferences(trendComment: false),
        ),
      );

      final toggles = tester
          .widgetList<RoundToggle>(find.byType(RoundToggle))
          .toList();

      // Order matches the sections: like, comment, appointments, rating,
      // clients, orders.
      expect(toggles[0].value, isTrue);
      expect(toggles[1].value, isFalse);
      expect(toggles[2].value, isTrue);
    });

    testWidgets('toggling flips the value optimistically', (tester) async {
      final update = FakeUpdateUsecase();
      final cubit = await pumpSheet(tester, update: update);

      await tester.tap(find.byType(RoundToggle).first);
      await tester.pumpAndSettle();

      expect(cubit.state.isEnabled(NotificationPreferenceKey.trendLike), isFalse);
      expect(update.calls.single.key, NotificationPreferenceKey.trendLike);
      expect(update.calls.single.value, isFalse);
    });

    testWidgets('shows an error banner with retry when loading fails', (
      tester,
    ) async {
      await pumpSheet(tester, loadResult: const Left('offline'));

      expect(find.text('offline'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('shows a spinner while the first load is running', (
      tester,
    ) async {
      final gate = Completer<Either>();
      final cubit = NotificationPreferencesCubit(
        loadUsecase: GatedLoadUsecase(gate.future),
        updateUsecase: FakeUpdateUsecase(),
        userIdProvider: () => 'user_1',
      );

      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: fashionistaLightTheme,
          home: BlocProvider<NotificationPreferencesCubit>.value(
            value: cubit,
            child: const Scaffold(body: NotificationPreferencesSheet()),
          ),
        ),
      );

      final loading = cubit.load();
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      gate.complete(Right(NotificationPreferences.defaults()));
      await loading;
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Likes on my trends'), findsOneWidget);
    });
  });
}
