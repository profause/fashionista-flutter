import 'package:equatable/equatable.dart';
import 'package:fashionista/data/models/availability/available_slot_model.dart';
import 'package:fashionista/data/models/bookings/booking_model.dart';

abstract class BookingState extends Equatable {
  const BookingState();

  @override
  List<Object?> get props => [];
}

class BookingInitial extends BookingState {
  const BookingInitial();
}

class BookingsLoading extends BookingState {
  const BookingsLoading();
}

/// Bookings list for either a designer or a client.
///
/// [ownerId] identifies whose list this is so a screen never renders another
/// screen's data.
class BookingsLoaded extends BookingState {
  final List<Booking> bookings;
  final String ownerId;

  /// `true` when the list came from the designer query, `false` for the
  /// client query. Needed because a user can be both a client and a designer,
  /// and both loads carry the same [ownerId].
  final bool isDesignerView;

  const BookingsLoaded({
    required this.bookings,
    required this.ownerId,
    this.isDesignerView = false,
  });

  /// The booking with [bookingId], or `null` when the list no longer has it.
  Booking? bookingById(String bookingId) {
    for (final booking in bookings) {
      if (booking.uid == bookingId) return booking;
    }
    return null;
  }

  @override
  List<Object?> get props => [bookings, ownerId, isDesignerView];
}

class AvailableSlotsLoading extends BookingState {
  final String designerId;
  final String date;

  const AvailableSlotsLoading({required this.designerId, required this.date});

  @override
  List<Object?> get props => [designerId, date];
}

class AvailableSlotsLoaded extends BookingState {
  final List<AvailableSlot> slots;
  final String designerId;
  final String date;
  final String timezone;

  const AvailableSlotsLoaded({
    required this.slots,
    required this.designerId,
    required this.date,
    this.timezone = '',
  });

  @override
  List<Object?> get props => [slots, designerId, date, timezone];
}

class BookingSubmitting extends BookingState {
  const BookingSubmitting();
}

class BookingCreated extends BookingState {
  final Booking booking;

  const BookingCreated(this.booking);

  @override
  List<Object?> get props => [booking];
}

class BookingActionSuccess extends BookingState {
  final String message;

  const BookingActionSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class BookingError extends BookingState {
  final String message;

  const BookingError(this.message);

  @override
  List<Object?> get props => [message];
}
