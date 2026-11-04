import 'package:fashionista/core/utils/scheduling/slot_generator.dart';
import 'package:fashionista/data/models/availability/availability_session_model.dart';
import 'package:flutter_test/flutter_test.dart';

AvailabilitySession session(String start, String end) =>
    AvailabilitySession(startTime: start, endTime: end);

List<String> problems(List<AvailabilitySession> sessions, int duration) {
  return SlotSchedulingService.validateSchedule(
    sessions: sessions,
    durationMinutes: duration,
  );
}

void main() {
  group('SlotSchedulingService.validateSchedule', () {
    test('accepts a valid multi-session day', () {
      expect(
        problems([
          session('08:00', '10:00'),
          session('12:00', '13:00'),
        ], 30),
        isEmpty,
      );
    });

    test('rejects a session without a start time', () {
      expect(problems([session('', '10:00')], 30), isNotEmpty);
    });

    test('rejects a session without an end time', () {
      expect(problems([session('08:00', '')], 30), isNotEmpty);
    });

    test('rejects an end time equal to the start time', () {
      expect(problems([session('08:00', '08:00')], 30), isNotEmpty);
    });

    test('rejects an end time earlier than the start time', () {
      expect(problems([session('10:00', '09:00')], 30), isNotEmpty);
    });

    test('rejects invalid time formats', () {
      expect(problems([session('8:00', '10:00')], 30), isNotEmpty);
      expect(problems([session('08:00', '25:00')], 30), isNotEmpty);
    });

    test('rejects overlapping sessions', () {
      final result = problems([
        session('08:00', '10:00'),
        session('09:30', '11:00'),
      ], 30);

      expect(result, isNotEmpty);
      expect(result.join(' ').toLowerCase(), contains('overlap'));
    });

    test('rejects duplicate sessions', () {
      final result = problems([
        session('08:00', '10:00'),
        session('08:00', '10:00'),
      ], 30);

      expect(result, isNotEmpty);
      expect(result.join(' ').toLowerCase(), contains('duplicate'));
    });

    test('rejects a session shorter than the duration', () {
      final result = problems([session('08:00', '08:15')], 30);

      expect(result, isNotEmpty);
      expect(result.join(' ').toLowerCase(), contains('shorter'));
    });

    test('rejects an empty day', () {
      expect(problems([], 30), isNotEmpty);
    });

    test('rejects a non-positive duration', () {
      expect(problems([session('08:00', '10:00')], 0), isNotEmpty);
    });

    test('accepts a session exactly as long as the duration', () {
      expect(problems([session('08:00', '08:30')], 30), isEmpty);
    });

    test('sorts sessions chronologically', () {
      final sorted = SlotSchedulingService.sortSessions([
        session('12:00', '13:00'),
        session('08:00', '10:00'),
      ]);

      expect(sorted.first.startTime, '08:00');
      expect(sorted.last.startTime, '12:00');
    });
  });
}
