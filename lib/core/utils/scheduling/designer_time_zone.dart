import 'package:fashionista/core/utils/scheduling/date_key.dart';
import 'package:fashionista/core/utils/scheduling/time_of_day_x.dart';
import 'package:timezone/timezone.dart' as tz;

/// Converts designer-local wall-clock availability into real instants.
///
/// Availability is authored as wall-clock time (`08:00`) in the designer's
/// timezone. Bookings additionally store the resolved UTC instant so that
/// range queries and ordering are unambiguous.
class DesignerTimeZone {
  DesignerTimeZone._();

  static const String fallbackZone = 'UTC';

  /// Strict check used before persisting a designer-supplied zone.
  ///
  /// Unlike [resolve], this never falls back, so a typo can be rejected.
  static bool isValidZone(String? timezone) {
    final name = (timezone ?? '').trim();
    if (name.isEmpty) return false;
    try {
      tz.getLocation(name);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Resolves an IANA name, falling back to the device timezone and finally
  /// UTC when the database is unavailable (for example in unit tests).
  static tz.Location resolve(String? timezone) {
    final name = (timezone ?? '').trim();
    if (name.isNotEmpty) {
      try {
        return tz.getLocation(name);
      } catch (_) {
        // Fall through to the local zone.
      }
    }
    try {
      return tz.local;
    } catch (_) {
      return tz.getLocation(fallbackZone);
    }
  }

  /// Local wall-clock date for [instant] in [location].
  static String dateKeyAt(tz.Location location, DateTime instant) {
    return DateKey.fromDate(tz.TZDateTime.from(instant, location));
  }

  /// Local weekday (`1` = Monday .. `7` = Sunday) for [instant].
  static int weekdayAt(tz.Location location, DateTime instant) {
    return tz.TZDateTime.from(instant, location).weekday;
  }

  /// Converts a local `yyyy-MM-dd` + `HH:mm` into a UTC instant.
  ///
  /// Throws [FormatException] when the date or time is malformed.
  static DateTime toUtc({
    required tz.Location location,
    required String date,
    required String time,
  }) {
    final parsedDate = DateKey.parse(date);
    final minutes = TimeOfDayX.tryToMinutes(time);
    if (minutes == null) {
      throw FormatException('Invalid HH:mm time', time);
    }
    final local = tz.TZDateTime(
      location,
      parsedDate.year,
      parsedDate.month,
      parsedDate.day,
      minutes ~/ 60,
      minutes % 60,
    );
    return local.toUtc();
  }

  /// UTC instant of local midnight for [dateKey].
  static DateTime dayStartUtc(tz.Location location, String dateKey) {
    return toUtc(location: location, date: dateKey, time: '00:00');
  }

  /// UTC instant of local midnight *after* [dateKey].
  static DateTime nextDayStartUtc(tz.Location location, String dateKey) {
    final parsed = DateKey.parse(dateKey);
    final explicitNext = DateTime(parsed.year, parsed.month, parsed.day)
        .add(const Duration(days: 1));
    return toUtc(
      location: location,
      date: DateKey.fromDate(explicitNext),
      time: '00:00',
    );
  }

  /// Current local wall-clock minute-of-day, used to hide slots that passed.
  static int localMinutesNow(tz.Location location) {
    final now = tz.TZDateTime.now(location);
    return now.hour * 60 + now.minute;
  }

  /// Local date key for today in [location].
  static String todayKey(tz.Location location) {
    return dateKeyAt(location, DateTime.now().toUtc());
  }

  /// `true` when the `date` + `time` combination is strictly in the future.
  static bool isFuture({
    required tz.Location location,
    required String date,
    required String time,
  }) {
    try {
      return toUtc(location: location, date: date, time: time)
          .isAfter(DateTime.now().toUtc());
    } catch (_) {
      return false;
    }
  }
}
