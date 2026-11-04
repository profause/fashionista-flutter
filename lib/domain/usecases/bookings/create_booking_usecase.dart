import 'package:dartz/dartz.dart';
import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/core/usecase/usecase.dart';
import 'package:fashionista/data/models/bookings/booking_model.dart';
import 'package:fashionista/data/models/bookings/create_booking_request.dart';
import 'package:fashionista/domain/repository/bookings/booking_repository.dart';

class CreateBookingUsecase
    implements Usecase<Either<String, Booking>, CreateBookingRequest> {
  @override
  Future<Either<String, Booking>> call(params) {
    return sl<BookingRepository>().createBooking(params);
  }
}
