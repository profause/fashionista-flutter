import 'package:equatable/equatable.dart';
import 'package:fashionista/data/models/bookings/booking_status.dart';
import 'package:fashionista/data/models/bookings/create_booking_request.dart';

abstract class BookingEvent extends Equatable {
  const BookingEvent();

  @override
  List<Object?> get props => [];
}

class LoadDesignerBookings extends BookingEvent {
  final String designerId;
  final bool refreshOnly;

  const LoadDesignerBookings(this.designerId, {this.refreshOnly = false});

  @override
  List<Object?> get props => [designerId, refreshOnly];
}

class LoadMyBookings extends BookingEvent {
  final String userId;
  final bool refreshOnly;

  const LoadMyBookings(this.userId, {this.refreshOnly = false});

  @override
  List<Object?> get props => [userId, refreshOnly];
}

class LoadAvailableSlots extends BookingEvent {
  final String designerId;
  final String date;

  const LoadAvailableSlots({required this.designerId, required this.date});

  @override
  List<Object?> get props => [designerId, date];
}

class CreateBooking extends BookingEvent {
  final CreateBookingRequest request;

  const CreateBooking(this.request);

  @override
  List<Object?> get props => [request];
}

class ChangeBookingStatus extends BookingEvent {
  final String bookingId;
  final BookingStatus status;
  final String actorUserId;
  final bool actorIsDesigner;

  const ChangeBookingStatus({
    required this.bookingId,
    required this.status,
    required this.actorUserId,
    required this.actorIsDesigner,
  });

  @override
  List<Object?> get props => [bookingId, status, actorUserId, actorIsDesigner];
}

class ResetBookingState extends BookingEvent {
  const ResetBookingState();
}
