import 'package:fashionista/data/models/bookings/booking_model.dart';

/// Timestamp a booking list can be ordered by.
enum BookingSortField {
  /// When the appointment takes place (`start_at`).
  startAt,

  /// When the request was submitted (`created_at`).
  createdAt,
}

/// Ordering for appointment lists.
///
/// Bookings that are missing the selected timestamp sort last regardless of the
/// direction, so a legacy document is never mistaken for the oldest entry.
class BookingSort {
  BookingSort._();

  static DateTime? valueOf(Booking booking, BookingSortField field) {
    return field == BookingSortField.startAt
        ? booking.startAt
        : booking.createdAt;
  }

  static int compare(
    Booking a,
    Booking b, {
    required BookingSortField field,
    required bool ascending,
  }) {
    final aValue = valueOf(a, field);
    final bValue = valueOf(b, field);

    if (aValue == null && bValue == null) return 0;
    if (aValue == null) return 1;
    if (bValue == null) return -1;

    return ascending ? aValue.compareTo(bValue) : bValue.compareTo(aValue);
  }

  /// Returns a sorted copy; the input is left untouched.
  static List<Booking> sorted(
    Iterable<Booking> bookings, {
    required BookingSortField field,
    required bool ascending,
  }) {
    final list = bookings.toList();
    list.sort((a, b) => compare(a, b, field: field, ascending: ascending));
    return list;
  }
}
