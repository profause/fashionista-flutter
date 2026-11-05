import 'package:fashionista/core/notifications/notification_router.dart';
import 'package:fashionista/data/models/notification/notification_payload.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NotificationPayload', () {
    test('reads FCM-style flat string data', () {
      final payload = NotificationPayload.fromData({
        'type': 'booking',
        'event': 'appointment_confirmed',
        'ref_id': 'booking_1',
        'ref_type': 'booking',
        'audience': 'client',
        'designer_id': 'designer_1',
        'title': 'Confirmed',
        'body': 'See you soon',
      });

      expect(payload.type, 'booking');
      expect(payload.event, 'appointment_confirmed');
      expect(payload.refId, 'booking_1');
      expect(payload.audience, 'client');
      expect(payload.isAppointment, isTrue);
      expect(payload.isForDesigner, isFalse);
    });

    test('accepts snake_case and camelCase identifiers', () {
      final payload = NotificationPayload.fromData({
        'refId': 'booking_9',
        'designerId': 'designer_9',
      });

      expect(payload.refId, 'booking_9');
      expect(payload.designerId, 'designer_9');
    });

    test('falls back to booking_id when ref_id is absent', () {
      final payload = NotificationPayload.fromData({'booking_id': 'b_7'});
      expect(payload.refId, 'b_7');
    });

    test('classifies work orders and measurements', () {
      expect(
        NotificationPayload.fromData({'type': 'work_order_status_progress'})
            .isWorkOrder,
        isTrue,
      );
      expect(
        NotificationPayload.fromData({'event': 'order_completed'}).isWorkOrder,
        isTrue,
      );
      expect(
        NotificationPayload.fromData({'type': 'measurement'}).isMeasurement,
        isTrue,
      );
      expect(
        NotificationPayload.fromData({'event': 'appointment_cancelled'})
            .isAppointment,
        isTrue,
      );
    });

    test('empty data yields an inert payload', () {
      final payload = NotificationPayload.fromData(const {});
      expect(payload.isAppointment, isFalse);
      expect(payload.isWorkOrder, isFalse);
      expect(payload.isMeasurement, isFalse);
      expect(payload.refId, '');
    });
  });

  group('NotificationRouter', () {
    test('designer appointment opens their appointments list', () {
      final destination = NotificationRouter.resolve({
        'type': 'booking',
        'audience': 'designer',
        'designer_id': 'designer_1',
      });

      expect(destination.isFallback, isFalse);
      expect(destination.path, '/designer-bookings?designerId=designer_1');
    });

    test('client appointment opens my bookings', () {
      final destination = NotificationRouter.resolve({
        'type': 'booking',
        'audience': 'client',
        'event': 'appointment_confirmed',
      });

      expect(destination.path, '/my-bookings');
    });

    test('designer appointment without a designer id falls back to inbox', () {
      final destination = NotificationRouter.resolve({
        'type': 'booking',
        'audience': 'designer',
      });

      expect(destination.isFallback, isTrue);
      expect(destination.path, '/notifications');
    });

    test('work order opens the order details', () {
      final destination = NotificationRouter.resolve({
        'type': 'work_order_status_progress',
        'ref_id': 'wo_42',
      });

      expect(destination.path, '/workorders/details/wo_42');
    });

    test('work order without an id falls back to inbox', () {
      final destination = NotificationRouter.resolve({
        'type': 'work_order_status_progress',
      });

      expect(destination.path, '/notifications');
      expect(destination.isFallback, isTrue);
    });

    test('measurement opens my measurement', () {
      final destination = NotificationRouter.resolve({
        'type': 'measurement',
      });

      expect(destination.path, '/my-measurement');
    });

    test('trend like opens the liked trend', () {
      final destination = NotificationRouter.resolve({
        'type': 'trend',
        'event': 'trend_liked',
        'ref_id': 'trend_7',
        'ref_type': 'trend',
        'audience': 'user',
      });

      expect(destination.path, '/trends/trend_7');
      expect(destination.isFallback, isFalse);
    });

    test('trend like without an id falls back to inbox', () {
      final destination = NotificationRouter.resolve({
        'type': 'trend',
        'event': 'trend_liked',
      });

      expect(destination.path, '/notifications');
      expect(destination.isFallback, isTrue);
    });

    test('designer review opens the designer profile', () {
      final destination = NotificationRouter.resolve({
        'type': 'review',
        'event': 'review_received',
        'ref_id': 'review_9',
        'ref_type': 'designer_review',
        'designer_id': 'designer_3',
        'audience': 'designer',
      });

      expect(destination.path, '/designers/designer_3');
      expect(destination.isFallback, isFalse);
    });

    test('designer review without a designer id falls back to inbox', () {
      final destination = NotificationRouter.resolve({
        'type': 'review',
        'event': 'review_received',
        'ref_id': 'review_9',
      });

      expect(destination.path, '/notifications');
      expect(destination.isFallback, isTrue);
    });

    test('unknown type falls back to the inbox', () {
      final destination = NotificationRouter.resolve({'type': 'unknown'});

      expect(destination.path, '/notifications');
      expect(destination.isFallback, isTrue);
    });

    test('empty payload falls back to the inbox', () {
      expect(
        NotificationRouter.resolve(const {}).path,
        '/notifications',
      );
    });

    test('designer id is URL-encoded in the query string', () {
      final destination = NotificationRouter.resolve({
        'type': 'booking',
        'audience': 'designer',
        'designer_id': 'a b/c',
      });

      expect(destination.path, contains('designerId='));
      expect(destination.path, isNot(contains(' ')));
    });
  });
}
