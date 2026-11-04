import 'package:fashionista/core/utils/scheduling/slot_generator.dart';
import 'package:fashionista/core/utils/scheduling/time_of_day_x.dart';
import 'package:fashionista/data/models/availability/availability_session_model.dart';
import 'package:fashionista/data/models/availability/designer_availability_model.dart';
import 'package:flutter_test/flutter_test.dart';

AvailabilitySession session(String start, String end) =>
    AvailabilitySession(startTime: start, endTime: end);

DesignerAvailability buildDay({
  required List<AvailabilitySession> sessions,
  int durationMinutes = 30,
  bool isAvailable = true,
  int dayOfWeek = DateTime.monday,
}) {
  return DesignerAvailability(
    dayOfWeek: dayOfWeek,
    isAvailable: isAvailable,
    appointmentDurationMinutes: durationMinutes,
    sessions: sessions,
  );
}

void main() {
  group('TimeOfDayX', () {
    test('parses and formats valid 24-hour times', () {
      expect(TimeOfDayX.toMinutes('00:00'), 0);
      expect(TimeOfDayX.toMinutes('08:30'), 510);
      expect(TimeOfDayX.toMinutes('23:59'), 1439);
      expect(TimeOfDayX.fromMinutes(510), '08:30');
      expect(TimeOfDayX.fromMinutes(1439), '23:59');
    });

    test('rejects malformed times', () {
      expect(TimeOfDayX.isValid('8:00'), isFalse);
      expect(TimeOfDayX.isValid('24:00'), isFalse);
      expect(TimeOfDayX.isValid('08:60'), isFalse);
      expect(TimeOfDayX.isValid(''), isFalse);
      expect(TimeOfDayX.isValid(null), isFalse);
      expect(TimeOfDayX.tryToMinutes('nope'), isNull);
    });

    test('normalises loose input', () {
      expect(TimeOfDayX.normalize('8:00'), '08:00');
      expect(TimeOfDayX.normalize('0800'), '08:00');
      expect(TimeOfDayX.normalize('930'), '09:30');
      expect(TimeOfDayX.normalize('bad'), isNull);
    });

    test('renders 12-hour display labels', () {
      expect(TimeOfDayX.toDisplay('08:00'), '8:00 AM');
      expect(TimeOfDayX.toDisplay('00:00'), '12:00 AM');
      expect(TimeOfDayX.toDisplay('12:30'), '12:30 PM');
      expect(TimeOfDayX.toDisplay('13:05'), '1:05 PM');
    });
  });

  group('SlotSchedulingService.generateSlots', () {
    test('generates 30-minute slots from one session', () {
      final slots = SlotSchedulingService.generateSlots(
        sessions: [session('08:00', '10:00')],
        durationMinutes: 30,
      );

      expect(slots.map((s) => '${s.startTime}-${s.endTime}'), [
        '08:00-08:30',
        '08:30-09:00',
        '09:00-09:30',
        '09:30-10:00',
      ]);
    });

    test('generates 60-minute slots', () {
      final slots = SlotSchedulingService.generateSlots(
        sessions: [session('09:00', '12:00')],
        durationMinutes: 60,
      );

      expect(slots.map((s) => s.startTime), ['09:00', '10:00', '11:00']);
    });

    test('drops the incomplete remainder for a 45-minute duration', () {
      final slots = SlotSchedulingService.generateSlots(
        sessions: [session('08:00', '10:00')],
        durationMinutes: 45,
      );

      expect(slots.map((s) => '${s.startTime}-${s.endTime}'), [
        '08:00-08:45',
        '08:45-09:30',
      ]);
    });

    test('handles multiple sessions in chronological order', () {
      final slots = SlotSchedulingService.generateSlots(
        sessions: [session('12:00', '13:00'), session('08:00', '10:00')],
        durationMinutes: 30,
      );

      expect(slots.map((s) => s.startTime), [
        '08:00',
        '08:30',
        '09:00',
        '09:30',
        '12:00',
        '12:30',
      ]);
    });

    test('returns an empty list when there are no sessions', () {
      expect(
        SlotSchedulingService.generateSlots(
          sessions: const [],
          durationMinutes: 30,
        ),
        isEmpty,
      );
    });

    test('returns an empty list for a non-positive duration', () {
      expect(
        SlotSchedulingService.generateSlots(
          sessions: [session('08:00', '10:00')],
          durationMinutes: 0,
        ),
        isEmpty,
      );
    });

    test('skips invalid and reversed sessions', () {
      final slots = SlotSchedulingService.generateSlots(
        sessions: [
          session('not-a-time', '10:00'),
          session('10:00', '09:00'),
          session('08:00', '09:00'),
        ],
        durationMinutes: 30,
      );

      expect(slots.map((s) => s.startTime), ['08:00', '08:30']);
    });

    test('marks booked start times as unavailable', () {
      final slots = SlotSchedulingService.generateSlotsMarkingBooked(
        sessions: [session('08:00', '09:00')],
        durationMinutes: 30,
        bookedStartTimes: {'08:30'},
      );

      expect(slots.first.isAvailable, isTrue);
      expect(slots.last.isAvailable, isFalse);
    });

    test('drops slots that already started today', () {
      final slots = SlotSchedulingService.buildDaySlots(
        weekly: buildDay(sessions: [session('08:00', '10:00')]),
        now: DateTime(2026, 11, 16, 8, 45),
      );

      expect(slots.map((s) => s.startTime), ['09:00', '09:30']);
    });

    test('keeps all slots when no "now" is supplied', () {
      final slots = SlotSchedulingService.buildDaySlots(
        weekly: buildDay(sessions: [session('08:00', '10:00')]),
      );

      expect(slots.length, 4);
    });
  });
}
