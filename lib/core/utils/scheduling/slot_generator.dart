import 'package:fashionista/core/utils/scheduling/time_of_day_x.dart';
import 'package:fashionista/data/models/availability/availability_exception_model.dart';
import 'package:fashionista/data/models/availability/availability_session_model.dart';
import 'package:fashionista/data/models/availability/available_slot_model.dart';
import 'package:fashionista/data/models/availability/designer_availability_model.dart';

/// Pure scheduling rules: slot generation, schedule validation and
/// date-exception resolution.
///
/// Free of Flutter and Firestore so it can be unit tested directly and reused
/// by the repository, the designer preview and the booking transaction.
class SlotSchedulingService {
  SlotSchedulingService._();

  /// Generates contiguous appointment slots for [sessions].
  ///
  /// Slots that would run past the end of a session are discarded, so a
  /// 45-minute duration over `08:00-10:00` yields `08:00` and `08:45` only.
  /// The result is chronological and de-duplicated.
  static List<AvailableSlot> generateSlots({
    required List<AvailabilitySession> sessions,
    required int durationMinutes,
  }) {
    if (durationMinutes <= 0 || sessions.isEmpty) return const [];

    final slots = <AvailableSlot>[];

    for (final session in sessions) {
      final start = TimeOfDayX.tryToMinutes(session.startTime);
      final end = TimeOfDayX.tryToMinutes(session.endTime);
      if (start == null || end == null || end <= start) continue;

      var cursor = start;
      while (cursor + durationMinutes <= end) {
        slots.add(
          AvailableSlot(
            startTime: TimeOfDayX.fromMinutes(cursor),
            endTime: TimeOfDayX.fromMinutes(cursor + durationMinutes),
          ),
        );
        cursor += durationMinutes;
      }
    }

    slots.sort((a, b) => a.startMinutes.compareTo(b.startMinutes));

    final seen = <String>{};
    return slots.where((slot) => seen.add(slot.key)).toList();
  }

  /// Generates slots and marks the ones whose start time already has an active
  /// booking as unavailable.
  static List<AvailableSlot> generateSlotsMarkingBooked({
    required List<AvailabilitySession> sessions,
    required int durationMinutes,
    required Set<String> bookedStartTimes,
  }) {
    return generateSlots(sessions: sessions, durationMinutes: durationMinutes)
        .map(
          (slot) => bookedStartTimes.contains(slot.startTime)
              ? slot.copyWith(isAvailable: false)
              : slot,
        )
        .toList();
  }

  /// Validates a day's schedule.
  ///
  /// Returns an empty list when valid, otherwise one human readable message
  /// per problem found.
  static List<String> validateSchedule({
    required List<AvailabilitySession> sessions,
    required int durationMinutes,
  }) {
    final problems = <String>[];

    if (durationMinutes <= 0) {
      problems.add('Appointment duration must be greater than zero.');
    }

    if (sessions.isEmpty) {
      problems.add('Add at least one availability session.');
    }

    final seenRanges = <String>{};
    final parsed = <_Range>[];

    for (final session in sessions) {
      if (session.startTime.trim().isEmpty) {
        problems.add('Every session needs a start time.');
        continue;
      }
      if (session.endTime.trim().isEmpty) {
        problems.add('Every session needs an end time.');
        continue;
      }

      final start = TimeOfDayX.tryToMinutes(session.startTime);
      final end = TimeOfDayX.tryToMinutes(session.endTime);

      if (start == null || end == null) {
        problems.add('Use 24-hour HH:mm times for every session.');
        continue;
      }

      if (end <= start) {
        problems.add(
          'End time must be after start time '
          '(${session.startTime} - ${session.endTime}).',
        );
        continue;
      }

      if (durationMinutes > 0 && end - start < durationMinutes) {
        problems.add(
          'Session ${session.startTime} - ${session.endTime} is shorter than '
          'the appointment duration.',
        );
      }

      if (!seenRanges.add('$start-$end')) {
        problems.add(
          'Duplicate session ${session.startTime} - ${session.endTime}.',
        );
        continue;
      }

      parsed.add(_Range(start: start, end: end, raw: session));
    }

    parsed.sort((a, b) => a.start.compareTo(b.start));
    for (var i = 1; i < parsed.length; i++) {
      if (parsed[i].start < parsed[i - 1].end) {
        problems.add(
          'Sessions ${parsed[i - 1].raw.startTime} - ${parsed[i - 1].raw.endTime} '
          'and ${parsed[i].raw.startTime} - ${parsed[i].raw.endTime} overlap.',
        );
      }
    }

    return problems;
  }

