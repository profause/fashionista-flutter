import 'package:fashionista/data/models/notification/notification_preferences.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NotificationPreferences', () {
    test('defaults every category to enabled', () {
      final preferences = NotificationPreferences.defaults();

      for (final key in NotificationPreferenceKey.values) {
        expect(preferences.isEnabled(key), isTrue, reason: key.firestoreKey);
      }
    });

    test('exposes only keys with a producer as visible', () {
      final visible = NotificationPreferenceKey.visibleKeys
          .map((key) => key.firestoreKey)
          .toList();

      expect(visible, [
        'trend_like',
        'trend_comment',
        'appointments',
        'appointment_reminder',
        'designer_rating',
        'order_updates',
        'clients',
      ]);
      // The measurement trigger was removed, so that row stays hidden.
      expect(visible, isNot(contains('measurement_updates')));
    });

    test('round-trips through toMap and fromMap', () {
      const original = NotificationPreferences(
        trendLike: false,
        trendComment: true,
        appointments: false,
        clients: false,
      );

      final restored = NotificationPreferences.fromMap(original.toMap());

      expect(restored, original);
    });

    test('serialises every key with its Firestore name', () {
      final map = NotificationPreferences.defaults().toMap();

      expect(map.keys, containsAll([
        'trend_like',
        'trend_comment',
        'appointments',
        'appointment_reminder',
        'designer_rating',
        'order_updates',
        'measurement_updates',
        'clients',
      ]));
      expect(map['trend_like'], isTrue);
    });

    test('defaults when the document does not exist', () {
      expect(
        NotificationPreferences.fromMap(const {}),
        NotificationPreferences.defaults(),
      );
    });

    test('defaults a missing individual field', () {
      final preferences = NotificationPreferences.fromMap({
        'trend_comment': false,
      });

      expect(preferences.trendComment, isFalse);
      expect(preferences.trendLike, isTrue);
      expect(preferences.appointments, isTrue);
    });

    test('reads a legacy key when the new one is absent', () {
      final preferences = NotificationPreferences.fromMap({'social': false});

      expect(preferences.trendLike, isFalse);
      expect(preferences.trendComment, isFalse);
      expect(preferences.designerRating, isFalse);
      expect(preferences.appointments, isTrue);
    });

    test('prefers the new key over the legacy key', () {
      final preferences = NotificationPreferences.fromMap({
        'social': false,
        'trend_like': true,
      });

      expect(preferences.trendLike, isTrue);
      expect(preferences.trendComment, isFalse);
    });

    test('reads the remaining legacy aliases', () {
      final preferences = NotificationPreferences.fromMap({
        'orders': false,
        'measurements': false,
        'reminders': false,
      });

      expect(preferences.orderUpdates, isFalse);
      expect(preferences.measurementUpdates, isFalse);
      expect(preferences.appointmentReminder, isFalse);
    });

    test('preserves unknown fields so a save cannot drop them', () {
      final preferences = NotificationPreferences.fromMap({
        'trend_like': false,
        'future_flag': true,
      });

      expect(preferences.unknown['future_flag'], isTrue);
      expect(preferences.toMap()['future_flag'], isTrue);
      expect(preferences.toMap()['trend_like'], isFalse);
    });

    test('ignores junk values instead of coercing them', () {
      final preferences = NotificationPreferences.fromMap({
        'trend_like': 'false',
        'trend_comment': 0,
        'appointments': null,
      });

      expect(preferences.trendLike, isTrue);
      expect(preferences.trendComment, isTrue);
      expect(preferences.appointments, isTrue);
    });

    test('withValue changes only the requested key', () {
      final preferences = NotificationPreferences.defaults().withValue(
        NotificationPreferenceKey.trendComment,
        false,
      );

      expect(preferences.trendComment, isFalse);
      expect(preferences.trendLike, isTrue);
      expect(preferences.measurementUpdates, isTrue);
    });

    test('different values are not equal', () {
      expect(
        NotificationPreferences.defaults().withValue(
          NotificationPreferenceKey.clients,
          false,
        ),
        isNot(NotificationPreferences.defaults()),
      );
    });

    test('maps Firestore keys back to enum values', () {
      expect(
        NotificationPreferenceKey.fromFirestoreKey('order_updates'),
        NotificationPreferenceKey.orderUpdates,
      );
      expect(NotificationPreferenceKey.fromFirestoreKey('social'), isNull);
    });

    test('groups visible keys by section', () {
      expect(
        NotificationPreferenceSection.social.keys,
        [NotificationPreferenceKey.trendLike, NotificationPreferenceKey.trendComment],
      );
      expect(NotificationPreferenceSection.appointments.keys, [
        NotificationPreferenceKey.appointments,
        NotificationPreferenceKey.appointmentReminder,
      ]);
    });
  });
}
