import 'package:fashionista/data/models/bookings/booking_client_model.dart';
import 'package:fashionista/data/models/bookings/booking_model.dart';
import 'package:fashionista/data/models/bookings/booking_status.dart';
import 'package:fashionista/data/services/local/appointment_reminder_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

const String designerId = 'designer_1';
const String clientId = 'client_1';

final DateTime now = DateTime(2026, 11, 6, 9, 0);

Booking booking({
  String uid = 'booking_1',
  BookingStatus status = BookingStatus.confirmed,
  DateTime? startAt,
  String? designer,
  String? user,
  String? clientName,
}) {
  final start = startAt ?? now.add(const Duration(hours: 3));
  return Booking(
    uid: uid,
    designerId: designer ?? designerId,
    userId: user ?? clientId,
    date: DateFormat('yyyy-MM-dd').format(start),
    dayOfWeek: start.weekday,
    startAt: start,
    endAt: start.add(const Duration(minutes: 60)),
    startTime: '12:00',
    endTime: '13:00',
    status: status,
    client: clientName == null
        ? null
        : BookingClient(name: clientName, id: 'c1'),
  );
}

class RecordingScheduler {
  final List<
    ({
      int id,
      String title,
      String body,
      DateTime scheduledDate,
      Map<String, dynamic> data,
    })
  >
  scheduled = [];
  final List<int> cancelled = [];

  AppointmentReminderService build({
    bool enabled = true,
    DateTime Function()? clock,
    int? preferenceReads,
  }) {
    return AppointmentReminderService(
      now: clock ?? () => now,
      remindersEnabled: () async {
        if (preferenceReads != null) return enabled;
        return enabled;
      },
      schedule:
          ({
            required int id,
            required String title,
            required String body,
            required DateTime scheduledDate,
            required Map<String, dynamic> data,
          }) async {
            scheduled.add((
              id: id,
              title: title,
              body: body,
              scheduledDate: scheduledDate,
              data: data,
            ));
          },
      cancel: (id) async => cancelled.add(id),
    );
  }
}

