import 'package:dartz/dartz.dart';
import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/data/models/bookings/booking_model.dart';
import 'package:fashionista/data/models/bookings/booking_status.dart';
import 'package:fashionista/data/models/bookings/create_booking_request.dart';
import 'package:fashionista/data/services/firebase/firebase_booking_service.dart';
import 'package:fashionista/domain/repository/bookings/booking_repository.dart';

class BookingRepositoryImpl implements BookingRepository {
  FirebaseBookingService get _service => sl<FirebaseBookingService>();

  @override
  Future<Either<String, List<Booking>>> fetchBookingsForDesigner(
    String designerId,
  ) {
    return _service.findBookingsForDesigner(designerId);
  }

  @override
  Stream<List<Booking>> watchBookingsForDesigner(String designerId) {
    return _service.streamBookingsForDesigner(designerId);
  }

  @override
  Future<Either<String, List<Booking>>> fetchBookingsForUser(String userId) {
    return _service.findBookingsForUser(userId);
  }

  @override
  Stream<List<Booking>> watchBookingsForUser(String userId) {
    return _service.streamBookingsForUser(userId);
  }

  @override
  Future<Either<String, List<Booking>>> fetchBookingsForDesignerOnDate({
    required String designerId,
    required String date,
    required String timezone,
  }) {
    return _service.findBookingsForDesignerOnDate(designerId, date, timezone);
  }

  @override
  Future<Either<String, Booking?>> fetchBookingById(String bookingId) {
    return _service.findBookingById(bookingId);
  }

  @override
  Stream<Booking?> watchBooking(String bookingId) {
    return _service.streamBooking(bookingId);
  }

  @override
  Future<Either<String, Set<String>>> fetchBookedStartTimes({
    required String designerId,
    required String date,
    required String timezone,
  }) {
    return _service.findBookedStartTimes(
      designerId: designerId,
      date: date,
      timezone: timezone,
    );
  }

  @override
  Future<Either<String, List<Booking>>> fetchScheduleConflicts({
    required String designerId,
    required int dayOfWeek,
    String? date,
  }) {
    return _service.findScheduleConflicts(
      designerId: designerId,
      dayOfWeek: dayOfWeek,
      date: date,
    );
  }

  @override
  Future<Either<String, Booking>> createBooking(CreateBookingRequest request) {
    return _service.createBooking(request);
  }

  @override
  Future<Either<String, void>> updateBookingStatus({
    required String bookingId,
    required BookingStatus status,
    required String actorUserId,
    required bool actorIsDesigner,
  }) {
    return _service.updateBookingStatus(
      bookingId: bookingId,
      status: status,
      actorUserId: actorUserId,
      actorIsDesigner: actorIsDesigner,
    );
  }
}
