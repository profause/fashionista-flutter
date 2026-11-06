import 'package:dartz/dartz.dart';
import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/core/usecase/usecase.dart';
import 'package:fashionista/data/models/notification/notification_preferences.dart';
import 'package:fashionista/domain/repository/notifications/notification_preferences_repository.dart';

class UpdateNotificationPreferenceParams {
  final String userId;
  final NotificationPreferenceKey key;
  final bool value;

  const UpdateNotificationPreferenceParams({
    required this.userId,
    required this.key,
    required this.value,
  });
}

class UpdateNotificationPreferenceUsecase
    implements Usecase<Either, UpdateNotificationPreferenceParams> {
  @override
  Future<Either> call(UpdateNotificationPreferenceParams params) {
    return sl<NotificationPreferencesRepository>().updatePreference(
      userId: params.userId,
      key: params.key,
      value: params.value,
    );
  }
}
