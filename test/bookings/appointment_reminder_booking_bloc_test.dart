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
import 'package:fashionista/domain/usecases/bookings/fetch_bookings_for_user_usecase.dart';
import 'package:fashionista/domain/usecases/bookings/update_booking_status_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

const String designerId = 'designer_1';
const String clientId = 'client_1';

final DateTime now = DateTime(2026, 11, 6, 9, 0);

Booking booking({
  BookingStatus status = BookingStatus.pending,
  String designer = designerId,
  String user = clientId,
}) {
  final start = now.add(const Duration(hours: 3));
  return Booking(
    uid: 'booking_1',
    designerId: designer,
    userId: user,
    date: DateFormat('yyyy-MM-dd').format(start),
    dayOfWeek: start.weekday,
    startAt: start,
    endAt: start.add(const Duration(minutes: 60)),
    startTime: '12:00',
    endTime: '13:00',
    status: status,
  );
}

class FakeBookingRepository implements BookingRepository {
  FakeBookingRepository(this.bookings);

  List<Booking> bookings;

  @override
  Future<Either<String, List<Booking>>> fetchBookingsForDesigner(
    String designerId,
  ) async => Right(bookings);

  @override
  Future<Either<String, List<Booking>>> fetchBookingsForUser(
    String userId,
  ) async => Right(bookings);

  @override
  Future<Either<String, void>> updateBookingStatus({
    required String bookingId,
    required BookingStatus status,
    required String actorUserId,
    required bool actorIsDesigner,
  }) async {
    bookings = [
      for (final item in bookings)
        if (item.uid == bookingId) item.copyWith(status: status) else item,
    ];
    return const Right(null);
  }

  /// Everything the reminder flow never touches.
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

/// The bloc also reads the offline booking snapshot; this test has no Hive.
class StubHiveBookingService extends HiveBookingService {
  @override
  Future<List<Booking>> getDesignerBookings(String designerId) async =>
      const [];

  @override
  Future<void> saveDesignerBookings(
    String designerId,
    List<Booking> bookings,
  ) async {}
}

void main() {
  late FakeBookingRepository repository;
  late List<({DateTime scheduledDate, int id})> scheduled;
  late List<int> cancelled;

  setUp(() {
    repository = FakeBookingRepository([booking()]);
    scheduled = [];
    cancelled = [];

    sl.registerSingleton<BookingRepository>(repository);
    sl.registerSingleton<HiveBookingService>(StubHiveBookingService());
    sl.registerSingleton<FetchBookingsForDesignerUsecase>(
      FetchBookingsForDesignerUsecase(),
    );
    sl.registerSingleton<FetchBookingsForUserUsecase>(
      FetchBookingsForUserUsecase(),
    );
    sl.registerSingleton<UpdateBookingStatusUsecase>(
      UpdateBookingStatusUsecase(),
    );
    sl.registerSingleton<AppointmentReminderService>(
      AppointmentReminderService(
        now: () => now,
        remindersEnabled: () async => true,
        schedule:
            ({
              required int id,
              required String title,
              required String body,
              required DateTime scheduledDate,
              required Map<String, dynamic> data,
            }) async {
              scheduled.add((id: id, scheduledDate: scheduledDate));
            },
        cancel: (id) async => cancelled.add(id),
      ),
    );
  });

  tearDown(() => sl.reset());

  /// Loads the designer list so the bloc knows the booking before it changes.
  Future<BookingBloc> loadedBloc() async {
    final bloc = BookingBloc();
    bloc.add(const LoadDesignerBookings(designerId));
    await bloc.stream.firstWhere((state) => state is BookingsLoaded);
    return bloc;
  }

  test('confirming an appointment arms the reminder', () async {
    final bloc = await loadedBloc();
    scheduled.clear(); // the initial list sync already ran

    final changed = bloc.stream.firstWhere(
      (state) => state is BookingActionSuccess,
    );
    bloc.add(
      const ChangeBookingStatus(
        bookingId: 'booking_1',
        status: BookingStatus.confirmed,
        actorUserId: designerId,
        actorIsDesigner: true,
      ),
    );
    await changed;
    await Future<void>.delayed(Duration.zero);

    expect(scheduled, isNotEmpty);
    expect(
      scheduled.first.scheduledDate,
      now
          .add(const Duration(hours: 3))
          .subtract(AppointmentReminderService.leadTime),
    );

    await bloc.close();
  });

  test('declining an appointment cancels the reminder', () async {
    final bloc = await loadedBloc();
    cancelled.clear();

    final changed = bloc.stream.firstWhere(
      (state) => state is BookingActionSuccess,
    );
    bloc.add(
      const ChangeBookingStatus(
        bookingId: 'booking_1',
        status: BookingStatus.declined,
        actorUserId: designerId,
        actorIsDesigner: true,
      ),
    );
    await changed;
    await Future<void>.delayed(Duration.zero);

    expect(
      cancelled,
      contains(AppointmentReminderService.notificationIdFor('booking_1')),
    );
    expect(scheduled, isEmpty);

    await bloc.close();
  });

  test('loading my bookings schedules reminders for confirmed ones', () async {
    repository.bookings = [booking(status: BookingStatus.confirmed)];

    final bloc = BookingBloc();
    bloc.add(const LoadMyBookings(clientId));
    await bloc.stream.firstWhere((state) => state is BookingsLoaded);
    await Future<void>.delayed(Duration.zero);

    expect(scheduled, isNotEmpty);

    await bloc.close();
  });

  test('a pending booking in the list schedules nothing', () async {
    final bloc = await loadedBloc();
    await Future<void>.delayed(Duration.zero);

    expect(scheduled, isEmpty);

    await bloc.close();
  });
}
