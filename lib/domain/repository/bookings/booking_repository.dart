import 'package:dartz/dartz.dart';
import 'package:fashionista/data/models/bookings/booking_model.dart';
import 'package:fashionista/data/models/bookings/booking_status.dart';
import 'package:fashionista/data/models/bookings/create_booking_request.dart';

abstract class BookingRepository {
  Future<Either<String, List<Booking>>> fetchBookingsForDesigner(
    String designerId,
  );

  Stream<List<Booking>> watchBookingsForDesigner(String designerId);

  Future<Either<String, List<Booking>>> fetchBookingsForUser(String userId);

  Stream<List<Booking>> watchBookingsForUser(String userId);

  Future<Either<String, List<Booking>>> fetchBookingsForDesignerOnDate({
    required String designerId,
    required String date,
    required String timezone,
  });

  Future<Either<String, Booking?>> fetchBookingById(String bookingId);

  Stream<Booking?> watchBooking(String bookingId);

  Future<Either<String, Set<String>>> fetchBookedStartTimes({
    required String designerId,
    required String date,
    required String timezone,
  });

  Future<Either<String, List<Booking>>> fetchScheduleConflicts({
    required String designerId,
    required int dayOfWeek,
    String? date,
  });

  Future<Either<String, Booking>> createBooking(CreateBookingRequest request);

  Future<Either<String, void>> updateBookingStatus({
    required String bookingId,
    required BookingStatus status,
    required String actorUserId,
    required bool actorIsDesigner,
  });
}
