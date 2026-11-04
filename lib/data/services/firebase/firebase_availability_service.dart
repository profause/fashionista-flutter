import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:fashionista/data/models/availability/availability_exception_model.dart';
import 'package:fashionista/data/models/availability/designer_availability_model.dart';

abstract class FirebaseAvailabilityService {
  Future<Either<String, List<DesignerAvailability>>> fetchWeeklyAvailability(
    String designerId,
  );

  Future<Either<String, DesignerAvailability?>> fetchDayAvailability(
    String designerId,
    int dayOfWeek,
  );

  Future<Either<String, void>> saveDayAvailability(
    String designerId,
    DesignerAvailability availability,
  );

  Future<Either<String, List<AvailabilityException>>> fetchExceptions(
    String designerId, {
    required String dateFrom,
    required String dateTo,
  });

  Future<Either<String, AvailabilityException?>> fetchException(
    String designerId,
    String date,
  );

  Future<Either<String, void>> saveException(
    String designerId,
    AvailabilityException exception,
  );

  Future<Either<String, void>> deleteException(
    String designerId,
    String date,
  );

  Future<Either<String, String?>> fetchDesignerTimezone(String designerId);

  Future<Either<String, void>> saveDesignerTimezone(
    String designerId,
    String timezone,
  );
}

class FirebaseAvailabilityServiceImpl implements FirebaseAvailabilityService {
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _availabilityCollection(
    String designerId,
  ) {
    return _firestore
        .collection('designers')
        .doc(designerId)
        .collection('availability');
  }

  CollectionReference<Map<String, dynamic>> _exceptionsCollection(
    String designerId,
  ) {
    return _firestore
        .collection('designers')
        .doc(designerId)
        .collection('availability_exceptions');
  }

  @override
  Future<Either<String, List<DesignerAvailability>>> fetchWeeklyAvailability(
    String designerId,
  ) async {
    try {
      final snapshot = await _availabilityCollection(designerId).get();
      final byDay = <int, DesignerAvailability>{};

      for (final doc in snapshot.docs) {
        final model = DesignerAvailability.fromJson(doc.data());
        // The document id is authoritative for the weekday.
        final dayFromId = int.tryParse(doc.id) ?? model.dayOfWeek;
        byDay[dayFromId] = model.copyWith(dayOfWeek: dayFromId);
      }

      return Right([
        for (var day = DateTime.monday; day <= DateTime.sunday; day++)
          byDay[day] ?? DesignerAvailability.empty(day),
      ]);
    } on FirebaseException catch (e) {
      return Left(e.message ?? 'Unable to load availability');
    } catch (e) {
      return Left('Unable to load availability: $e');
    }
  }

  @override
  Future<Either<String, DesignerAvailability?>> fetchDayAvailability(
    String designerId,
    int dayOfWeek,
  ) async {
    try {
      final doc = await _availabilityCollection(
        designerId,
      ).doc(dayOfWeek.toString()).get();
      if (!doc.exists) return const Right(null);
      return Right(
        DesignerAvailability.fromJson(
          doc.data()!,
        ).copyWith(dayOfWeek: dayOfWeek),
      );
    } on FirebaseException catch (e) {
      return Left(e.message ?? 'Unable to load this day');
    } catch (e) {
      return Left('Unable to load this day: $e');
    }
  }

  @override
  Future<Either<String, void>> saveDayAvailability(
    String designerId,
    DesignerAvailability availability,
  ) async {
    try {
      await _availabilityCollection(designerId)
          .doc(availability.dayOfWeek.toString())
          .set(
            availability
                .copyWith(updatedAt: DateTime.now().toUtc())
                .toJson(),
            SetOptions(merge: true),
          );
      return const Right(null);
    } on FirebaseException catch (e) {
      return Left(e.message ?? 'Unable to save availability');
    } catch (e) {
      return Left('Unable to save availability: $e');
    }
  }

  @override
  Future<Either<String, List<AvailabilityException>>> fetchExceptions(
    String designerId, {
    required String dateFrom,
    required String dateTo,
  }) async {
    try {
      final snapshot = await _exceptionsCollection(designerId)
          .where(
            FieldPath.documentId,
            isGreaterThanOrEqualTo: dateFrom,
            isLessThanOrEqualTo: dateTo,
          )
          .get();

      return Right(
        snapshot.docs.map((doc) {
          final model = AvailabilityException.fromJson(doc.data());
          return model.copyWith(date: doc.id);
        }).toList(),
      );
    } on FirebaseException catch (e) {
      return Left(e.message ?? 'Unable to load availability exceptions');
    } catch (e) {
      return Left('Unable to load availability exceptions: $e');
    }
  }

  @override
  Future<Either<String, AvailabilityException?>> fetchException(
    String designerId,
    String date,
  ) async {
    try {
      final doc = await _exceptionsCollection(designerId).doc(date).get();
      if (!doc.exists) return const Right(null);
      return Right(
        AvailabilityException.fromJson(
          doc.data()!,
        ).copyWith(date: doc.id),
      );
    } on FirebaseException catch (e) {
      return Left(e.message ?? 'Unable to load this exception');
    } catch (e) {
      return Left('Unable to load this exception: $e');
    }
  }

  @override
  Future<Either<String, void>> saveException(
    String designerId,
    AvailabilityException exception,
  ) async {
    try {
      final now = DateTime.now().toUtc();
      final payload = exception
          .copyWith(createdAt: exception.createdAt ?? now, updatedAt: now)
          .toJson();
      await _exceptionsCollection(designerId)
          .doc(exception.date)
          .set(payload, SetOptions(merge: true));
      return const Right(null);
    } on FirebaseException catch (e) {
      return Left(e.message ?? 'Unable to save the exception');
    } catch (e) {
      return Left('Unable to save the exception: $e');
    }
  }

  @override
  Future<Either<String, void>> deleteException(
    String designerId,
    String date,
  ) async {
    try {
      await _exceptionsCollection(designerId).doc(date).delete();
      return const Right(null);
    } on FirebaseException catch (e) {
      return Left(e.message ?? 'Unable to remove the exception');
    } catch (e) {
      return Left('Unable to remove the exception: $e');
    }
  }

  @override
  Future<Either<String, String?>> fetchDesignerTimezone(
    String designerId,
  ) async {
    try {
      final doc = await _firestore.collection('designers').doc(designerId).get();
      if (!doc.exists) return const Right(null);
      final timezone = doc.data()?['timezone'];
      return Right(timezone is String && timezone.isNotEmpty ? timezone : null);
    } on FirebaseException catch (e) {
      return Left(e.message ?? 'Unable to load the designer timezone');
    } catch (e) {
      return Left('Unable to load the designer timezone: $e');
    }
  }

  @override
  Future<Either<String, void>> saveDesignerTimezone(
    String designerId,
    String timezone,
  ) async {
    try {
      await _firestore.collection('designers').doc(designerId).set({
        'timezone': timezone,
      }, SetOptions(merge: true));
      return const Right(null);
    } on FirebaseException catch (e) {
      return Left(e.message ?? 'Unable to save the designer timezone');
    } catch (e) {
      return Left('Unable to save the designer timezone: $e');
    }
  }
}
