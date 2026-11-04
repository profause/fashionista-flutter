import 'package:fashionista/core/utils/scheduling/date_key.dart';
import 'package:fashionista/core/utils/scheduling/designer_time_zone.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tz;

void main() {
  setUpAll(tz.initializeTimeZones);

  group('DesignerTimeZone', () {
    test('accepts real IANA zones and rejects typos', () {
      expect(DesignerTimeZone.isValidZone('Africa/Accra'), isTrue);
      expect(DesignerTimeZone.isValidZone('America/New_York'), isTrue);
      expect(DesignerTimeZone.isValidZone('Africa/Nowhere'), isFalse);
      expect(DesignerTimeZone.isValidZone(''), isFalse);
      expect(DesignerTimeZone.isValidZone(null), isFalse);
    });

    test('converts wall-clock times to UTC using the designer zone', () {
      final accra = DesignerTimeZone.resolve('Africa/Accra');
      final newYork = DesignerTimeZone.resolve('America/New_York');

      expect(
        DesignerTimeZone.toUtc(
          location: accra,
          date: '2026-11-16',
          time: '08:00',
        ),
        DateTime.utc(2026, 11, 16, 8, 0),
      );

      // November is EST (UTC-5).
      expect(
        DesignerTimeZone.toUtc(
          location: newYork,
          date: '2026-11-16',
          time: '08:00',
        ),
        DateTime.utc(2026, 11, 16, 13, 0),
      );
    });

    test('day range covers exactly one local day', () {
      final accra = DesignerTimeZone.resolve('Africa/Accra');
      final start = DesignerTimeZone.dayStartUtc(accra, '2026-11-16');
      final next = DesignerTimeZone.nextDayStartUtc(accra, '2026-11-16');

      expect(next.difference(start), const Duration(hours: 24));
    });

    test('handles the DST spring-forward hour without throwing', () {
      final newYork = DesignerTimeZone.resolve('America/New_York');

      // 2026-03-08 02:30 does not exist locally; tz shifts it forward.
      final resolved = DesignerTimeZone.toUtc(
        location: newYork,
        date: '2026-03-08',
        time: '02:30',
      );

      expect(resolved.isBefore(DateTime.utc(2026, 3, 8, 12)), isTrue);
      expect(resolved.isAfter(DateTime.utc(2026, 3, 8, 5)), isTrue);
    });

    test('rejects malformed dates and times', () {
      final accra = DesignerTimeZone.resolve('Africa/Accra');

      expect(
        () => DesignerTimeZone.toUtc(
          location: accra,
          date: '16-11-2026',
          time: '08:00',
        ),
        throwsFormatException,
      );
      expect(
        () => DesignerTimeZone.toUtc(
          location: accra,
          date: '2026-11-16',
          time: '8:00',
        ),
        throwsFormatException,
      );
    });

    test('derives date keys and weekdays in the designer zone', () {
      final newYork = DesignerTimeZone.resolve('America/New_York');

      // 2026-11-16 01:00 UTC is still Sunday the 15th in New York.
      final instant = DateTime.utc(2026, 11, 16, 1, 0);

      expect(DesignerTimeZone.dateKeyAt(newYork, instant), '2026-11-15');
      expect(DesignerTimeZone.weekdayAt(newYork, instant), DateTime.sunday);
    });
  });

  group('DateKey', () {
    test('formats and parses yyyy-MM-dd', () {
      expect(DateKey.fromDate(DateTime(2026, 3, 7)), '2026-03-07');
      expect(DateKey.tryParse('2026-03-07'), DateTime(2026, 3, 7));
      expect(DateKey.compact('2026-03-07'), '20260307');
    });

    test('rejects invalid dates', () {
      expect(DateKey.tryParse('2026-02-30'), isNull);
      expect(DateKey.tryParse('07/03/2026'), isNull);
      expect(DateKey.tryParse(null), isNull);
    });
  });
}
