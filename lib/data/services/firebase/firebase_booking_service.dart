import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:fashionista/core/utils/scheduling/booking_policy.dart';
import 'package:fashionista/core/utils/scheduling/designer_time_zone.dart';
import 'package:fashionista/core/utils/scheduling/reservation_key.dart';
import 'package:fashionista/core/utils/scheduling/slot_generator.dart';
import 'package:fashionista/data/models/availability/availability_exception_model.dart';
import 'package:fashionista/data/models/availability/designer_availability_model.dart';
import 'package:fashionista/data/models/bookings/booking_client_model.dart';
import 'package:fashionista/data/models/bookings/booking_model.dart';
import 'package:fashionista/data/models/bookings/booking_status.dart';
import 'package:fashionista/data/models/bookings/create_booking_request.dart';
import 'package:fashionista/data/models/bookings/slot_reservation_model.dart';

abstract class FirebaseBookingService {
  Future<Either<String, List<Booking>>> findBookingsForDesigner(
    String designerId,
  );

  Stream<List<Booking>> streamBookingsForDesigner(String designerId);

  Future<Either<String, List<Booking>>> findBookingsForUser(String userId);

  Stream<List<Booking>> streamBookingsForUser(String userId);

  Future<Either<String, List<Booking>>> findBookingsForDesignerOnDate(
    String designerId,
    String date,
    String timezone,
  );

  Future<Either<String, Booking?>> findBookingById(String bookingId);

  Stream<Booking?> streamBooking(String bookingId);

  /// Start times already held by an active booking on [date].
  Future<Either<String, Set<String>>> findBookedStartTimes({
    required String designerId,
    required String date,
    required String timezone,
  });

  /// Bookings that would be invalidated if the designer edits [dayOfWeek].
  Future<Either<String, List<Booking>>> findScheduleConflicts({
    required String designerId,
    required int dayOfWeek,
    String? date,
  });

  Future<Either<String, Booking>> createBooking(CreateBookingRequest request);

  Future<Either<String, void>> updateBookingStatus({
    required String bookingId,
    required BookingStatus status,
    required String actorUserId,
    required bool actorIsDesigner,
  });
}

class FirebaseBookingServiceImpl implements FirebaseBookingService {
  /// Overridable for tests; production resolves the default instance.
  final FirebaseFirestore? _firestoreOverride;

  FirebaseBookingServiceImpl({FirebaseFirestore? firestore})
    : _firestoreOverride = firestore;

  FirebaseFirestore get _firestore =>
      _firestoreOverride ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _bookings =>
      _firestore.collection('bookings');

  CollectionReference<Map<String, dynamic>> get _reservations =>
      _firestore.collection('slot_reservations');

