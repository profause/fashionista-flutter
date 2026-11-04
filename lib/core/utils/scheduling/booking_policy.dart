/// Booking rules that are policy rather than data.
///
/// Keeping these in one place means product tuning (reservation TTL,
/// cancellation window, booking horizon) never requires hunting through the
/// services or the UI.
class BookingPolicy {
  BookingPolicy._();

  /// How long a `pending` booking holds its slot before another client may
  /// reclaim it. Expired reservations are never deleted; they are treated as
  /// reclaimable inside the booking transaction.
  static const Duration pendingReservationTtl = Duration(minutes: 15);

  /// How far ahead a client may book.
  static const int bookingHorizonDays = 30;

  /// A client may cancel at most this long before the appointment starts.
  static const Duration clientCancellationCutoff = Duration(hours: 2);

  /// Allowed statuses a client may cancel from.
  static const List<String> clientCancellableStatuses = ['pending', 'confirmed'];

  /// Allowed statuses a designer may cancel from.
  static const List<String> designerCancellableStatuses = [
    'pending',
    'confirmed',
  ];
}
