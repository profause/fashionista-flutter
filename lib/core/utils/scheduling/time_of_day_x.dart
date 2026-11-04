import 'package:flutter/material.dart';

/// Helpers for the 24-hour `HH:mm` wall-clock strings used by designer
/// availability and bookings.
///
/// Availability is stored as local wall-clock time (for example `08:00`),
/// never as an instant. Converting a date + wall-clock into a real instant
/// happens only at booking time, using the designer's timezone.
class TimeOfDayX {
  TimeOfDayX._();

  static final RegExp _pattern = RegExp(r'^([01]\d|2[0-3]):([0-5]\d)$');

  /// Returns `true` when [value] is a valid 24-hour `HH:mm` string.
  static bool isValid(String? value) {
    if (value == null) return false;
    return _pattern.hasMatch(value.trim());
  }

  /// Parses `HH:mm` into minutes from midnight.
  ///
  /// Throws [FormatException] when [value] is not a valid `HH:mm` string.
  static int toMinutes(String value) {
    if (!isValid(value)) {
      throw FormatException('Invalid HH:mm time', value);
    }
    final parts = value.trim().split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  /// Parses `HH:mm`, returning `null` instead of throwing.
  static int? tryToMinutes(String? value) {
    if (!isValid(value)) return null;
    return toMinutes(value!);
  }

  /// Formats minutes from midnight as `HH:mm`.
  ///
  /// Values outside a single day are clamped to `00:00`-`23:59`.
  static String fromMinutes(int minutes) {
    final clamped = minutes.clamp(0, 24 * 60 - 1);
    final hours = (clamped ~/ 60).toString().padLeft(2, '0');
    final mins = (clamped % 60).toString().padLeft(2, '0');
    return '$hours:$mins';
  }

  /// Normalises loose input (`8:00`, `0800`) into `08:00`.
  ///
  /// Returns `null` when the value cannot be interpreted as a time.
  static String? normalize(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;

    if (_pattern.hasMatch(trimmed)) return trimmed;

    final digitsOnly = trimmed.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.length == 3) {
      return fromMinutes(
        int.parse(digitsOnly.substring(0, 1)) * 60 +
            int.parse(digitsOnly.substring(1)),
      );
    }
    if (digitsOnly.length == 4) {
      return fromMinutes(
        int.parse(digitsOnly.substring(0, 2)) * 60 +
            int.parse(digitsOnly.substring(2)),
      );
    }
    return null;
  }

  /// `HH:mm` counterpart of a Flutter [TimeOfDay].
  static String fromTimeOfDay(TimeOfDay time) {
    return fromMinutes(time.hour * 60 + time.minute);
  }

  /// Flutter [TimeOfDay] counterpart of an `HH:mm` string.
  static TimeOfDay? toTimeOfDay(String? value) {
    final minutes = tryToMinutes(value);
    if (minutes == null) return null;
    return TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60);
  }

  /// 12-hour label used by the availability and booking screens.
  static String toDisplay(String value) {
    final minutes = tryToMinutes(value);
    if (minutes == null) return value;
    final hour24 = minutes ~/ 60;
    final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
    final period = hour24 < 12 ? 'AM' : 'PM';
    final mins = (minutes % 60).toString().padLeft(2, '0');
    return '$hour12:$mins $period';
  }
}
