import 'package:fashionista/core/utils/scheduling/time_of_day_x.dart';
import 'package:fashionista/data/models/author/author_model.dart';
import 'package:fashionista/data/models/bookings/booking_client_model.dart';
import 'package:fashionista/data/models/notification/notification_model.dart';

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
    type: 'booking',
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
      'type': 'booking',
      'event': 'appointment_requested',
      'ref_id': bookingId,
      'ref_type': 'booking',
      'audience': 'designer',
      'designer_id': designerId,
      'user_id': userId,
    },
  );
}
