import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fashionista/core/utils/scheduling/reservation_key.dart';
import 'package:fashionista/data/models/bookings/booking_client_model.dart';
import 'package:fashionista/data/models/bookings/booking_model.dart';
import 'package:fashionista/data/models/bookings/booking_notification.dart';
import 'package:fashionista/data/models/notification/notification_model.dart';
import 'package:fashionista/data/models/bookings/booking_status.dart';
import 'package:fashionista/data/models/bookings/slot_reservation_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BookingStatus', () {
    test('uses snake_case wire values', () {
      expect(BookingStatus.noShow.value, 'no_show');
      expect(BookingStatus.pending.value, 'pending');
      expect(BookingStatus.confirmed.value, 'confirmed');
    });

    test('parses wire values back to the enum', () {
      expect(BookingStatusX.fromValue('no_show'), BookingStatus.noShow);
      expect(BookingStatusX.fromValue('noShow'), BookingStatus.noShow);
      expect(BookingStatusX.fromValue('confirmed'), BookingStatus.confirmed);
      expect(BookingStatusX.fromValue(null), BookingStatus.pending);
    });

    test('knows which statuses hold a slot', () {
      expect(BookingStatus.pending.holdsSlot, isTrue);
      expect(BookingStatus.confirmed.holdsSlot, isTrue);
      expect(BookingStatus.declined.holdsSlot, isFalse);
      expect(BookingStatus.cancelled.holdsSlot, isFalse);
      expect(BookingStatus.completed.holdsSlot, isFalse);
      expect(BookingStatus.noShow.holdsSlot, isFalse);
    });
  });

  group('ReservationKey', () {
    test('is deterministic for the same designer, date and time', () {
      final first = ReservationKey.forSlot(
        designerId: 'designer_123',
        date: '2026-11-16',
        startTime: '08:30',
      );
      final second = ReservationKey.forSlot(
        designerId: 'designer_123',
        date: '2026-11-16',
        startTime: '08:30',
      );

      expect(first, second);
      expect(first, 'designer_123_20261116_0830');
    });

    test('differs across slots and designers', () {
      final eight = ReservationKey.forSlot(
        designerId: 'designer_123',
        date: '2026-11-16',
        startTime: '08:00',
      );
      final eightThirty = ReservationKey.forSlot(
        designerId: 'designer_123',
        date: '2026-11-16',
        startTime: '08:30',
      );
      final otherDesigner = ReservationKey.forSlot(
        designerId: 'designer_999',
        date: '2026-11-16',
        startTime: '08:00',
      );

      expect(eight, isNot(eightThirty));
      expect(eight, isNot(otherDesigner));
    });
  });

  group('Booking serialization', () {
    Booking booking() => Booking(
      uid: 'booking_1',
      designerId: 'designer_1',
      userId: 'user_1',
      clientId: 'client_1',
      date: '2026-11-16',
      dayOfWeek: DateTime.monday,
      startAt: DateTime.utc(2026, 11, 16, 8, 30),
      endAt: DateTime.utc(2026, 11, 16, 9, 0),
      startTime: '08:30',
      endTime: '09:00',
      timezone: 'Africa/Accra',
      durationMinutes: 30,
      status: BookingStatus.pending,
      notes: 'Wedding outfit',
    );

    test('serializes times as Firestore timestamps', () {
      final json = booking().toJson();

      expect(json['start_at'], isA<Timestamp>());
      expect(json['end_at'], isA<Timestamp>());
      expect(json['designer_id'], 'designer_1');
      expect(json['day_of_week'], DateTime.monday);
      expect(json['status'], 'pending');
    });

    test('round-trips through Firestore timestamps', () {
      final json = booking().toJson();
      final restored = Booking.fromJson(json);

      expect(restored.startAt, DateTime.utc(2026, 11, 16, 8, 30));
      expect(restored.endAt, DateTime.utc(2026, 11, 16, 9, 0));
      expect(restored.startTime, '08:30');
      expect(restored.durationMinutes, 30);
      expect(restored.status, BookingStatus.pending);
    });

    test('reads legacy epoch integers', () {
      final restored = Booking.fromJson({
        'designer_id': 'designer_1',
        'user_id': 'user_1',
        'date': '2026-11-16',
        'day_of_week': 1,
        'start_time': '08:30',
        'end_time': '09:00',
        'start_at': DateTime.utc(2026, 11, 16, 8, 30).millisecondsSinceEpoch,
        'status': 'no_show',
      });

      expect(restored.startAt, isNotNull);
      expect(restored.status, BookingStatus.noShow);
    });
  });

  group('BookingClient snapshot', () {
    test('round-trips id, name, avatar and mobile number', () {
      final booking = Booking(
        uid: 'booking_1',
        designerId: 'designer_1',
        userId: 'user_1',
        clientId: 'client_1',
        date: '2026-11-16',
        dayOfWeek: DateTime.monday,
        startTime: '08:30',
        endTime: '09:00',
        client: const BookingClient(
          id: 'client_1',
          name: 'Ama Mensah',
          avatar: 'https://cdn.example.com/ama.jpg',
          mobileNumber: '+233201234567',
        ),
      );

      final restored = Booking.fromJson(booking.toJson());

      expect(restored.client, isNotNull);
      expect(restored.client!.id, 'client_1');
      expect(restored.client!.name, 'Ama Mensah');
      expect(restored.client!.avatar, 'https://cdn.example.com/ama.jpg');
      expect(restored.client!.mobileNumber, '+233201234567');
      expect(restored.client!.displayName, 'Ama Mensah');
      expect(restored.client!.hasAvatar, isTrue);
    });

    test('serializes under the "client" key', () {
      final booking = Booking(
        designerId: 'designer_1',
        userId: 'user_1',
        date: '2026-11-16',
        dayOfWeek: 1,
        startTime: '08:30',
        endTime: '09:00',
        client: const BookingClient(id: 'c1', name: 'Kofi'),
      );

      final json = booking.toJson();
      expect(json['client'], isA<Map<String, dynamic>>());
      expect((json['client'] as Map)['id'], 'c1');
      expect((json['client'] as Map)['name'], 'Kofi');
    });

    test('falls back gracefully when the snapshot is missing', () {
      final restored = Booking.fromJson({
        'designer_id': 'designer_1',
        'user_id': 'user_1',
        'date': '2026-11-16',
        'day_of_week': 1,
        'start_time': '08:30',
        'end_time': '09:00',
      });

      expect(restored.client, isNull);
      expect(const BookingClient().displayName, 'Client');
      expect(const BookingClient().hasAvatar, isFalse);
    });

    test('is included in equality', () {
      Booking base(BookingClient client) => Booking(
        designerId: 'designer_1',
        userId: 'user_1',
        date: '2026-11-16',
        dayOfWeek: 1,
        startTime: '08:30',
        endTime: '09:00',
        client: client,
      );

      expect(
        base(const BookingClient(name: 'A')),
        isNot(base(const BookingClient(name: 'B'))),
      );
    });
  });

  group('buildBookingNotification', () {
    NotificationModel build() {
      return buildBookingNotification(
        notificationId: 'notif_1',
        bookingId: 'booking_1',
        designerId: 'designer_1',
        userId: 'user_1',
        client: const BookingClient(
          id: 'client_1',
          name: 'Ama Mensah',
          avatar: 'https://cdn.example.com/ama.jpg',
          mobileNumber: '+233201234567',
        ),
        date: '2026-11-16',
        startTime: '08:30',
        createdAt: DateTime.utc(2026, 11, 1, 9),
      );
    }

    test('targets the designer and is authored by the client', () {
      final notification = build();

      expect(notification.to, 'designer_1');
      expect(notification.from, 'user_1');
      expect(notification.uid, 'notif_1');
      expect(notification.refId, 'booking_1');
      expect(notification.refType, 'booking');
      expect(notification.type, 'appointment');
      expect(notification.status, 'new');
    });

    test('describes who booked and when', () {
      final notification = build();

      expect(notification.title, 'New appointment request');
      expect(notification.description, contains('Ama Mensah'));
      expect(notification.description, contains('2026-11-16'));
      expect(notification.description, contains('8:30 AM'));
    });

    // Regression: the client and the server must agree on the document id,
    // otherwise both write a notification and the designer sees it twice.
    test('derives the id the server uses for its idempotency key', () {
      expect(
        buildBookingNotificationId('booking_1'),
        'booking__requested__booking_1',
      );
      expect(
        buildBookingNotificationId('abc123XYZ'),
        'booking__requested__abc123XYZ',
      );
    });

    test('carries the client snapshot as the author', () {
      final author = build().author!;

      expect(author.uid, 'user_1');
      expect(author.name, 'Ama Mensah');
      expect(author.avatar, 'https://cdn.example.com/ama.jpg');
      expect(author.mobileNumber, '+233201234567');
    });

    test('serializes with epoch millis and snake_case keys', () {
      final json = build().toJson();

      expect(
        json['created_at'],
        DateTime.utc(2026, 11, 1, 9).millisecondsSinceEpoch,
      );
      expect(json['ref_type'], 'booking');
      expect(json['to'], 'designer_1');
      expect(json['from'], 'user_1');
    });

    test('falls back to "Client" when the name is empty', () {
      final notification = buildBookingNotification(
        notificationId: 'n',
        bookingId: 'b',
        designerId: 'd',
        userId: 'u',
        client: const BookingClient(id: 'c'),
        date: '2026-11-16',
        startTime: '08:00',
        createdAt: DateTime.utc(2026, 11, 1),
      );

      expect(notification.description, startsWith('Client requested'));
    });
  });

  group('SlotReservation', () {
    test('is active while reserved and before expiry', () {
      final reservation = SlotReservation(
        designerId: 'designer_1',
        userId: 'user_1',
        bookingId: 'booking_1',
        status: SlotReservationStatus.reserved,
        expiresAt: DateTime.utc(2026, 11, 16, 10),
      );

      expect(reservation.isActiveAt(DateTime.utc(2026, 11, 16, 9, 59)), isTrue);
    });

    test('is reclaimable after expiry', () {
      final reservation = SlotReservation(
        designerId: 'designer_1',
        status: SlotReservationStatus.reserved,
        expiresAt: DateTime.utc(2026, 11, 16, 10),
      );

      expect(
        reservation.isActiveAt(DateTime.utc(2026, 11, 16, 10, 1)),
        isFalse,
      );
    });

    test('released reservations are never active', () {
      final reservation = SlotReservation(
        designerId: 'designer_1',
        status: SlotReservationStatus.released,
        expiresAt: DateTime.utc(2026, 11, 16, 23),
      );

      expect(reservation.isActiveAt(DateTime.utc(2026, 11, 16, 9)), isFalse);
    });
  });
}
