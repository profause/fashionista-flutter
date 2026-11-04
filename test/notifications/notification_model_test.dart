import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fashionista/core/service_locator/local_notification_service.dart';
import 'package:fashionista/data/models/notification/device_registration_model.dart';
import 'package:fashionista/data/models/notification/notification_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NotificationModel', () {
    test('round-trips the notification inbox fields', () {
      final model = NotificationModel(
        uid: 'notif_1',
        refId: 'booking_1',
        refType: 'booking',
        title: 'Appointment confirmed',
        description: 'Your appointment is confirmed',
        type: 'booking',
        createdAt: DateTime.utc(2026, 11, 4).millisecondsSinceEpoch,
        status: 'new',
        event: 'appointment_confirmed',
        readAt: DateTime.utc(2026, 11, 5),
        data: const {'audience': 'client', 'designer_id': 'designer_1'},
        from: 'designer_1',
        to: 'user_1',
      );

      final restored = NotificationModel.fromJson(model.toJson());

      expect(restored.event, 'appointment_confirmed');
      expect(restored.readAt, DateTime.utc(2026, 11, 5));
      expect(restored.data?['audience'], 'client');
      expect(restored.data?['designer_id'], 'designer_1');
      expect(restored.createdAt, model.createdAt);
    });

    test('deserializes legacy documents without the new fields', () {
      final restored = NotificationModel.fromJson({
        'uid': 'legacy',
        'title': 'New Client',
        'description': 'Someone added you',
        'type': 'info',
        'created_at': 1700000000000,
        'status': 'read',
        'from': 'a',
        'to': 'b',
      });

      expect(restored.event, isNull);
      expect(restored.readAt, isNull);
      expect(restored.data, isNull);
      expect(restored.status, 'read');
    });

    test('reads read_at stored as a Firestore timestamp', () {
      final restored = NotificationModel.fromJson({
        'uid': 'n',
        'title': 't',
        'description': 'd',
        'type': 'booking',
        'created_at': 0,
        'read_at': Timestamp.fromDate(DateTime.utc(2026, 1, 2, 3)),
        'to': 'u',
      });

      expect(restored.readAt, DateTime.utc(2026, 1, 2, 3));
    });

    test('copyWith updates only the read state', () {
      final model = NotificationModel(
        uid: 'n',
        title: 't',
        description: 'd',
        type: 'booking',
        to: 'u',
      );

      final read = model.copyWith(
        status: 'read',
        readAt: DateTime.utc(2026, 1, 1),
      );

      expect(read.status, 'read');
      expect(read.readAt, DateTime.utc(2026, 1, 1));
      expect(read.uid, 'n');
    });
  });

  group('DeviceRegistration', () {
    test('serializes to the devices subcollection shape', () {
      final device = DeviceRegistration(
        fcmToken: 'token_123',
        platform: 'android',
        deviceName: 'Pixel',
        isActive: true,
        createdAt: DateTime.utc(2026, 11, 4),
      );

      final json = device.toJson();

      expect(json['fcm_token'], 'token_123');
      expect(json['platform'], 'android');
      expect(json['device_name'], 'Pixel');
      expect(json['is_active'], isTrue);
      expect(json['created_at'], isA<Timestamp>());
    });

    test('defaults to active and round-trips', () {
      final restored = DeviceRegistration.fromJson({
        'fcm_token': 't',
        'platform': 'ios',
      });

      expect(restored.isActive, isTrue);
      expect(restored.platform, 'ios');
      expect(restored.deviceName, isNull);
    });

    test('toFirestore always stamps updated_at', () {
      final payload = DeviceRegistration(
        fcmToken: 't',
        platform: 'ios',
      ).toFirestore();

      expect(payload['updated_at'], isA<Timestamp>());
      expect(payload['last_seen_at'], isA<Timestamp>());
    });
  });

  group('LocalNotificationService payload codec', () {
    test('encodes data as a JSON string and decodes it back', () {
      const data = {
        'type': 'booking',
        'event': 'appointment_confirmed',
        'designer_id': 'd1',
      };

      final encoded = LocalNotificationService.encodePayload(data);
      final decoded = LocalNotificationService.parsePayload(encoded);

      expect(decoded['type'], 'booking');
      expect(decoded['event'], 'appointment_confirmed');
      expect(decoded['designer_id'], 'd1');
    });

    test('empty data encodes to an empty payload', () {
      expect(LocalNotificationService.encodePayload(const {}), '');
      expect(LocalNotificationService.parsePayload(''), isEmpty);
      expect(LocalNotificationService.parsePayload(null), isEmpty);
    });

    test('malformed payloads are ignored, not thrown', () {
      expect(LocalNotificationService.parsePayload('{not json'), isEmpty);
      expect(LocalNotificationService.parsePayload('[]'), isEmpty);
    });

    test('stringifies non-string values', () {
      final encoded = LocalNotificationService.encodePayload({'count': 3});
      expect(LocalNotificationService.parsePayload(encoded)['count'], '3');
    });
  });
}