  Booking _bookingFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    return Booking.fromJson(doc.data() ?? {}).copyWith(uid: doc.id);
  }

  @override
  Future<Either<String, List<Booking>>> findBookingsForDesigner(
    String designerId,
  ) async {
    try {
      final snapshot = await _bookings
          .where('designer_id', isEqualTo: designerId)
          .orderBy('start_at', descending: true)
          .get();
      return Right(snapshot.docs.map(_bookingFromDoc).toList());
    } on FirebaseException catch (e) {
      return Left(e.message ?? 'Unable to load bookings');
    } catch (e) {
      return Left('Unable to load bookings: $e');
    }
  }

  @override
  Stream<List<Booking>> streamBookingsForDesigner(String designerId) {
    return _bookings
        .where('designer_id', isEqualTo: designerId)
        .orderBy('start_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(_bookingFromDoc).toList());
  }

  @override
  Future<Either<String, List<Booking>>> findBookingsForUser(
    String userId,
  ) async {
    try {
      final snapshot = await _bookings
          .where('user_id', isEqualTo: userId)
          .orderBy('start_at', descending: true)
          .get();
      return Right(snapshot.docs.map(_bookingFromDoc).toList());
    } on FirebaseException catch (e) {
      return Left(e.message ?? 'Unable to load your bookings');
    } catch (e) {
      return Left('Unable to load your bookings: $e');
    }
  }

  @override
  Stream<List<Booking>> streamBookingsForUser(String userId) {
    return _bookings
        .where('user_id', isEqualTo: userId)
        .orderBy('start_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(_bookingFromDoc).toList());
  }

  @override
  Future<Either<String, List<Booking>>> findBookingsForDesignerOnDate(
    String designerId,
    String date,
    String timezone,
  ) async {
    try {
      final location = DesignerTimeZone.resolve(timezone);
      final dayStart = DesignerTimeZone.dayStartUtc(location, date);
      final nextDayStart = DesignerTimeZone.nextDayStartUtc(location, date);

      final snapshot = await _bookings
          .where('designer_id', isEqualTo: designerId)
          .where('start_at', isGreaterThanOrEqualTo: Timestamp.fromDate(dayStart))
          .where('start_at', isLessThan: Timestamp.fromDate(nextDayStart))
          .get();

      return Right(snapshot.docs.map(_bookingFromDoc).toList());
    } on FirebaseException catch (e) {
      return Left(e.message ?? 'Unable to load booked slots');
    } catch (e) {
      return Left('Unable to load booked slots: $e');
    }
  }

  @override
  Future<Either<String, Booking?>> findBookingById(String bookingId) async {
    try {
      final doc = await _bookings.doc(bookingId).get();
      if (!doc.exists) return const Right(null);
      return Right(_bookingFromDoc(doc));
    } on FirebaseException catch (e) {
      return Left(e.message ?? 'Unable to load the booking');
    } catch (e) {
      return Left('Unable to load the booking: $e');
    }
  }

  @override
  Stream<Booking?> streamBooking(String bookingId) {
    return _bookings.doc(bookingId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return _bookingFromDoc(doc);
    });
  }

  @override
  Future<Either<String, Set<String>>> findBookedStartTimes({
    required String designerId,
    required String date,
    required String timezone,
  }) async {
    final result = await findBookingsForDesignerOnDate(
      designerId,
      date,
      timezone,
    );

    return result.fold(
      (failure) => Left(failure),
      (bookings) => Right({
        for (final booking in bookings)
          if (booking.status.holdsSlot) booking.startTime,
      }),
    );
  }

  @override
  Future<Either<String, List<Booking>>> findScheduleConflicts({
    required String designerId,
    required int dayOfWeek,
    String? date,
  }) async {
    try {
      // Filtering status client-side keeps the composite index narrow.
      final snapshot = await _bookings
          .where('designer_id', isEqualTo: designerId)
          .where('day_of_week', isEqualTo: dayOfWeek)
          .where(
            'start_at',
            isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime.now().toUtc()),
          )
          .get();

      final conflicts = snapshot.docs
          .map(_bookingFromDoc)
          .where((booking) => booking.status.isUpcoming)
          .where((booking) => date == null || booking.date == date)
          .toList();

      conflicts.sort((a, b) {
        final aStart = a.startAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bStart = b.startAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return aStart.compareTo(bStart);
      });

      return Right(conflicts);
    } on FirebaseException catch (e) {
      return Left(e.message ?? 'Unable to check existing bookings');
    } catch (e) {
      return Left('Unable to check existing bookings: $e');
    }
  }

  @override
  Future<Either<String, Booking>> createBooking(
    CreateBookingRequest request,
  ) async {
    if (request.designerId.isEmpty || request.userId.isEmpty) {
      return const Left('You need to be signed in to book an appointment.');
    }

    try {
      // Queries are not allowed inside a transaction, so the designer-scoped
      // client record is resolved first. A deterministic id keeps the
      // auto-created record idempotent.
      final clientId = await _resolveClientId(
        designerId: request.designerId,
        userId: request.userId,
        providedClientId: request.clientId,
      );

      final bookingRef = _bookings.doc();
      final timezone = request.timezone.isEmpty
          ? await _designerTimezone(request.designerId)
          : request.timezone;
      final location = DesignerTimeZone.resolve(timezone);

      final startAt = DesignerTimeZone.toUtc(
        location: location,
        date: request.date,
        time: request.startTime,
      );
      final endAt = DesignerTimeZone.toUtc(
        location: location,
        date: request.date,
        time: request.endTime,
      );

      if (!startAt.isAfter(DateTime.now().toUtc())) {
        return const Left('That appointment time has already passed.');
      }

      final reservationRef = _reservations.doc(
        ReservationKey.forSlot(
          designerId: request.designerId,
          date: request.date,
          startTime: request.startTime,
        ),
      );

      final availabilityRef = _firestore
          .collection('designers')
          .doc(request.designerId)
          .collection('availability')
          .doc(request.dayOfWeek.toString());

      final exceptionRef = _firestore
          .collection('designers')
          .doc(request.designerId)
          .collection('availability_exceptions')
          .doc(request.date);

      final designerRef = _firestore
          .collection('designers')
          .doc(request.designerId);

      final clientRef = _firestore.collection('clients').doc(clientId);
      final relationshipRef = _firestore
          .collection('client_measurements')
          .doc(request.userId)
          .collection('clients')
          .doc(clientId);
      final userRef = _firestore.collection('users').doc(request.userId);

      final booking = await _firestore.runTransaction<Booking>((transaction) async {
        // ---- All reads happen before any write. -------------------------
        final designerDoc = await transaction.get(designerRef);
        final availabilityDoc = await transaction.get(availabilityRef);
        final exceptionDoc = await transaction.get(exceptionRef);
        final reservationDoc = await transaction.get(reservationRef);
        final clientDoc = await transaction.get(clientRef);
        final relationshipDoc = await transaction.get(relationshipRef);
        final userDoc = await transaction.get(userRef);

        final availability = availabilityDoc.exists
            ? DesignerAvailability.fromJson(availabilityDoc.data()!)
            : null;
        final exception = exceptionDoc.exists
            ? AvailabilityException.fromJson(exceptionDoc.data()!)
            : null;

        final effective = SlotSchedulingService.resolveEffective(
          weekly: availability,
          exception: exception,
        );

        if (!effective.isBookable) {
          throw const _BookingFailure(
            'The designer is not available at that time.',
          );
        }

        final slots = SlotSchedulingService.generateSlots(
          sessions: effective.sessions,
          durationMinutes: effective.durationMinutes,
        );

        final matchesSlot = slots.any(
          (slot) =>
              slot.startTime == request.startTime &&
              slot.endTime == request.endTime,
        );

        if (!matchesSlot) {
          throw const _BookingFailure(
            'That time is not part of the designer availability anymore.',
          );
        }

        final existingReservation = reservationDoc.exists
            ? SlotReservation.fromJson(reservationDoc.data()!)
            : null;

        if (existingReservation != null &&
            existingReservation.isActiveAt(DateTime.now().toUtc())) {
          throw const _BookingFailure(
            'That slot was just booked by someone else. Pick another time.',
          );
        }

        final now = DateTime.now().toUtc();
        final bookingId = bookingRef.id;

        final userData = userDoc.data() ?? const <String, dynamic>{};
        final clientData = clientDoc.data() ?? const <String, dynamic>{};

        // Prefer the designer-scoped client record; fall back to the user
        // profile when the client record is being created by this booking.
        final clientSnapshot = BookingClient(
          id: clientId,
          name: _firstNonEmpty([
            clientData['full_name'],
            clientData['name'],
            userData['full_name'],
            userData['user_name'],
          ]),
          avatar: _firstNonEmpty([
            clientData['image_url'],
            clientData['avatar'],
            userData['profile_image'],
          ]),
          mobileNumber: _firstNonEmpty([
            clientData['mobile_number'],
            userData['mobile_number'],
            userData['email'],
          ]),
        );

        final storedTimezone = designerDoc.data()?['timezone'];
        final resolvedTimezone = storedTimezone is String &&
                storedTimezone.isNotEmpty
            ? storedTimezone
            : (timezone.isEmpty ? location.name : timezone);

        final newBooking = Booking(
          uid: bookingId,
          designerId: request.designerId,
          userId: request.userId,
          clientId: clientId,
          date: request.date,
          dayOfWeek: request.dayOfWeek,
          startAt: startAt,
          endAt: endAt,
          startTime: request.startTime,
          endTime: request.endTime,
          timezone: resolvedTimezone,
          durationMinutes: effective.durationMinutes,
          status: BookingStatus.pending,
          client: clientSnapshot,
          notes: request.notes,
          createdAt: now,
          updatedAt: now,
        );

        final bookingPayload = newBooking.toJson()..remove('uid');

        // ---- Writes. ---------------------------------------------------
        transaction.set(bookingRef, bookingPayload);

        transaction.set(reservationRef, {
          'designer_id': request.designerId,
          'user_id': request.userId,
          'booking_id': bookingId,
          'start_at': Timestamp.fromDate(startAt),
          'end_at': Timestamp.fromDate(endAt),
          'status': SlotReservationStatus.reserved.name,
          'expires_at': Timestamp.fromDate(
            now.add(BookingPolicy.pendingReservationTtl),
          ),
          'created_at': Timestamp.fromDate(now),
        });

        if (!clientDoc.exists) {
          transaction.set(clientRef, {
            'uid': clientId,
            'created_by': request.designerId,
            'full_name': clientSnapshot.name,
            'mobile_number': clientSnapshot.mobileNumber,
            'image_url': clientSnapshot.avatar,
            'gender': (userData['gender'] ?? '').toString(),
            'created_date': Timestamp.fromDate(now),
            'updated_at': now.millisecondsSinceEpoch,
            'is_pinned': false,
          });
        }

        if (!relationshipDoc.exists) {
          transaction.set(relationshipRef, {
            'client_id': clientId,
            'designer_id': request.designerId,
            'is_default': false,
          });
        }

        return newBooking;
      });

      return Right(booking);
    } on _BookingFailure catch (e) {
      return Left(e.message);
    } on FirebaseException catch (e) {
      return Left(e.message ?? 'Unable to create the booking');
    } catch (e) {
      return Left('Unable to create the booking: $e');
    }
  }

  @override
  Future<Either<String, void>> updateBookingStatus({
    required String bookingId,
    required BookingStatus status,
    required String actorUserId,
    required bool actorIsDesigner,
  }) async {
    try {
      final bookingRef = _bookings.doc(bookingId);
      final bookingSnapshot = await bookingRef.get();
      if (!bookingSnapshot.exists) {
        return const Left('Booking not found.');
      }

      final booking = _bookingFromDoc(bookingSnapshot);
      final ownershipError = _validateActor(
        booking: booking,
        actorUserId: actorUserId,
        actorIsDesigner: actorIsDesigner,
      );
      if (ownershipError != null) return Left(ownershipError);

      final transitionError = _validateTransition(
        booking: booking,
        nextStatus: status,
        actorIsDesigner: actorIsDesigner,
      );
      if (transitionError != null) return Left(transitionError);

      final reservationRef = _reservations.doc(
        ReservationKey.forSlot(
          designerId: booking.designerId,
          date: booking.date,
          startTime: booking.startTime,
        ),
      );

      await _firestore.runTransaction((transaction) async {
        // Reads first.
        final reservationSnapshot = await transaction.get(reservationRef);
        final now = DateTime.now().toUtc();

        // Writes.
        transaction.update(bookingRef, {
          'status': status.value,
          'updated_at': Timestamp.fromDate(now),
        });

        if (reservationSnapshot.exists) {
          final reservation = SlotReservation.fromJson(
            reservationSnapshot.data() ?? const {},
          );
          if (reservation.bookingId == bookingId) {
            if (status == BookingStatus.declined ||
                status == BookingStatus.cancelled) {
              // Release the slot immediately.
              transaction.update(reservationRef, {
                'status': SlotReservationStatus.released.name,
                'expires_at': Timestamp.fromDate(now),
              });
            } else if (status == BookingStatus.confirmed) {
              // A confirmed booking holds the slot until the appointment ends.
              final holdsUntil = booking.endAt ?? now;
              transaction.update(reservationRef, {
                'status': SlotReservationStatus.reserved.name,
                'expires_at': Timestamp.fromDate(holdsUntil),
              });
            }
          }
        }
      });

      return const Right(null);
    } on FirebaseException catch (e) {
      return Left(e.message ?? 'Unable to update the booking');
    } catch (e) {
      return Left('Unable to update the booking: $e');
    }
  }

  String? _validateActor({
    required Booking booking,
    required String actorUserId,
    required bool actorIsDesigner,
  }) {
    if (actorUserId.isEmpty) return 'You need to be signed in.';
    if (actorIsDesigner) {
      if (booking.designerId != actorUserId) {
        return 'You can only manage bookings for your own appointments.';
      }
    } else if (booking.userId != actorUserId) {
      return 'You can only manage your own bookings.';
    }
    return null;
  }

  String? _validateTransition({
    required Booking booking,
    required BookingStatus nextStatus,
    required bool actorIsDesigner,
  }) {
    final current = booking.status;

    if (current == nextStatus) return 'That booking is already ${nextStatus.label.toLowerCase()}.';

    if (actorIsDesigner) {
      const allowed = <BookingStatus, List<BookingStatus>>{
        BookingStatus.pending: [
          BookingStatus.confirmed,
          BookingStatus.declined,
          BookingStatus.cancelled,
        ],
        BookingStatus.confirmed: [
          BookingStatus.completed,
          BookingStatus.noShow,
          BookingStatus.cancelled,
        ],
      };

      if (!(allowed[current] ?? const []).contains(nextStatus)) {
        return 'This booking cannot be moved from ${current.label} to '
            '${nextStatus.label}.';
      }
      return null;
    }

    // Client-side rules.
    if (nextStatus != BookingStatus.cancelled) {
      return 'You can only cancel a booking.';
    }

    final cancellable = current == BookingStatus.pending ||
        current == BookingStatus.confirmed;
    if (!cancellable) {
      return 'This booking can no longer be cancelled.';
    }

    if (current == BookingStatus.confirmed) {
      final startAt = booking.startAt;
      if (startAt != null) {
        final cutoff = startAt.subtract(BookingPolicy.clientCancellationCutoff);
        if (DateTime.now().toUtc().isAfter(cutoff)) {
          return 'This appointment can no longer be cancelled online. '
              'Please contact the designer.';
        }
      }
    }

    return null;
  }

  Future<String> _designerTimezone(String designerId) async {
    try {
      final doc = await _firestore.collection('designers').doc(designerId).get();
      final stored = doc.data()?['timezone'];
      if (stored is String && stored.isNotEmpty) return stored;
    } catch (_) {
      // Fall back below.
    }
    return '';
  }

  Future<String> _resolveClientId({
    required String designerId,
    required String userId,
    required String providedClientId,
  }) async {
    if (providedClientId.isNotEmpty) return providedClientId;

    final snapshot = await _firestore
        .collection('client_measurements')
        .doc(userId)
        .collection('clients')
        .where('designer_id', isEqualTo: designerId)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) return snapshot.docs.first.id;

    // Deterministic id so a retried booking cannot create two client records.
    return 'c_${designerId}_$userId';
  }
}

/// Returns the first non-empty trimmed string from [values].
String _firstNonEmpty(List<Object?> values) {
  for (final value in values) {
    final text = (value ?? '').toString().trim();
    if (text.isNotEmpty) return text;
  }
  return '';
}

class _BookingFailure implements Exception {
  final String message;

  const _BookingFailure(this.message);

  @override
  String toString() => message;
}
