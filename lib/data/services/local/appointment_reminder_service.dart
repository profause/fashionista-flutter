import 'package:fashionista/core/service_locator/local_notification_service.dart';
import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/data/models/bookings/booking_model.dart';
import 'package:fashionista/data/models/bookings/booking_status.dart';
import 'package:fashionista/data/models/notification/notification_preferences.dart';
import 'package:fashionista/data/services/firebase/firebase_notification_preferences_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

/// Callback shape injected so tests never touch the notification plugin.
typedef ScheduleLocalNotification =
    Future<void> Function({
      required int id,
      required String title,
      required String body,
      required DateTime scheduledDate,
      required Map<String, dynamic> data,
    });

typedef CancelLocalNotification = Future<void> Function(int id);

/// Schedules the local "your appointment starts in 5 minutes" reminder.
///
/// Local notifications only fire on the device that scheduled them, so this is
/// deliberately device-scoped: the designer's phone gets its reminder when the
/// designer confirms, and the client's phone gets one the next time its booking
/// list shows the confirmed appointment.
///
/// The `appointment_reminder` preference is read before anything is scheduled,
/// and a disabled preference cancels an already-scheduled reminder instead of
/// leaving a stale one behind.
class AppointmentReminderService {
  AppointmentReminderService({
    ScheduleLocalNotification? schedule,
    CancelLocalNotification? cancel,
    Future<bool> Function()? remindersEnabled,
    DateTime Function()? now,
  }) : _schedule = schedule ?? _scheduleWithPlugin,
       _cancel = cancel ?? LocalNotificationService.cancel,
       _remindersEnabled = remindersEnabled ?? _readPreference,
       _now = now ?? DateTime.now;

  /// How long before the appointment the reminder fires.
  static const Duration leadTime = Duration(minutes: 5);

  final ScheduleLocalNotification _schedule;
  final CancelLocalNotification _cancel;
  final Future<bool> Function() _remindersEnabled;
  final DateTime Function() _now;

  static Future<void> _scheduleWithPlugin({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    required Map<String, dynamic> data,
  }) {
    return LocalNotificationService.scheduleNotification(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      channel: LocalNotificationChannel.appointments,
      // An appointment happens once; the default daily repeat would nag.
      matchDateTimeComponents: null,
      data: data,
    );
  }

  /// Reads the signed-in user's `appointment_reminder` preference.
  ///
  /// Fails closed: if the preference cannot be read we do not deliver a
  /// reminder the user may have switched off.
  static Future<bool> _readPreference() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null || userId.isEmpty) return false;

    final result = await sl<FirebaseNotificationPreferencesService>()
        .fetchPreferences(userId);

    return result.fold(
      (error) {
        debugPrint('Appointment reminder skipped: $error');
        return false;
      },
      (preferences) =>
          preferences.isEnabled(NotificationPreferenceKey.appointmentReminder),
    );
  }

  /// Stable id for a booking's reminder.
  ///
  /// FNV-1a over the booking id: `String.hashCode` is not guaranteed to be the
  /// same across app launches, so it could not cancel a reminder scheduled in
  /// an earlier session.
  static int notificationIdFor(String bookingId) {
    var hash = 0x811c9dc5;
    for (final unit in bookingId.codeUnits) {
      hash = ((hash ^ unit) * 0x01000193) & 0x7fffffff;
    }
    return hash;
  }

  /// Schedules or cancels the reminder for [booking].
  ///
  /// Returns `true` when a reminder is now scheduled. [prefEnabled] short-cuts
  /// the preference read when the caller already knows the answer.
  Future<bool> syncBooking(
    Booking booking, {
    required String currentUserId,
    bool? prefEnabled,
  }) async {
    final bookingId = booking.uid;
    if (bookingId == null || bookingId.isEmpty) return false;

    final id = notificationIdFor(bookingId);

    if (!_isParticipant(booking, currentUserId) ||
        !_reminderIsUpcoming(booking)) {
      await _safeCancel(id);
      return false;
    }

    final bool enabled;
    try {
      enabled = prefEnabled ?? await _remindersEnabled();
    } catch (error) {
      // Fail closed: never deliver a reminder the user may have switched off.
      debugPrint('Appointment reminder preference unavailable: $error');
      await _safeCancel(id);
      return false;
    }

    if (!enabled) {
      await _safeCancel(id);
      return false;
    }

    final startAt = booking.startAt!.toLocal();
    final isForDesigner = booking.userId != currentUserId;

    // A denied notification permission or a refused exact-alarm request must
    // never surface as a failed booking action, so scheduling is best effort.
    try {
      await _schedule(
        id: id,
        title: 'Appointment reminder',
        body: _body(booking, startAt, forDesigner: isForDesigner),
        scheduledDate: startAt.subtract(leadTime),
        data: {
          'type': 'appointment',
          'event': 'appointment_reminder',
          'booking_id': bookingId,
          'designer_id': booking.designerId,
          'audience': booking.userId == currentUserId ? 'client' : 'designer',
        },
      );
      return true;
    } catch (error) {
      debugPrint('Appointment reminder could not be scheduled: $error');
      return false;
    }
  }

  Future<void> _safeCancel(int id) async {
    try {
      await _cancel(id);
    } catch (error) {
      debugPrint('Appointment reminder could not be cancelled: $error');
    }
  }

  /// Reconciles every booking in a list, reading the preference at most once.
  ///
  /// Called after a bookings list loads so a client's device picks up an
  /// appointment the designer confirmed while the app was closed, and so
  /// reminders for cancelled or past appointments do not linger.
  Future<void> syncAll(
    Iterable<Booking> bookings, {
    required String currentUserId,
  }) async {
    if (currentUserId.isEmpty) return;

    bool? enabled;

    for (final booking in bookings) {
      // Only a confirmed, future appointment needs the preference; anything
      // else is a cancellation and must not trigger a read.
      final needsReminder =
          _isParticipant(booking, currentUserId) &&
          _reminderIsUpcoming(booking);

      if (needsReminder && enabled == null) {
        enabled = await _remindersEnabled();
      }

      await syncBooking(
        booking,
        currentUserId: currentUserId,
        prefEnabled: needsReminder ? enabled : false,
      );
    }
  }

  /// Cancels the reminder of a booking that was cancelled or completed.
  Future<void> cancelFor(String bookingId) async {
    if (bookingId.isEmpty) return;
    await _safeCancel(notificationIdFor(bookingId));
  }

  bool _isParticipant(Booking booking, String userId) {
    if (userId.isEmpty) return false;
    return booking.userId == userId || booking.designerId == userId;
  }

  bool _reminderIsUpcoming(Booking booking) {
    if (booking.status != BookingStatus.confirmed) return false;

    final startAt = booking.startAt;
    if (startAt == null) return false;

    return startAt.toLocal().isAfter(_now().add(leadTime));
  }

  String _body(
    Booking booking,
    DateTime startAtLocal, {
    required bool forDesigner,
  }) {
    final time = DateFormat.jm().format(startAtLocal);
    final today = _now();

    final isToday =
        startAtLocal.year == today.year &&
        startAtLocal.month == today.month &&
        startAtLocal.day == today.day;

    // Naming the client only helps the designer; to the client it would read
    // as "your appointment with yourself".
    final who = forDesigner ? (booking.client?.name.trim() ?? '') : '';
    final subject = who.isEmpty
        ? 'your appointment'
        : 'your appointment with $who';

    return isToday
        ? '$subject starts at $time.'
        : '$subject is on ${DateFormat.MMMd().format(startAtLocal)} at $time.';
  }
}
