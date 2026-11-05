import 'package:fashionista/data/models/notification/notification_payload.dart';

/// Where a tapped notification should take the user.
class NotificationDestination {
  final String path;

  /// `true` when the payload did not identify a usable resource, so the inbox
  /// is the safest landing place.
  final bool isFallback;

  const NotificationDestination(this.path, {this.isFallback = false});

  static const String inboxPath = '/notifications';
  static const NotificationDestination inbox = NotificationDestination(
    inboxPath,
    isFallback: true,
  );
}

/// Central payload → route mapping.
///
/// Pure and side-effect free so every notification type can be unit tested
/// without a router, Firebase or a widget tree. Navigation itself is performed
/// by `NotificationNavigator`.
class NotificationRouter {
  NotificationRouter._();

  static NotificationDestination resolve(Map<String, dynamic> data) {
    return resolvePayload(NotificationPayload.fromData(data));
  }

  static NotificationDestination resolvePayload(NotificationPayload payload) {
    if (payload.isAppointment) {
      // The two sides of a booking land on different lists.
      if (payload.isForDesigner) {
        if (payload.designerId.isEmpty) return NotificationDestination.inbox;
        return NotificationDestination(
          Uri(
            path: '/designer-bookings',
            queryParameters: {'designerId': payload.designerId},
          ).toString(),
        );
      }
      return const NotificationDestination('/my-bookings');
    }

    if (payload.isWorkOrder) {
      if (payload.refId.isEmpty) return NotificationDestination.inbox;
      return NotificationDestination('/workorders/details/${payload.refId}');
    }

    if (payload.isMeasurement) {
      return const NotificationDestination('/my-measurement');
    }

    if (payload.isTrend) {
      if (payload.refId.isEmpty) return NotificationDestination.inbox;
      return NotificationDestination('/trends/${payload.refId}');
    }

    if (payload.isReview) {
      // The review itself lives on the designer's profile, which is addressed
      // by the designer id — not the review document id.
      if (payload.designerId.isEmpty) return NotificationDestination.inbox;
      return NotificationDestination('/designers/${payload.designerId}');
    }

    return NotificationDestination.inbox;
  }
}
