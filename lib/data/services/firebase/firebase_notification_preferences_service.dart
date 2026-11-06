import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:fashionista/data/models/notification/notification_preferences.dart';

/// Firestore access for the notification preference document.
abstract class FirebaseNotificationPreferencesService {
  Future<Either<String, NotificationPreferences>> fetchPreferences(
    String userId,
  );

  Future<Either<String, void>> setPreference({
    required String userId,
    required NotificationPreferenceKey key,
    required bool value,
  });
}

class FirebaseNotificationPreferencesServiceImpl
    implements FirebaseNotificationPreferencesService {
  DocumentReference<Map<String, dynamic>> _document(String userId) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('settings')
        .doc('notifications');
  }

  @override
  Future<Either<String, NotificationPreferences>> fetchPreferences(
    String userId,
  ) async {
    if (userId.isEmpty) {
      return const Left('No signed-in user');
    }

    try {
      final snapshot = await _document(userId).get();

      // A user who has never opened this sheet has no document at all; the
      // defaults are the effective settings, so this is not an error.
      if (!snapshot.exists) {
        return Right(NotificationPreferences.defaults());
      }

      return Right(
        NotificationPreferences.fromMap(snapshot.data() ?? const {}),
      );
    } on FirebaseException catch (e) {
      return Left(e.message ?? 'Unable to load notification preferences');
    } catch (e) {
      return Left('Unable to load notification preferences: $e');
    }
  }

  @override
  Future<Either<String, void>> setPreference({
    required String userId,
    required NotificationPreferenceKey key,
    required bool value,
  }) async {
    if (userId.isEmpty) {
      return const Left('No signed-in user');
    }

    try {
      // Merge so one toggle never rewrites the other categories.
      await _document(userId).set({
        key.firestoreKey: value,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return const Right(null);
    } on FirebaseException catch (e) {
      return Left(e.message ?? 'Unable to save notification preference');
    } catch (e) {
      return Left('Unable to save notification preference: $e');
    }
  }
}
