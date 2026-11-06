import 'package:dartz/dartz.dart';
import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/data/models/notification/notification_preferences.dart';
import 'package:fashionista/data/services/firebase/firebase_notification_preferences_service.dart';
import 'package:fashionista/domain/repository/notifications/notification_preferences_repository.dart';

class NotificationPreferencesRepositoryImpl
    implements NotificationPreferencesRepository {
  @override
  Future<Either<String, NotificationPreferences>> fetchPreferences(
    String userId,
  ) {
    return sl<FirebaseNotificationPreferencesService>().fetchPreferences(userId);
  }

  @override
  Future<Either<String, void>> updatePreference({
    required String userId,
    required NotificationPreferenceKey key,
    required bool value,
  }) {
    return sl<FirebaseNotificationPreferencesService>().setPreference(
      userId: userId,
      key: key,
      value: value,
    );
  }
}
