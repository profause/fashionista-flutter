import 'package:dartz/dartz.dart';
import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/core/usecase/usecase.dart';
import 'package:fashionista/data/models/bookings/booking_model.dart';
import 'package:fashionista/domain/repository/bookings/booking_repository.dart';

class FetchScheduleConflictsParams {
  final String designerId;
  final int dayOfWeek;
  final String? date;

  const FetchScheduleConflictsParams({
    required this.designerId,
    required this.dayOfWeek,
    this.date,
  });
}

class FetchScheduleConflictsUsecase
    implements
        Usecase<Either<String, List<Booking>>, FetchScheduleConflictsParams> {
  @override
  Future<Either<String, List<Booking>>> call(params) {
    return sl<BookingRepository>().fetchScheduleConflicts(
      designerId: params.designerId,
      dayOfWeek: params.dayOfWeek,
      date: params.date,
    );
  }
}
