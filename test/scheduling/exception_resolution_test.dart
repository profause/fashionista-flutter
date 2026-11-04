import 'package:fashionista/core/utils/scheduling/slot_generator.dart';
import 'package:fashionista/data/models/availability/availability_exception_model.dart';
import 'package:fashionista/data/models/availability/availability_session_model.dart';
import 'package:fashionista/data/models/availability/designer_availability_model.dart';
import 'package:flutter_test/flutter_test.dart';

AvailabilitySession session(String start, String end) =>
    AvailabilitySession(startTime: start, endTime: end);

DesignerAvailability weekly() => DesignerAvailability(
  dayOfWeek: DateTime.monday,
  isAvailable: true,
  appointmentDurationMinutes: 30,
  sessions: [session('08:00', '10:00'), session('12:00', '13:00')],
);

void main() {
  group('Exception resolution', () {
    test('uses weekly availability when no exception exists', () {
      final effective = SlotSchedulingService.resolveEffective(
        weekly: weekly(),
      );

      expect(effective.source, AvailabilitySource.weekly);
      expect(effective.sessions.length, 2);
      expect(effective.durationMinutes, 30);
      expect(effective.isBookable, isTrue);
    });

    test('unavailable exception overrides an enabled weekday', () {
      final effective = SlotSchedulingService.resolveEffective(
        weekly: weekly(),
        exception: AvailabilityException.unavailable(
          date: '2026-11-16',
          reason: 'Personal commitments',
        ),
      );

      expect(effective.source, AvailabilitySource.exceptionUnavailable);
      expect(effective.sessions, isEmpty);
      expect(effective.isBookable, isFalse);
    });

    test('custom exception replaces the weekly sessions and duration', () {
      final effective = SlotSchedulingService.resolveEffective(
        weekly: weekly(),
        exception: AvailabilityException.custom(
          date: '2026-11-18',
          sessions: [session('10:00', '14:00')],
          appointmentDurationMinutes: 60,
        ),
      );

      expect(effective.source, AvailabilitySource.exceptionCustom);
      expect(effective.sessions.length, 1);
      expect(effective.durationMinutes, 60);

      final slots = SlotSchedulingService.generateSlots(
        sessions: effective.sessions,
        durationMinutes: effective.durationMinutes,
      );
      expect(slots.map((s) => s.startTime), ['10:00', '11:00', '12:00', '13:00']);
    });

    test('custom exception inherits the weekday duration when omitted', () {
      final effective = SlotSchedulingService.resolveEffective(
        weekly: weekly(),
        exception: AvailabilityException.custom(
          date: '2026-11-18',
          sessions: [session('10:00', '12:00')],
        ),
      );

      expect(effective.durationMinutes, 30);
    });

    test('disabled weekday yields no effective sessions', () {
      final effective = SlotSchedulingService.resolveEffective(
        weekly: weekly().copyWith(isAvailable: false),
      );

      expect(effective.isBookable, isFalse);
      expect(effective.sessions, isEmpty);
    });

    test('missing weekly document yields no effective sessions', () {
      final effective = SlotSchedulingService.resolveEffective(weekly: null);

      expect(effective.isBookable, isFalse);
    });

    test('exception wins even when the weekday is disabled', () {
      final effective = SlotSchedulingService.resolveEffective(
        weekly: weekly().copyWith(isAvailable: false),
        exception: AvailabilityException.custom(
          date: '2026-11-18',
          sessions: [session('15:00', '16:00')],
        ),
      );

      expect(effective.source, AvailabilitySource.exceptionCustom);
      expect(effective.isBookable, isTrue);
    });
  });
}
