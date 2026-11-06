import 'dart:io';

import 'package:fashionista/core/service_locator/hive_service.dart';
import 'package:fashionista/data/models/bookings/booking_client_model.dart';
import 'package:fashionista/data/models/bookings/booking_model.dart';
import 'package:fashionista/data/models/bookings/booking_status.dart';
import 'package:fashionista/data/services/hive/hive_booking_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

Booking booking({
  String uid = 'b1',
  BookingStatus status = BookingStatus.confirmed,
  DateTime? startAt,
}) {
  final start = startAt ?? DateTime.utc(2026, 11, 6, 12, 0);
  return Booking(
    uid: uid,
    designerId: 'designer_1',
    userId: 'user_1',
    clientId: 'client_1',
    date: '2026-11-06',
    dayOfWeek: 5,
    startAt: start,
    endAt: start.add(const Duration(minutes: 60)),
    startTime: '12:00',
    endTime: '13:00',
    timezone: 'Africa/Lagos',
    durationMinutes: 60,
    status: status,
    client: const BookingClient(id: 'client_1', name: 'Ava', mobileNumber: ''),
    notes: 'Bring the fabric',
    createdAt: DateTime.utc(2026, 11, 1, 9, 0),
    updatedAt: DateTime.utc(2026, 11, 2, 9, 0),
  );
}

void main() {
  late Directory tempDir;
  late HiveBookingService service;

  setUpAll(() async {
    tempDir = Directory.systemTemp.createTempSync('bookings_cache_test');
    Hive.init(tempDir.path);
    HiveService().bookingsBox = await Hive.openBox<String>('bookings_cache');
    service = HiveBookingService();
  });

  tearDownAll(() async {
    await Hive.close();
    tempDir.deleteSync(recursive: true);
  });

  setUp(() => service.clearCache());

  test('returns an empty list when nothing was cached', () async {
    expect(await service.getDesignerBookings('designer_1'), isEmpty);
  });

  test('round-trips a booking, including timestamps and status', () async {
    final original = booking();

    await service.saveDesignerBookings('designer_1', [original]);
    final cached = (await service.getDesignerBookings('designer_1')).single;

    expect(cached.uid, original.uid);
    expect(cached.status, BookingStatus.confirmed);
    expect(cached.startAt, original.startAt);
    expect(cached.endAt, original.endAt);
    expect(cached.createdAt, original.createdAt);
    expect(cached.client?.name, 'Ava');
    expect(cached.timezone, 'Africa/Lagos');
    expect(cached.durationMinutes, 60);
    expect(cached.notes, 'Bring the fabric');
  });

  test('keeps lists apart per designer', () async {
    await service.saveDesignerBookings('designer_1', [booking(uid: 'a')]);
    await service.saveDesignerBookings('designer_2', [booking(uid: 'b')]);

    expect((await service.getDesignerBookings('designer_1')).single.uid, 'a');
    expect((await service.getDesignerBookings('designer_2')).single.uid, 'b');
  });

  test('saving replaces the previous snapshot instead of appending', () async {
    await service.saveDesignerBookings('designer_1', [
      booking(uid: 'a'),
      booking(uid: 'b'),
    ]);
    await service.saveDesignerBookings('designer_1', [booking(uid: 'c')]);

    final cached = await service.getDesignerBookings('designer_1');
    expect(cached.map((item) => item.uid), ['c']);
  });

  test('an empty save clears the snapshot', () async {
    await service.saveDesignerBookings('designer_1', [booking()]);
    await service.saveDesignerBookings('designer_1', []);

    expect(await service.getDesignerBookings('designer_1'), isEmpty);
  });

  test('ignores a corrupted entry instead of throwing', () async {
    await HiveService().bookingsBox.put(
      HiveBookingService.designerKey('designer_1'),
      'not json',
    );

    expect(await service.getDesignerBookings('designer_1'), isEmpty);
  });

  test('clearCache drops every designer snapshot', () async {
    await service.saveDesignerBookings('designer_1', [booking()]);
    await service.clearCache();

    expect(await service.getDesignerBookings('designer_1'), isEmpty);
  });
}
