import 'package:dartz/dartz.dart';
import 'package:fashionista/data/models/notification/notification_preferences.dart';

abstract class NotificationPreferencesRepository {
  /// Preferences for [userId]; defaults when the document does not exist.
  Future<Either<String, NotificationPreferences>> fetchPreferences(
    String userId,
  );

  /// Persists a single category with a merge write.
  Future<Either<String, void>> updatePreference({
    required String userId,
    required NotificationPreferenceKey key,
    required bool value,
  });
}
