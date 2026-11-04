import 'package:json_annotation/json_annotation.dart';

/// Lifecycle of an appointment booking.
///
/// Stored in Firestore as the lower `snake_case` name (`no_show`, not `noShow`).
enum BookingStatus {
  pending,
  confirmed,
  declined,
  cancelled,
  completed,
  @JsonValue('no_show')
  noShow,
}

extension BookingStatusX on BookingStatus {
  /// Wire value persisted in Firestore.
  String get value {
    switch (this) {
      case BookingStatus.pending:
        return 'pending';
      case BookingStatus.confirmed:
        return 'confirmed';
      case BookingStatus.declined:
        return 'declined';
      case BookingStatus.cancelled:
        return 'cancelled';
      case BookingStatus.completed:
        return 'completed';
      case BookingStatus.noShow:
        return 'no_show';
    }
  }

  String get label {
    switch (this) {
      case BookingStatus.pending:
        return 'Pending';
      case BookingStatus.confirmed:
        return 'Confirmed';
      case BookingStatus.declined:
        return 'Declined';
      case BookingStatus.cancelled:
        return 'Cancelled';
      case BookingStatus.completed:
        return 'Completed';
      case BookingStatus.noShow:
        return 'No show';
    }
  }

  /// Statuses that still occupy a slot.
  bool get holdsSlot =>
      this == BookingStatus.pending || this == BookingStatus.confirmed;

  /// Statuses that are still upcoming work for the designer.
  bool get isUpcoming =>
      this == BookingStatus.pending || this == BookingStatus.confirmed;

  static BookingStatus fromValue(String? value) {
    switch ((value ?? '').trim().toLowerCase()) {
      case 'pending':
        return BookingStatus.pending;
      case 'confirmed':
        return BookingStatus.confirmed;
      case 'declined':
        return BookingStatus.declined;
      case 'cancelled':
        return BookingStatus.cancelled;
      case 'completed':
        return BookingStatus.completed;
      case 'no_show':
      case 'noshow':
        return BookingStatus.noShow;
      default:
        return BookingStatus.pending;
    }
  }
}
