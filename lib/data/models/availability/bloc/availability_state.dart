import 'package:equatable/equatable.dart';
import 'package:fashionista/data/models/availability/availability_exception_model.dart';
import 'package:fashionista/data/models/availability/designer_availability_model.dart';
import 'package:fashionista/data/models/bookings/booking_model.dart';

abstract class AvailabilityState extends Equatable {
  const AvailabilityState();

  @override
  List<Object?> get props => [];
}

class AvailabilityInitial extends AvailabilityState {
  const AvailabilityInitial();
}

class AvailabilityLoading extends AvailabilityState {
  const AvailabilityLoading();
}

class AvailabilityLoaded extends AvailabilityState {
  final List<DesignerAvailability> weekly;
  final String timezone;

  const AvailabilityLoaded({required this.weekly, this.timezone = ''});

  @override
  List<Object?> get props => [weekly, timezone];
}

class AvailabilitySaving extends AvailabilityState {
  final List<DesignerAvailability> weekly;
  final String timezone;

  const AvailabilitySaving({required this.weekly, this.timezone = ''});

  @override
  List<Object?> get props => [weekly, timezone];
}

class AvailabilitySaved extends AvailabilityState {
  final List<DesignerAvailability> weekly;
  final String timezone;
  final String message;

  const AvailabilitySaved({
    required this.weekly,
    required this.message,
    this.timezone = '',
  });

  @override
  List<Object?> get props => [weekly, timezone, message];
}

/// Emitted instead of saving when existing bookings would be invalidated.
///
/// The designer must acknowledge the conflict explicitly; nothing is cancelled
/// or deleted automatically.
class AvailabilityConflicts extends AvailabilityState {
  final List<DesignerAvailability> weekly;
  final String timezone;
  final List<Booking> conflicts;
  final DesignerAvailability? pendingDay;
  final AvailabilityException? pendingException;

  const AvailabilityConflicts({
    required this.weekly,
    required this.conflicts,
    this.timezone = '',
    this.pendingDay,
    this.pendingException,
  });

  @override
  List<Object?> get props => [
    weekly,
    timezone,
    conflicts,
    pendingDay,
    pendingException,
  ];
}

class AvailabilityError extends AvailabilityState {
  final String message;
  final List<DesignerAvailability> weekly;
  final String timezone;

  const AvailabilityError({
    required this.message,
    required this.weekly,
    this.timezone = '',
  });

  @override
  List<Object?> get props => [message, weekly, timezone];
}
