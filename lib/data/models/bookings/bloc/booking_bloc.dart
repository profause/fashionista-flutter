import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/data/models/bookings/booking_status.dart';
import 'package:fashionista/data/models/bookings/bloc/booking_event.dart';
import 'package:fashionista/data/models/bookings/bloc/booking_state.dart';
import 'package:fashionista/domain/usecases/availability/fetch_designer_timezone_usecase.dart';
import 'package:fashionista/domain/usecases/bookings/create_booking_usecase.dart';
import 'package:fashionista/domain/usecases/bookings/fetch_bookings_for_designer_usecase.dart';
import 'package:fashionista/domain/usecases/bookings/fetch_bookings_for_user_usecase.dart';
import 'package:fashionista/domain/usecases/bookings/get_available_slots_usecase.dart';
import 'package:fashionista/domain/usecases/bookings/update_booking_status_usecase.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BookingBloc extends Bloc<BookingEvent, BookingState> {
  BookingBloc() : super(const BookingInitial()) {
    on<LoadDesignerBookings>(_onLoadDesignerBookings);
    on<LoadMyBookings>(_onLoadMyBookings);
    on<LoadAvailableSlots>(_onLoadAvailableSlots);
    on<CreateBooking>(_onCreateBooking);
    on<ChangeBookingStatus>(_onChangeStatus);
    on<ResetBookingState>((event, emit) => emit(const BookingInitial()));
  }

  Future<void> _onLoadDesignerBookings(
    LoadDesignerBookings event,
    Emitter<BookingState> emit,
  ) async {
    if (!event.refreshOnly) emit(const BookingsLoading());
    final result = await sl<FetchBookingsForDesignerUsecase>()(
      event.designerId,
    );

    result.fold(
      (failure) => emit(BookingError(failure)),
      (bookings) => emit(
        BookingsLoaded(bookings: bookings, ownerId: event.designerId),
      ),
    );
  }

  Future<void> _onLoadMyBookings(
    LoadMyBookings event,
    Emitter<BookingState> emit,
  ) async {
    if (!event.refreshOnly) emit(const BookingsLoading());
    final result = await sl<FetchBookingsForUserUsecase>()(event.userId);

    result.fold(
      (failure) => emit(BookingError(failure)),
      (bookings) => emit(
        BookingsLoaded(bookings: bookings, ownerId: event.userId),
      ),
    );
  }

  Future<void> _onLoadAvailableSlots(
    LoadAvailableSlots event,
    Emitter<BookingState> emit,
  ) async {
    emit(
      AvailableSlotsLoading(designerId: event.designerId, date: event.date),
    );

    final timezoneResult = await sl<FetchDesignerTimezoneUsecase>()(
      event.designerId,
    );
    final timezone = timezoneResult.getOrElse(() => null) ?? '';

    final result = await sl<GetAvailableSlotsUsecase>()(
      GetAvailableSlotsParams(designerId: event.designerId, date: event.date),
    );

    result.fold(
      (failure) => emit(BookingError(failure)),
      (slots) => emit(
        AvailableSlotsLoaded(
          slots: slots,
          designerId: event.designerId,
          date: event.date,
          timezone: timezone,
        ),
      ),
    );
  }

  Future<void> _onCreateBooking(
    CreateBooking event,
    Emitter<BookingState> emit,
  ) async {
    emit(const BookingSubmitting());

    final result = await sl<CreateBookingUsecase>()(event.request);

    result.fold(
      (failure) => emit(BookingError(failure)),
      (booking) => emit(BookingCreated(booking)),
    );
  }

  Future<void> _onChangeStatus(
    ChangeBookingStatus event,
    Emitter<BookingState> emit,
  ) async {
    final previous = state;
    final ownerId = previous is BookingsLoaded ? previous.ownerId : '';

    emit(const BookingSubmitting());

    final result = await sl<UpdateBookingStatusUsecase>()(
      UpdateBookingStatusParams(
        bookingId: event.bookingId,
        status: event.status,
        actorUserId: event.actorUserId,
        actorIsDesigner: event.actorIsDesigner,
      ),
    );

    await result.fold(
      (failure) async => emit(BookingError(failure)),
      (_) async {
        if (ownerId.isNotEmpty) {
          if (event.actorIsDesigner) {
            add(
              LoadDesignerBookings(ownerId, refreshOnly: true),
            );
          } else {
            add(LoadMyBookings(ownerId, refreshOnly: true));
          }
        }
        emit(
          BookingActionSuccess(
            'Booking marked as ${event.status.label.toLowerCase()}.',
          ),
        );
      },
    );
  }
}