void main() {
  group('notification ids', () {
    test('are stable for the same booking', () {
      expect(
        AppointmentReminderService.notificationIdFor('booking_1'),
        AppointmentReminderService.notificationIdFor('booking_1'),
      );
    });

    test('are positive 31-bit values that differ per booking', () {
      final a = AppointmentReminderService.notificationIdFor('booking_1');
      final b = AppointmentReminderService.notificationIdFor('booking_2');

      expect(a, greaterThanOrEqualTo(0));
      expect(a, lessThan(0x80000000));
      expect(a, isNot(b));
    });
  });

  group('syncBooking', () {
    test(
      'schedules five minutes before a confirmed, future appointment',
      () async {
        final recorder = RecordingScheduler();
        final service = recorder.build();
        final appointment = booking(startAt: now.add(const Duration(hours: 2)));

        final scheduled = await service.syncBooking(
          appointment,
          currentUserId: designerId,
        );

        expect(scheduled, isTrue);
        final entry = recorder.scheduled.single;
        expect(
          entry.scheduledDate,
          appointment.startAt!.toLocal().subtract(
            AppointmentReminderService.leadTime,
          ),
        );
        expect(entry.title, 'Appointment reminder');
        expect(
          entry.id,
          AppointmentReminderService.notificationIdFor('booking_1'),
        );
        // The payload routes a tap back to the right bookings list.
        expect(entry.data['type'], 'appointment');
        expect(entry.data['booking_id'], 'booking_1');
        expect(entry.data['designer_id'], designerId);
        expect(entry.data['audience'], 'designer');
        expect(recorder.cancelled, isEmpty);
      },
    );

    test('uses the client audience for the client device', () async {
      final recorder = RecordingScheduler();
      final service = recorder.build();

      await service.syncBooking(booking(), currentUserId: clientId);

      expect(recorder.scheduled.single.data['audience'], 'client');
    });

    test(
      'names the client in the body when the appointment is today',
      () async {
        final recorder = RecordingScheduler();
        final service = recorder.build();

        await service.syncBooking(
          booking(
            startAt: now.add(const Duration(hours: 1)),
            clientName: 'Ava',
          ),
          currentUserId: designerId,
        );

        expect(recorder.scheduled.single.body, contains('with Ava'));
        expect(recorder.scheduled.single.body, contains('starts at'));
      },
    );

    test('does not name the client on the client device', () async {
      final recorder = RecordingScheduler();
      final service = recorder.build();

      await service.syncBooking(
        booking(startAt: now.add(const Duration(hours: 1)), clientName: 'Ava'),
        currentUserId: clientId,
      );

      expect(recorder.scheduled.single.body, isNot(contains('with Ava')));
      expect(recorder.scheduled.single.body, contains('your appointment'));
    });

    test('mentions the date for a later appointment', () async {
      final recorder = RecordingScheduler();
      final service = recorder.build();

      await service.syncBooking(
        booking(startAt: now.add(const Duration(days: 2))),
        currentUserId: designerId,
      );

      expect(recorder.scheduled.single.body, contains('is on'));
    });

    test('cancels instead of scheduling when the preference is off', () async {
      final recorder = RecordingScheduler();
      final service = recorder.build(enabled: false);

      final scheduled = await service.syncBooking(
        booking(),
        currentUserId: designerId,
      );

      expect(scheduled, isFalse);
      expect(recorder.scheduled, isEmpty);
      expect(
        recorder.cancelled.single,
        AppointmentReminderService.notificationIdFor('booking_1'),
      );
    });

    test('does nothing for a booking that is not confirmed', () async {
      for (final status in [
        BookingStatus.pending,
        BookingStatus.cancelled,
        BookingStatus.declined,
        BookingStatus.completed,
        BookingStatus.noShow,
      ]) {
        final recorder = RecordingScheduler();
        final service = recorder.build();

        final scheduled = await service.syncBooking(
          booking(status: status),
          currentUserId: designerId,
        );

        expect(scheduled, isFalse, reason: '$status must not schedule');
        expect(recorder.scheduled, isEmpty, reason: '$status');
        expect(recorder.cancelled, hasLength(1), reason: '$status');
      }
    });

    test('skips an appointment that starts within the lead time', () async {
      final recorder = RecordingScheduler();
      final service = recorder.build();

      final scheduled = await service.syncBooking(
        booking(startAt: now.add(const Duration(minutes: 3))),
        currentUserId: designerId,
      );

      expect(scheduled, isFalse);
      expect(recorder.scheduled, isEmpty);
    });

    test('skips bookings the user is not part of', () async {
      final recorder = RecordingScheduler();
      final service = recorder.build();

      final scheduled = await service.syncBooking(
        booking(),
        currentUserId: 'someone_else',
      );

      expect(scheduled, isFalse);
      expect(recorder.scheduled, isEmpty);
    });

    test(
      'a re-confirmed appointment replaces the same notification id',
      () async {
        final recorder = RecordingScheduler();
        final service = recorder.build();

        await service.syncBooking(booking(), currentUserId: designerId);
        await service.syncBooking(booking(), currentUserId: designerId);

        expect(recorder.scheduled, hasLength(2));
        expect(
          recorder.scheduled.map((entry) => entry.id).toSet(),
          hasLength(1),
        );
      },
    );
  });

  group('unknown preference', () {
    AppointmentReminderService throwingPreference(
      List<int> scheduledIds,
      List<int> cancelledIds,
    ) {
      return AppointmentReminderService(
        now: () => now,
        remindersEnabled: () async => throw StateError('offline'),
        schedule:
            ({
              required int id,
              required String title,
              required String body,
              required DateTime scheduledDate,
              required Map<String, dynamic> data,
            }) async {
              scheduledIds.add(id);
            },
        cancel: (id) async => cancelledIds.add(id),
      );
    }

    test(
      'schedules nothing and cancels nothing when it cannot be read',
      () async {
        final scheduledIds = <int>[];
        final cancelledIds = <int>[];
        final service = throwingPreference(scheduledIds, cancelledIds);

        final scheduled = await service.syncBooking(
          booking(),
          currentUserId: designerId,
        );

        expect(scheduled, isFalse);
        expect(scheduledIds, isEmpty);
        // An offline blip must not wipe a reminder the user already has.
        expect(cancelledIds, isEmpty);
      },
    );

    test('syncAll leaves every reminder untouched', () async {
      final scheduledIds = <int>[];
      final cancelledIds = <int>[];
      final service = throwingPreference(scheduledIds, cancelledIds);

      await service.syncAll([
        booking(uid: 'b1'),
        booking(uid: 'b2', status: BookingStatus.cancelled),
      ], currentUserId: designerId);

      expect(scheduledIds, isEmpty);
      expect(cancelledIds, isEmpty);
    });
  });

  group('syncAll', () {
    test(
      'reads the preference once for a list of future appointments',
      () async {
        var reads = 0;
        final scheduledIds = <int>[];

        final service = AppointmentReminderService(
          now: () => now,
          remindersEnabled: () async {
            reads += 1;
            return true;
          },
          schedule:
              ({
                required int id,
                required String title,
                required String body,
                required DateTime scheduledDate,
                required Map<String, dynamic> data,
              }) async {
                scheduledIds.add(id);
              },
          cancel: (id) async {},
        );

        await service.syncAll([
          booking(uid: 'b1'),
          booking(uid: 'b2'),
          booking(uid: 'b3'),
        ], currentUserId: designerId);

        expect(reads, 1);
        expect(scheduledIds, hasLength(3));
      },
    );

    test(
      'does not read the preference when nothing can be scheduled',
      () async {
        var reads = 0;

        final service = AppointmentReminderService(
          now: () => now,
          remindersEnabled: () async {
            reads += 1;
            return true;
          },
          schedule:
              ({
                required int id,
                required String title,
                required String body,
                required DateTime scheduledDate,
                required Map<String, dynamic> data,
              }) async {},
          cancel: (id) async {},
        );

        await service.syncAll([
          booking(uid: 'b1', status: BookingStatus.cancelled),
          booking(uid: 'b2', status: BookingStatus.completed),
        ], currentUserId: designerId);

        expect(reads, 0);
      },
    );

    test(
      'cancels reminders for appointments that are no longer confirmed',
      () async {
        final recorder = RecordingScheduler();
        final service = recorder.build();

        await service.syncAll([
          booking(uid: 'b1', status: BookingStatus.cancelled),
          booking(uid: 'b2'),
        ], currentUserId: designerId);

        expect(recorder.cancelled, [
          AppointmentReminderService.notificationIdFor('b1'),
        ]);
        expect(recorder.scheduled.single.data['booking_id'], 'b2');
      },
    );

    test('ignores an empty user id', () async {
      final recorder = RecordingScheduler();
      final service = recorder.build();

      await service.syncAll([booking()], currentUserId: '');

      expect(recorder.scheduled, isEmpty);
      expect(recorder.cancelled, isEmpty);
    });
  });

  test('cancelFor targets the booking reminder id', () async {
    final recorder = RecordingScheduler();
    final service = recorder.build();

    await service.cancelFor('booking_9');

    expect(
      recorder.cancelled.single,
      AppointmentReminderService.notificationIdFor('booking_9'),
    );
  });
}
