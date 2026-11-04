import 'package:fashionista/core/utils/scheduling/booking_sort.dart';
import 'package:fashionista/data/models/bookings/booking_model.dart';
import 'package:fashionista/data/models/bookings/booking_status.dart';
import 'package:flutter_test/flutter_test.dart';

Booking booking({
  required String id,
  DateTime? startAt,
  DateTime? createdAt,
}) {
  return Booking(
    uid: id,
    designerId: 'designer_1',
    userId: 'user_$id',
    date: '2026-11-16',
    dayOfWeek: 1,
    startAt: startAt,
    createdAt: createdAt,
    startTime: '08:00',
    endTime: '08:30',
    status: BookingStatus.pending,
  );
}

void main() {
  final early = DateTime.utc(2026, 11, 16, 8);
  final middle = DateTime.utc(2026, 11, 16, 10);
  final late = DateTime.utc(2026, 11, 16, 12);

  group('BookingSort by start_at', () {
    final bookings = [
      booking(id: 'late', startAt: late),
      booking(id: 'early', startAt: early),
      booking(id: 'middle', startAt: middle),
    ];

    test('ascending orders earliest first', () {
      final sorted = BookingSort.sorted(
        bookings,
        field: BookingSortField.startAt,
        ascending: true,
      );

      expect(sorted.map((b) => b.uid), ['early', 'middle', 'late']);
    });

    test('descending orders latest first', () {
      final sorted = BookingSort.sorted(
        bookings,
        field: BookingSortField.startAt,
        ascending: false,
      );

      expect(sorted.map((b) => b.uid), ['late', 'middle', 'early']);
    });
  });

  group('BookingSort by created_at', () {
    test('uses the submission timestamp, not the appointment time', () {
      final sorted = BookingSort.sorted([
        booking(id: 'a', startAt: early, createdAt: late),
        booking(id: 'b', startAt: late, createdAt: early),
      ], field: BookingSortField.createdAt, ascending: true);

      expect(sorted.map((b) => b.uid), ['b', 'a']);
    });

    test('descending reverses the order', () {
      final sorted = BookingSort.sorted([
        booking(id: 'a', createdAt: early),
        booking(id: 'b', createdAt: late),
      ], field: BookingSortField.createdAt, ascending: false);

      expect(sorted.map((b) => b.uid), ['b', 'a']);
    });
  });

  group('BookingSort edge cases', () {
    test('bookings without the field sort last in both directions', () {
      final withNull = [
        booking(id: 'none'),
        booking(id: 'early', startAt: early),
        booking(id: 'late', startAt: late),
      ];

      final ascending = BookingSort.sorted(
        withNull,
        field: BookingSortField.startAt,
        ascending: true,
      );
      final descending = BookingSort.sorted(
        withNull,
        field: BookingSortField.startAt,
        ascending: false,
      );

      expect(ascending.last.uid, 'none');
      expect(descending.last.uid, 'none');
      expect(ascending.first.uid, 'early');
      expect(descending.first.uid, 'late');
    });

    test('does not mutate the input list', () {
      final original = [
        booking(id: 'late', startAt: late),
        booking(id: 'early', startAt: early),
      ];

      BookingSort.sorted(
        original,
        field: BookingSortField.startAt,
        ascending: true,
      );

      expect(original.first.uid, 'late');
    });

    test('handles an empty list', () {
      expect(
        BookingSort.sorted(
          const [],
          field: BookingSortField.startAt,
          ascending: true,
        ),
        isEmpty,
      );
    });
  });
}
