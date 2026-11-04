import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/core/utils/scheduling/slot_generator.dart';
import 'package:fashionista/data/models/availability/availability_session_model.dart';
import 'package:fashionista/data/models/availability/bloc/availability_event.dart';
import 'package:fashionista/data/models/availability/bloc/availability_state.dart';
import 'package:fashionista/data/models/availability/designer_availability_model.dart';
import 'package:fashionista/data/models/bookings/booking_model.dart';
import 'package:fashionista/domain/usecases/availability/delete_availability_exception_usecase.dart';
import 'package:fashionista/domain/usecases/availability/fetch_designer_timezone_usecase.dart';
import 'package:fashionista/domain/usecases/availability/fetch_weekly_availability_usecase.dart';
import 'package:fashionista/domain/usecases/availability/save_availability_exception_usecase.dart';
import 'package:fashionista/domain/usecases/availability/save_day_availability_usecase.dart';
import 'package:fashionista/domain/usecases/availability/save_designer_timezone_usecase.dart';
import 'package:fashionista/domain/usecases/bookings/fetch_schedule_conflicts_usecase.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AvailabilityBloc extends Bloc<AvailabilityEvent, AvailabilityState> {
  AvailabilityBloc() : super(const AvailabilityInitial()) {
    on<LoadAvailability>(_onLoad);
    on<SaveDay>(_onSaveDay);
    on<SaveException>(_onSaveException);
    on<DeleteException>(_onDeleteException);
    on<SaveTimezone>(_onSaveTimezone);
  }

  Future<void> _onLoad(
    LoadAvailability event,
    Emitter<AvailabilityState> emit,
  ) async {
    emit(const AvailabilityLoading());

    final weeklyResult = await sl<FetchWeeklyAvailabilityUsecase>()(
      event.designerId,
    );

    await weeklyResult.fold(
      (failure) async => emit(
        AvailabilityError(
          message: failure,
          weekly: DesignerAvailability.emptyWeek(),
        ),
      ),
      (weekly) async {
        final timezoneResult = await sl<FetchDesignerTimezoneUsecase>()(
          event.designerId,
        );
        final timezone = timezoneResult.getOrElse(() => null) ?? '';
        emit(AvailabilityLoaded(weekly: weekly, timezone: timezone));
      },
    );
  }

  Future<void> _onSaveDay(
    SaveDay event,
    Emitter<AvailabilityState> emit,
  ) async {
    final current = state;
    final weekly = current is AvailabilityLoaded
        ? current.weekly
        : current is AvailabilitySaved
        ? current.weekly
        : DesignerAvailability.emptyWeek();
    final timezone = _timezoneOf(current);

    if (event.availability.isAvailable) {
      final problems = SlotSchedulingService.validateSchedule(
        sessions: event.availability.sessions,
        durationMinutes: event.availability.appointmentDurationMinutes,
      );
      if (problems.isNotEmpty) {
        emit(
          AvailabilityError(
            message: problems.first,
            weekly: weekly,
            timezone: timezone,
          ),
        );
        return;
      }
    }

    if (!event.confirmedConflicts) {
      final conflicts = await _invalidatedBookings(
        designerId: event.designerId,
        dayOfWeek: event.availability.dayOfWeek,
        sessions: event.availability.isAvailable
            ? event.availability.sessions
            : const [],
        durationMinutes: event.availability.appointmentDurationMinutes,
      );

      if (conflicts.isNotEmpty) {
        emit(
          AvailabilityConflicts(
            weekly: weekly,
            timezone: timezone,
            conflicts: conflicts,
            pendingDay: event.availability,
          ),
        );
        return;
      }
    }

    emit(AvailabilitySaving(weekly: weekly, timezone: timezone));

    final result = await sl<SaveDayAvailabilityUsecase>()(
      SaveDayAvailabilityParams(
        designerId: event.designerId,
        availability: event.availability.copyWith(
          sessions: SlotSchedulingService.sortSessions(
            event.availability.sessions,
          ),
        ),
      ),
    );

    await result.fold(
      (failure) async => emit(
        AvailabilityError(
          message: failure,
          weekly: weekly,
          timezone: timezone,
        ),
      ),
      (_) async {
        final updated = _replaceDay(weekly, event.availability);
        emit(
          AvailabilitySaved(
            weekly: updated,
            timezone: timezone,
            message: '${event.availability.dayName} availability saved.',
          ),
        );
      },
    );
  }

  Future<void> _onSaveException(
    SaveException event,
    Emitter<AvailabilityState> emit,
  ) async {
    final current = state;
    final weekly = _weeklyOf(current);
    final timezone = _timezoneOf(current);

    if (event.exception.isCustom) {
      final problems = SlotSchedulingService.validateSchedule(
        sessions: event.exception.sessions,
        durationMinutes: event.exception.appointmentDurationMinutes ??
            _durationForDate(weekly, event.exception.date),
      );
      if (problems.isNotEmpty) {
        emit(
          AvailabilityError(
            message: problems.first,
            weekly: weekly,
            timezone: timezone,
          ),
        );
        return;
      }
    }

    if (!event.confirmedConflicts) {
      final parsed = DateTime.tryParse(event.exception.date);
      final conflicts = await _invalidatedBookings(
        designerId: event.designerId,
        dayOfWeek: parsed?.weekday ?? 1,
        sessions: event.exception.isCustom ? event.exception.sessions : const [],
        durationMinutes: event.exception.appointmentDurationMinutes ??
            _durationForDate(weekly, event.exception.date),
        date: event.exception.date,
      );

      if (conflicts.isNotEmpty) {
        emit(
          AvailabilityConflicts(
            weekly: weekly,
            timezone: timezone,
            conflicts: conflicts,
            pendingException: event.exception,
          ),
        );
        return;
      }
    }

    emit(AvailabilitySaving(weekly: weekly, timezone: timezone));

    final result = await sl<SaveAvailabilityExceptionUsecase>()(
      SaveAvailabilityExceptionParams(
        designerId: event.designerId,
        exception: event.exception,
      ),
    );

    await result.fold(
      (failure) async => emit(
        AvailabilityError(
          message: failure,
          weekly: weekly,
          timezone: timezone,
        ),
      ),
      (_) async => emit(
        AvailabilitySaved(
          weekly: weekly,
          timezone: timezone,
          message: 'Availability updated for ${event.exception.date}.',
        ),
      ),
    );
  }

  Future<void> _onDeleteException(
    DeleteException event,
    Emitter<AvailabilityState> emit,
  ) async {
    final weekly = _weeklyOf(state);
    final timezone = _timezoneOf(state);

    emit(AvailabilitySaving(weekly: weekly, timezone: timezone));

    final result = await sl<DeleteAvailabilityExceptionUsecase>()(
      DeleteAvailabilityExceptionParams(
        designerId: event.designerId,
        date: event.date,
      ),
    );

    await result.fold(
      (failure) async => emit(
        AvailabilityError(
          message: failure,
          weekly: weekly,
          timezone: timezone,
        ),
      ),
      (_) async => emit(
        AvailabilitySaved(
          weekly: weekly,
          timezone: timezone,
          message: 'Exception removed for ${event.date}.',
        ),
      ),
    );
  }

  Future<void> _onSaveTimezone(
    SaveTimezone event,
    Emitter<AvailabilityState> emit,
  ) async {
    final weekly = _weeklyOf(state);

    final result = await sl<SaveDesignerTimezoneUsecase>()(
      SaveDesignerTimezoneParams(
        designerId: event.designerId,
        timezone: event.timezone,
      ),
    );

    result.fold(
      (failure) => emit(
        AvailabilityError(
          message: failure,
          weekly: weekly,
          timezone: _timezoneOf(state),
        ),
      ),
      (_) => emit(
        AvailabilitySaved(
          weekly: weekly,
          timezone: event.timezone,
          message: 'Timezone set to ${event.timezone}.',
        ),
      ),
    );
  }

  Future<List<Booking>> _invalidatedBookings({
    required String designerId,
    required int dayOfWeek,
    required List<AvailabilitySession> sessions,
    required int durationMinutes,
    String? date,
  }) async {
    final result = await sl<FetchScheduleConflictsUsecase>()(
      FetchScheduleConflictsParams(
        designerId: designerId,
        dayOfWeek: dayOfWeek,
        date: date,
      ),
    );

    return result.fold((_) => const <Booking>[], (bookings) {
      final slots = SlotSchedulingService.generateSlots(
        sessions: sessions,
        durationMinutes: durationMinutes,
      );
      final slotStarts = slots.map((slot) => slot.startTime).toSet();
      return bookings
          .where((booking) => !slotStarts.contains(booking.startTime))
          .toList();
    });
  }

  int _durationForDate(List<DesignerAvailability> weekly, String date) {
    final parsed = DateTime.tryParse(date);
    if (parsed == null) return DesignerAvailability.defaultDurationMinutes;
    for (final day in weekly) {
      if (day.dayOfWeek == parsed.weekday) {
        return day.appointmentDurationMinutes;
      }
    }
    return DesignerAvailability.defaultDurationMinutes;
  }

  List<DesignerAvailability> _weeklyOf(AvailabilityState state) {
    if (state is AvailabilityLoaded) return state.weekly;
    if (state is AvailabilitySaving) return state.weekly;
    if (state is AvailabilitySaved) return state.weekly;
    if (state is AvailabilityError) return state.weekly;
    if (state is AvailabilityConflicts) return state.weekly;
    return DesignerAvailability.emptyWeek();
  }

  String _timezoneOf(AvailabilityState state) {
    if (state is AvailabilityLoaded) return state.timezone;
    if (state is AvailabilitySaving) return state.timezone;
    if (state is AvailabilitySaved) return state.timezone;
    if (state is AvailabilityError) return state.timezone;
    if (state is AvailabilityConflicts) return state.timezone;
    return '';
  }

  List<DesignerAvailability> _replaceDay(
    List<DesignerAvailability> weekly,
    DesignerAvailability updated,
  ) {
    return [
      for (final day in weekly)
        if (day.dayOfWeek == updated.dayOfWeek) updated else day,
    ];
  }
}
