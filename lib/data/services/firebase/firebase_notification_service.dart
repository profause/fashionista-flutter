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

  /// Unread-only counter used by the badge.
  Future<Either<String, int>> getUnreadCount(String uid);

  /// Marks every unread notification of [uid] as read in one go.
  Future<Either<String, int>> markAllAsRead(String uid);

  /// One page of the inbox, newest first.
  Future<Either<String, List<NotificationModel>>> findNotificationsPage(
    String uid, {
    int limit = 20,
    int? beforeCreatedAt,
  });
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
          .limit(100)
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
      await firestore
          .collection('notifications')
          .doc(notification.uid)
          .set(notification.toJson(), SetOptions(merge: true));
      return Right(notification);
    } on FirebaseException catch (e) {
      return Left(e.message);
    }
  }

  @override
  Future<Either<String, int>> getUnreadCount(String uid) async {
    if (uid.isEmpty) return const Right(0);
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('notifications')
          .where('to', isEqualTo: uid)
          .where('status', isEqualTo: 'new')
          .count()
          .get();
      return Right(snapshot.count ?? 0);
    } on FirebaseException catch (e) {
      return Left(e.message ?? 'Unable to count notifications');
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, int>> markAllAsRead(String uid) async {
    if (uid.isEmpty) return const Right(0);
    try {
      final firestore = FirebaseFirestore.instance;
      final snapshot = await firestore
          .collection('notifications')
          .where('to', isEqualTo: uid)
          .where('status', isEqualTo: 'new')
          .get();

      if (snapshot.docs.isEmpty) return const Right(0);

      // Firestore batches cap at 500 writes.
      for (var start = 0; start < snapshot.docs.length; start += 500) {
        final batch = firestore.batch();
        final chunk = snapshot.docs.skip(start).take(500);
        for (final doc in chunk) {
          batch.update(doc.reference, {
            'status': 'read',
            'read_at': Timestamp.fromDate(DateTime.now().toUtc()),
          });
        }
        await batch.commit();
      }

      return Right(snapshot.docs.length);
    } on FirebaseException catch (e) {
      return Left(e.message ?? 'Unable to mark notifications as read');
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, List<NotificationModel>>> findNotificationsPage(
    String uid, {
    int limit = 20,
    int? beforeCreatedAt,
  }) async {
    if (uid.isEmpty) return const Right(<NotificationModel>[]);
    try {
      Query<Map<String, dynamic>> query = FirebaseFirestore.instance
          .collection('notifications')
          .where('to', isEqualTo: uid)
          .orderBy('created_at', descending: true)
          .limit(limit);

      if (beforeCreatedAt != null) {
        query = query.where('created_at', isLessThan: beforeCreatedAt);
      }

      final snapshot = await query.get();
      return Right(
        snapshot.docs
            .map((doc) => NotificationModel.fromJson(doc.data()))
            .toList(),
      );
    } on FirebaseException catch (e) {
      return Left(e.message ?? 'Unable to load notifications');
    } catch (e) {
      return Left(e.toString());
    }
  }
}
