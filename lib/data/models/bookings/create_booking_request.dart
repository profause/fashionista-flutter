import 'package:equatable/equatable.dart';

/// Everything needed to attempt a slot reservation + booking creation.
class CreateBookingRequest extends Equatable {
  final String designerId;
  final String userId;

  /// Resolved before the transaction; empty means "resolve automatically".
  final String clientId;

  /// Designer-local date (`yyyy-MM-dd`).
  final String date;
  final int dayOfWeek;
  final String startTime;
  final String endTime;

  /// IANA timezone resolved from the designer profile.
  final String timezone;

  final String? notes;

  const CreateBookingRequest({
    required this.designerId,
    required this.userId,
    required this.date,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.timezone,
    this.clientId = '',
    this.notes,
  });

  CreateBookingRequest copyWith({
    String? designerId,
    String? userId,
    String? clientId,
    String? date,
    int? dayOfWeek,
    String? startTime,
    String? endTime,
    String? timezone,
    String? notes,
  }) {
    return CreateBookingRequest(
      designerId: designerId ?? this.designerId,
      userId: userId ?? this.userId,
      clientId: clientId ?? this.clientId,
      date: date ?? this.date,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      timezone: timezone ?? this.timezone,
      notes: notes ?? this.notes,
    );
  }

  @override
  List<Object?> get props => [
    designerId,
    userId,
    clientId,
    date,
    dayOfWeek,
    startTime,
    endTime,
    timezone,
    notes,
  ];
}