  /// Returns a copy of [sessions] sorted by start time.
  static List<AvailabilitySession> sortSessions(
    List<AvailabilitySession> sessions,
  ) {
    final sorted = List<AvailabilitySession>.from(sessions);
    sorted.sort((a, b) {
      final aStart = TimeOfDayX.tryToMinutes(a.startTime) ?? 0;
      final bStart = TimeOfDayX.tryToMinutes(b.startTime) ?? 0;
      return aStart.compareTo(bStart);
    });
    return sorted;
  }

  /// Resolves the sessions and duration that apply on a date.
  ///
  /// A date-specific exception always wins over the recurring weekly rules:
  /// `unavailable` yields no sessions, `custom` yields the exception's own
  /// sessions and (optional) duration.
  static EffectiveAvailability resolveEffective({
    required DesignerAvailability? weekly,
    AvailabilityException? exception,
  }) {
    if (exception != null) {
      if (exception.isUnavailable) {
        return const EffectiveAvailability(
          sessions: [],
          durationMinutes: 0,
          source: AvailabilitySource.exceptionUnavailable,
        );
      }
      if (exception.isCustom) {
        return EffectiveAvailability(
          sessions: sortSessions(exception.sessions),
          durationMinutes: (exception.appointmentDurationMinutes ??
                  weekly?.appointmentDurationMinutes ??
                  0)
              .clamp(0, 24 * 60),
          source: AvailabilitySource.exceptionCustom,
        );
      }
    }

    if (weekly == null || !weekly.isAvailable) {
      return const EffectiveAvailability(
        sessions: [],
        durationMinutes: 0,
        source: AvailabilitySource.unavailable,
      );
    }

    return EffectiveAvailability(
      sessions: sortSessions(weekly.sessions),
      durationMinutes: weekly.appointmentDurationMinutes,
      source: AvailabilitySource.weekly,
    );
  }

  /// Full slot pipeline for a single day: resolve availability, generate slots,
  /// mark booked ones, then drop slots whose start is not strictly after [now].
  static List<AvailableSlot> buildDaySlots({
    required DesignerAvailability? weekly,
    AvailabilityException? exception,
    Set<String> bookedStartTimes = const {},
    DateTime? now,
  }) {
    final effective = resolveEffective(weekly: weekly, exception: exception);
    final slots = generateSlotsMarkingBooked(
      sessions: effective.sessions,
      durationMinutes: effective.durationMinutes,
      bookedStartTimes: bookedStartTimes,
    );

    if (now == null) return slots;

    final nowMinutes = now.hour * 60 + now.minute;
    return slots
        .where((slot) => slot.startMinutes > nowMinutes)
        .toList(growable: false);
  }
}

/// Which rule supplied the effective availability for a date.
enum AvailabilitySource {
  weekly,
  exceptionCustom,
  exceptionUnavailable,
  unavailable,
}

class EffectiveAvailability {
  final List<AvailabilitySession> sessions;
  final int durationMinutes;
  final AvailabilitySource source;

  const EffectiveAvailability({
    required this.sessions,
    required this.durationMinutes,
    required this.source,
  });

  bool get isBookable => sessions.isNotEmpty && durationMinutes > 0;
}

class _Range {
  final int start;
  final int end;
  final AvailabilitySession raw;

  const _Range({required this.start, required this.end, required this.raw});
}
