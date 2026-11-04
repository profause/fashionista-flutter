import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:fashionista/data/models/notification/device_registration_model.dart';

abstract class FirebaseDeviceService {
  Future<Either<String, void>> registerDevice({
    required String userId,
    required String deviceId,
    required DeviceRegistration registration,
  });

  Future<Either<String, void>> deactivateDevice({
    required String userId,
    required String deviceId,
  });

  Future<Either<String, DeviceRegistration?>> findDevice({
    required String userId,
    required String deviceId,
  });
}

class FirebaseDeviceServiceImpl implements FirebaseDeviceService {
  final FirebaseFirestore? _firestoreOverride;

  FirebaseDeviceServiceImpl({FirebaseFirestore? firestore})
    : _firestoreOverride = firestore;

  FirebaseFirestore get _firestore =>
      _firestoreOverride ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _devices(String userId) {
    return _firestore.collection('users').doc(userId).collection('devices');
  }

  @override
  Future<Either<String, void>> registerDevice({
    required String userId,
    required String deviceId,
    required DeviceRegistration registration,
  }) async {
    if (userId.isEmpty || deviceId.isEmpty) {
      return const Left('Missing user or device identifier.');
    }

    try {
      final ref = _devices(userId).doc(deviceId);
      final existing = await ref.get();
      final now = DateTime.now().toUtc();

      await ref.set({
        ...registration.toFirestore(),
        'created_at':
            existing.data()?['created_at'] ??
            Timestamp.fromDate(registration.createdAt ?? now),
        'updated_at': Timestamp.fromDate(now),
        'last_seen_at': Timestamp.fromDate(now),
      }, SetOptions(merge: true));

      return const Right(null);
    } on FirebaseException catch (e) {
      return Left(e.message ?? 'Unable to register this device.');
    } catch (e) {
      return Left('Unable to register this device: $e');
    }
  }

  @override
  Future<Either<String, void>> deactivateDevice({
    required String userId,
    required String deviceId,
  }) async {
    if (userId.isEmpty || deviceId.isEmpty) return const Right(null);

    try {
      final ref = _devices(userId).doc(deviceId);
      final existing = await ref.get();
      if (!existing.exists) return const Right(null);

      await ref.update({
        'is_active': false,
        'fcm_token': '',
        'updated_at': Timestamp.fromDate(DateTime.now().toUtc()),
      });

      return const Right(null);
    } on FirebaseException catch (e) {
      return Left(e.message ?? 'Unable to deactivate this device.');
    } catch (e) {
      return Left('Unable to deactivate this device: $e');
    }
  }

  @override
  Future<Either<String, DeviceRegistration?>> findDevice({
    required String userId,
    required String deviceId,
  }) async {
    try {
      final doc = await _devices(userId).doc(deviceId).get();
      if (!doc.exists) return const Right(null);
      return Right(DeviceRegistration.fromJson(doc.data()!));
    } on FirebaseException catch (e) {
      return Left(e.message ?? 'Unable to read this device.');
    } catch (e) {
      return Left('Unable to read this device: $e');
    }
  }
}
