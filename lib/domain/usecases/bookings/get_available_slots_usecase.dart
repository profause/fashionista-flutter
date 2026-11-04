import 'package:dartz/dartz.dart';
import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/core/usecase/usecase.dart';
import 'package:fashionista/core/utils/scheduling/date_key.dart';
import 'package:fashionista/core/utils/scheduling/designer_time_zone.dart';
import 'package:fashionista/core/utils/scheduling/slot_generator.dart';
import 'package:fashionista/data/models/availability/available_slot_model.dart';
import 'package:fashionista/domain/repository/availability/availability_repository.dart';
import 'package:fashionista/domain/repository/bookings/booking_repository.dart';
import 'package:timezone/timezone.dart' as tz;

class GetAvailableSlotsParams {
  final String designerId;

  /// Designer-local date (`yyyy-MM-dd`).
  final String date;

  const GetAvailableSlotsParams({
    required this.designerId,
    required this.date,
  });
}

/// Builds the slots a client may actually book on [date].
///
/// Combines the designer's weekly schedule, any date exception and the bookings
/// that already hold a slot, then drops times that have already passed.
/// Generated slots are never written to Firestore.
class GetAvailableSlotsUsecase
    implements
        Usecase<Either<String, List<AvailableSlot>>, GetAvailableSlotsParams> {
  @override
  Future<Either<String, List<AvailableSlot>>> call(params) async {
    final parsedDate = DateKey.tryParse(params.date);
    if (parsedDate == null) {
      return const Left('Please pick a valid date.');
    }

    final availabilityRepository = sl<AvailabilityRepository>();
    final bookingRepository = sl<BookingRepository>();

    final timezoneResult = await availabilityRepository.fetchDesignerTimezone(
      params.designerId,
    );

    String timezone = '';
    final timezoneFailure = timezoneResult.fold<String?>(
      (failure) => failure,
      (value) {
        timezone = value ?? '';
        return null;
      },
    );
    if (timezoneFailure != null) return Left(timezoneFailure);

    final location = DesignerTimeZone.resolve(timezone);
    final dayOfWeek = parsedDate.weekday;

    final weeklyResult = await availabilityRepository.fetchDayAvailability(
      params.designerId,
      dayOfWeek,
    );
    final exceptionResult = await availabilityRepository.fetchException(
      params.designerId,
      params.date,
    );
    final bookedResult = await bookingRepository.fetchBookedStartTimes(
      designerId: params.designerId,
      date: params.date,
      timezone: timezone,
    );

    return weeklyResult.fold(
      (failure) => Left(failure),
      (weekly) => exceptionResult.fold(
        (failure) => Left(failure),
        (exception) => bookedResult.fold(
          (failure) => Left(failure),
          (bookedStartTimes) {
            final todayKey = DesignerTimeZone.todayKey(location);
            final isToday = todayKey == params.date;
            final now = isToday ? tz.TZDateTime.now(location) : null;

            final slots = SlotSchedulingService.buildDaySlots(
              weekly: weekly,
              exception: exception,
              bookedStartTimes: bookedStartTimes,
              now: now,
            );

            return Right(slots);
          },
        ),
      ),
    );
  }
}
