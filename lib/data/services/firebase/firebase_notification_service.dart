import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:fashionista/data/models/notification/notification_model.dart';

abstract class FirebaseNotificationService {
  Future<Either> createNotification(NotificationModel notification);
  Future<Either> updateNotification(NotificationModel notification);
  Future<Either> deleteNotification(String notificationId);
  Future<Either<String, NotificationModel>> findNotificationById(
    String notificationId,
  );
  Future<Either> fetchNotificationsFromFirestore(String uid);
  Future<Either<String, List<NotificationModel>>>
  findNotificationsFromFirestore(String uid);
  Future<Either<String, int>> getCount(String uid);
}

class FirebaseNotificationServiceImpl implements FirebaseNotificationService {
  @override
  Future<Either> createNotification(NotificationModel notification) async {
    try {
      final firestore = FirebaseFirestore.instance;
      firestore
          .collection('notifications')
          .doc(notification.uid)
          .set(notification.toJson(), SetOptions(merge: true));
      return Right(notification);
    } on FirebaseException catch (e) {
      return Left(e.message);
    }
  }

  @override
  Future<Either> deleteNotification(String notificationId) async {
    try {
      final firestore = FirebaseFirestore.instance;
      // Delete the document with the given uid
      await firestore.collection('notifications').doc(notificationId).delete();
      return const Right(
        'successfully deleted notification',
      ); // success without data
    } on FirebaseException catch (e) {
      return Left(e.message ?? 'Unknown Firestore error');
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either> fetchNotificationsFromFirestore(String uid) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final querySnapshot = await firestore
          .collection('notifications')
          .where('to', isEqualTo: uid)
          .orderBy('created_at', descending: true)
          .get();

      final notifications = querySnapshot.docs.map((doc) {
        final d = NotificationModel.fromJson(doc.data());
        return d;
      }).toList();
      return Right(notifications);
    } on FirebaseException catch (e) {
      return Left(e.message ?? 'An unknown Firebase error occurred');
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, NotificationModel>> findNotificationById(
    String notificationId,
  ) async {
    try {
      final firestore = FirebaseFirestore.instance;
      DocumentReference docRef = firestore
          .collection('notifications')
          .doc(notificationId);
      DocumentSnapshot doc = await docRef.get();
      if (!doc.exists) {
        return Left('work order not found');
      }
      NotificationModel notificationModel = NotificationModel.fromJson(
        doc.data() as Map<String, dynamic>,
      );

      return Right(notificationModel);
    } on FirebaseException catch (e) {
      return Left(e.message!);
    }
  }

  @override
  Future<Either<String, List<NotificationModel>>>
  findNotificationsFromFirestore(String uid) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final querySnapshot = await firestore
          .collection('notifications')
          .where('to', isEqualTo: uid)
          .orderBy('created_at', descending: true)
          .get();

      final notifications = querySnapshot.docs.map((doc) {
        final d = NotificationModel.fromJson(doc.data());
        return d;
      }).toList();
      return Right(notifications);
    } on FirebaseException catch (e) {
      return Left(e.message ?? 'An unknown Firebase error occurred');
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, int>> getCount(String uid) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final querySnapshot = await firestore
          .collection('notifications')
          .where('to', isEqualTo: uid)
          .count()
          .get();

      final count = querySnapshot.count;

      //await importTrends(sampleTrendsData);
      return Right(count ?? 0);
    } on FirebaseException catch (e) {
      return Left(e.message ?? 'An unknown Firebase error occurred');
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either> updateNotification(NotificationModel notification) async {
    try {
      final firestore = FirebaseFirestore.instance;
      firestore
          .collection('notifications')
          .doc(notification.uid)
          .set(notification.toJson(), SetOptions(merge: true));
      return Right(notification);
    } on FirebaseException catch (e) {
      return Left(e.message);
    }
  }
}
