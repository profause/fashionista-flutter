import 'package:fashionista/core/utils/scheduling/time_of_day_x.dart';
import 'package:fashionista/data/models/author/author_model.dart';
import 'package:fashionista/data/models/bookings/booking_client_model.dart';
import 'package:fashionista/data/models/notification/notification_model.dart';

/// Document id for the notification a designer receives when a client books.
///
/// Must produce exactly what the server derives from
/// `buildIdempotencyKey(['booking', 'requested', bookingId])` in
/// `functions/src/triggers/booking.triggers.ts` — `booking__requested__{id}`.
///
/// The two sides writing to the same id is what keeps a booking down to one
/// inbox entry: the server's `createHistoryIfAbsent` finds the document the
/// client transaction already created and skips inserting a second copy.
String buildBookingNotificationId(String bookingId) =>
    'booking__requested__$bookingId';

/// Builds the notification a designer receives when a client books a slot.
///
/// Kept as a pure function so the payload contract is unit tested and the
/// booking transaction stays readable.
NotificationModel buildBookingNotification({
  required String notificationId,
  required String bookingId,
  required String designerId,
  required String userId,
  required BookingClient client,
  required String date,
  required String startTime,
  required DateTime createdAt,
}) {
  return NotificationModel(
    uid: notificationId,
    refId: bookingId,
    refType: 'booking',
    title: 'New appointment request',
    description:
        '${client.displayName} requested $date at '
        '${TimeOfDayX.toDisplay(startTime)}',
    type: 'appointment',
    author: AuthorModel(
      uid: userId,
      name: client.name,
      avatar: client.avatar,
      mobileNumber: client.mobileNumber,
    ),
    createdAt: createdAt.millisecondsSinceEpoch,
    status: 'new',
    from: userId,
    to: designerId,
    event: 'appointment_requested',
    // Routing data for the push/inbox tap.
    data: {
      'type': 'appointment',
      'event': 'appointment_requested',
      'ref_id': bookingId,
      'ref_type': 'booking',
      'audience': 'designer',
      'designer_id': designerId,
      'user_id': userId,
    },
  );
}
