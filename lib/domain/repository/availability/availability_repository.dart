import 'package:dartz/dartz.dart';
import 'package:fashionista/data/models/availability/availability_exception_model.dart';
import 'package:fashionista/data/models/availability/designer_availability_model.dart';

abstract class AvailabilityRepository {
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

  Future<Either<String, void>> deleteException(String designerId, String date);

  Future<Either<String, String?>> fetchDesignerTimezone(String designerId);

  Future<Either<String, void>> saveDesignerTimezone(
    String designerId,
    String timezone,
  );
}
