import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/data/models/bookings/booking_model.dart';
import 'package:fashionista/data/models/bookings/booking_status.dart';
import 'package:fashionista/data/models/bookings/bloc/booking_bloc.dart';
import 'package:fashionista/data/models/bookings/bloc/booking_event.dart';
import 'package:fashionista/data/models/bookings/bloc/booking_state.dart';
import 'package:fashionista/data/services/hive/hive_booking_service.dart';
import 'package:fashionista/data/services/local/appointment_reminder_service.dart';
import 'package:fashionista/domain/repository/bookings/booking_repository.dart';
import 'package:fashionista/domain/usecases/bookings/fetch_bookings_for_designer_usecase.dart';
import 'package:fashionista/domain/usecases/bookings/update_booking_status_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

const String designerId = 'designer_1';

Booking booking({
  String uid = 'b1',
  BookingStatus status = BookingStatus.pending,
}) {
  final start = DateTime.utc(2026, 11, 6, 12, 0);
  return Booking(
    uid: uid,
    designerId: designerId,
    userId: 'user_1',
    date: '2026-11-06',
    dayOfWeek: 5,
    startAt: start,
    endAt: start.add(const Duration(minutes: 60)),
    startTime: '12:00',
    endTime: '13:00',
    status: status,
  );
}

/// In-memory stand-in for the Hive snapshot.
class FakeHiveBookingService extends HiveBookingService {
  final Map<String, List<Booking>> store = {};
  final List<List<Booking>> saves = [];

  @override
  Future<List<Booking>> getDesignerBookings(String designerId) async =>
      store[designerId] ?? const [];

  @override
  Future<void> saveDesignerBookings(
    String designerId,
    List<Booking> bookings,
  ) async {
    store[designerId] = List.of(bookings);
    saves.add(List.of(bookings));
  }
}

class FakeBookingRepository implements BookingRepository {
  Either<String, List<Booking>>? result;
  Completer<void>? gate;

  @override
  Future<Either<String, List<Booking>>> fetchBookingsForDesigner(
    String designerId,
  ) async {
    if (gate != null) await gate!.future;
    return result ?? const Right([]);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

void main() {
  late FakeBookingRepository repository;
  late FakeHiveBookingService cache;

  setUp(() {
    repository = FakeBookingRepository();
    cache = FakeHiveBookingService();

    sl.registerSingleton<BookingRepository>(repository);
    sl.registerSingleton<HiveBookingService>(cache);
    sl.registerSingleton<FetchBookingsForDesignerUsecase>(
      FetchBookingsForDesignerUsecase(),
    );
    sl.registerSingleton<UpdateBookingStatusUsecase>(
      UpdateBookingStatusUsecase(),
    );
    sl.registerSingleton<AppointmentReminderService>(
      AppointmentReminderService(
        remindersEnabled: () async => false,
        schedule:
            ({
              required int id,
              required String title,
              required String body,
              required DateTime scheduledDate,
              required Map<String, dynamic> data,
            }) async {},
        cancel: (id) async {},
      ),
    );
  });

  tearDown(() => sl.reset());

  test('paints the cached list before Firestore answers', () async {
    cache.store[designerId] = [booking(uid: 'cached')];
    repository.gate = Completer<void>();
    repository.result = Right([booking(uid: 'fresh')]);

    final bloc = BookingBloc();
    final states = <BookingState>[];
    final subscription = bloc.stream.listen(states.add);

    bloc.add(const LoadDesignerBookings(designerId));
    await Future<void>.delayed(Duration.zero);

    // The snapshot is on screen while the network call is still pending.
    final painted = bloc.state;
    expect(painted, isA<BookingsLoaded>());
    expect((painted as BookingsLoaded).fromCache, isTrue);
    expect(painted.bookings.single.uid, 'cached');

    repository.gate!.complete();
    repository.gate = null;
    await Future<void>.delayed(Duration.zero);

    // Firestore replaces it and the fresh list is cached.
    final loaded = bloc.state as BookingsLoaded;
    expect(loaded.fromCache, isFalse);
    expect(loaded.bookings.single.uid, 'fresh');
    expect(cache.store[designerId]!.single.uid, 'fresh');
    expect(states.length, greaterThanOrEqualTo(2));

    await subscription.cancel();
    await bloc.close();
  });

  test('shows a spinner when there is no cache to paint', () async {
    repository.gate = Completer<void>();
    repository.result = Right([booking()]);

    final bloc = BookingBloc();
    bloc.add(const LoadDesignerBookings(designerId));
    await Future<void>.delayed(Duration.zero);

    expect(bloc.state, isA<BookingsLoading>());

    repository.gate!.complete();
    repository.gate = null;
    await Future<void>.delayed(Duration.zero);

    expect(bloc.state, isA<BookingsLoaded>());

    await bloc.close();
  });

  test('keeps the cached list when the refresh fails', () async {
    cache.store[designerId] = [booking(uid: 'cached')];
    repository.result = const Left('offline');

    final bloc = BookingBloc();
    bloc.add(const LoadDesignerBookings(designerId));
    await Future<void>.delayed(const Duration(milliseconds: 10));

    final state = bloc.state;
    expect(state, isA<BookingsLoaded>());
    final loaded = state as BookingsLoaded;
    expect(loaded.bookings.single.uid, 'cached');
    expect(loaded.fromCache, isTrue);
    expect(loaded.refreshError, 'offline');

    await bloc.close();
  });

  test('reports an error when the failure leaves nothing to show', () async {
    repository.result = const Left('offline');

    final bloc = BookingBloc();
    bloc.add(const LoadDesignerBookings(designerId));
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(bloc.state, isA<BookingError>());
    expect((bloc.state as BookingError).message, 'offline');

    await bloc.close();
  });

  test('a silent refresh does not repaint the cache', () async {
    cache.store[designerId] = [booking(uid: 'cached')];
    repository.result = Right([booking(uid: 'fresh')]);

    final bloc = BookingBloc();
    bloc.add(const LoadDesignerBookings(designerId));
    await Future<void>.delayed(const Duration(milliseconds: 10));

    final states = <BookingState>[];
    final subscription = bloc.stream.listen(states.add);

    bloc.add(const LoadDesignerBookings(designerId, refreshOnly: true));
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(
      states.whereType<BookingsLoaded>().every((s) => !s.fromCache),
      isTrue,
    );
    expect((bloc.state as BookingsLoaded).bookings.single.uid, 'fresh');

    await subscription.cancel();
    await bloc.close();
  });

  test('a silent refresh failure keeps the list without a spinner', () async {
    repository.result = Right([booking(uid: 'fresh')]);

    final bloc = BookingBloc();
    bloc.add(const LoadDesignerBookings(designerId));
    await Future<void>.delayed(const Duration(milliseconds: 10));

    repository.result = const Left('timeout');
    bloc.add(const LoadDesignerBookings(designerId, refreshOnly: true));
    await Future<void>.delayed(const Duration(milliseconds: 10));

    final state = bloc.state as BookingsLoaded;
    expect(state.bookings.single.uid, 'fresh');
    expect(state.refreshError, 'timeout');

    await bloc.close();
  });

  test('caches an empty result so cancelled bookings do not linger', () async {
    cache.store[designerId] = [booking(uid: 'stale')];
    repository.result = const Right([]);

    final bloc = BookingBloc();
    bloc.add(const LoadDesignerBookings(designerId));
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect((bloc.state as BookingsLoaded).bookings, isEmpty);
    expect(cache.saves.single, isEmpty);
    expect(cache.store[designerId], isEmpty);

    await bloc.close();
  });
}
