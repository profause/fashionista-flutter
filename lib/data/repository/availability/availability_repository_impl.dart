import 'package:dartz/dartz.dart';
import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/data/models/availability/availability_exception_model.dart';
import 'package:fashionista/data/models/availability/designer_availability_model.dart';
import 'package:fashionista/data/services/firebase/firebase_availability_service.dart';
import 'package:fashionista/domain/repository/availability/availability_repository.dart';

class AvailabilityRepositoryImpl implements AvailabilityRepository {
  FirebaseAvailabilityService get _service =>
      sl<FirebaseAvailabilityService>();

  @override
  Future<Either<String, List<DesignerAvailability>>> fetchWeeklyAvailability(
    String designerId,
  ) {
    return _service.fetchWeeklyAvailability(designerId);
  }

  @override
  Future<Either<String, DesignerAvailability?>> fetchDayAvailability(
    String designerId,
    int dayOfWeek,
  ) {
    return _service.fetchDayAvailability(designerId, dayOfWeek);
  }

  @override
  Future<Either<String, void>> saveDayAvailability(
    String designerId,
    DesignerAvailability availability,
  ) {
    return _service.saveDayAvailability(designerId, availability);
  }

  @override
  Future<Either<String, List<AvailabilityException>>> fetchExceptions(
    String designerId, {
    required String dateFrom,
    required String dateTo,
  }) {
    return _service.fetchExceptions(
      designerId,
      dateFrom: dateFrom,
      dateTo: dateTo,
    );
  }

  @override
  Future<Either<String, AvailabilityException?>> fetchException(
    String designerId,
    String date,
  ) {
    return _service.fetchException(designerId, date);
  }

  @override
  Future<Either<String, void>> saveException(
    String designerId,
    AvailabilityException exception,
  ) {
    return _service.saveException(designerId, exception);
  }

  @override
  Future<Either<String, void>> deleteException(String designerId, String date) {
    return _service.deleteException(designerId, date);
  }

  @override
  Future<Either<String, String?>> fetchDesignerTimezone(String designerId) {
    return _service.fetchDesignerTimezone(designerId);
  }

  @override
  Future<Either<String, void>> saveDesignerTimezone(
    String designerId,
    String timezone,
  ) {
    return _service.saveDesignerTimezone(designerId, timezone);
  }
}
