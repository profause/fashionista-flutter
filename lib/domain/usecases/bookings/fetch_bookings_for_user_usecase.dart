import 'package:dartz/dartz.dart';
import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/core/usecase/usecase.dart';
import 'package:fashionista/data/models/bookings/booking_model.dart';
import 'package:fashionista/domain/repository/bookings/booking_repository.dart';

class FetchBookingsForUserUsecase
    implements Usecase<Either<String, List<Booking>>, String> {
  @override
  Future<Either<String, List<Booking>>> call(params) {
    return sl<BookingRepository>().fetchBookingsForUser(params);
  }
}
