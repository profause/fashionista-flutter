import 'package:dartz/dartz.dart';
import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/core/usecase/usecase.dart';
import 'package:fashionista/data/models/bookings/booking_status.dart';
import 'package:fashionista/domain/repository/bookings/booking_repository.dart';

class UpdateBookingStatusParams {
  final String bookingId;
  final BookingStatus status;
  final String actorUserId;
  final bool actorIsDesigner;

  const UpdateBookingStatusParams({
    required this.bookingId,
    required this.status,
    required this.actorUserId,
    required this.actorIsDesigner,
  });
}

class UpdateBookingStatusUsecase
    implements Usecase<Either<String, void>, UpdateBookingStatusParams> {
  @override
  Future<Either<String, void>> call(params) {
    return sl<BookingRepository>().updateBookingStatus(
      bookingId: params.bookingId,
      status: params.status,
      actorUserId: params.actorUserId,
      actorIsDesigner: params.actorIsDesigner,
    );
  }
}
