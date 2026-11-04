import 'package:equatable/equatable.dart';
import 'package:fashionista/data/models/availability/availability_exception_model.dart';
import 'package:fashionista/data/models/availability/designer_availability_model.dart';

abstract class AvailabilityEvent extends Equatable {
  const AvailabilityEvent();

  @override
  List<Object?> get props => [];
}

class LoadAvailability extends AvailabilityEvent {
  final String designerId;

  const LoadAvailability(this.designerId);

  @override
  List<Object?> get props => [designerId];
}

class SaveDay extends AvailabilityEvent {
  final String designerId;
  final DesignerAvailability availability;

  /// Set when the designer has seen the conflicting bookings and chose to save
  /// anyway. Existing bookings are never modified either way.
  final bool confirmedConflicts;

  const SaveDay({
    required this.designerId,
    required this.availability,
    this.confirmedConflicts = false,
  });

  @override
  List<Object?> get props => [designerId, availability, confirmedConflicts];
}

class SaveException extends AvailabilityEvent {
  final String designerId;
  final AvailabilityException exception;
  final bool confirmedConflicts;

  const SaveException({
    required this.designerId,
    required this.exception,
    this.confirmedConflicts = false,
  });

  @override
  List<Object?> get props => [designerId, exception, confirmedConflicts];
}

class DeleteException extends AvailabilityEvent {
  final String designerId;
  final String date;

  const DeleteException({required this.designerId, required this.date});

  @override
  List<Object?> get props => [designerId, date];
}

class SaveTimezone extends AvailabilityEvent {
  final String designerId;
  final String timezone;

  const SaveTimezone({required this.designerId, required this.timezone});

  @override
  List<Object?> get props => [designerId, timezone];
}
