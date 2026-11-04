import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

/// Thin wrapper around `flutter_local_notifications`.
///
/// Responsibilities:
///  * register the Android channels used by the app,
///  * present foreground FCM messages as system notifications,
///  * surface taps (including a cold-start tap) as a stream,
///  * keep the existing outfit-plan reminders working.
///
/// Push permission is requested by `PushNotificationService`, never here, so
/// the two flows cannot double-prompt.
class LocalNotificationService {
  LocalNotificationService._();

  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static const String generalChannelId = 'fashionista_general';
  static const String remindersChannelId = 'outfit_plan_channel';
  static const String _defaultIcon = '@mipmap/ic_launcher';

  static const AndroidNotificationChannel _generalChannel =
      AndroidNotificationChannel(
        generalChannelId,
        'General',
        description: 'Appointments, orders and account activity',
        importance: Importance.high,
      );

  static const AndroidNotificationChannel _remindersChannel =
      AndroidNotificationChannel(
        remindersChannelId,
        'Outfit Plan Reminders',
        description: 'Reminders for your planned outfits',
        importance: Importance.max,
      );

  static final StreamController<Map<String, dynamic>> _taps =
      StreamController<Map<String, dynamic>>.broadcast();

  static bool _initialized = false;
  static Map<String, dynamic>? _pendingLaunchPayload;

  /// Emits the decoded `data` map of a tapped notification.
  static Stream<Map<String, dynamic>> get onNotificationTap => _taps.stream;

  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    const android = AndroidInitializationSettings(_defaultIcon);
    const iOS = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _notifications.initialize(
      const InitializationSettings(android: android, iOS: iOS),
      onDidReceiveNotificationResponse: (response) {
        final payload = parsePayload(response.payload);
        if (payload.isNotEmpty) _taps.add(payload);
      },
      onDidReceiveBackgroundNotificationResponse: _backgroundTapHandler,
    );

    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.createNotificationChannel(_generalChannel);
    await androidPlugin?.createNotificationChannel(_remindersChannel);

    final launch = await _notifications.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp ?? false) {
      final payload = parsePayload(launch?.notificationResponse?.payload);
      if (payload.isNotEmpty) _pendingLaunchPayload = payload;
    }
  }

  /// Payload of the notification that cold-started the app, consumed once.
  static Map<String, dynamic>? consumeLaunchPayload() {
    final payload = _pendingLaunchPayload;
    _pendingLaunchPayload = null;
    return payload;
  }

  /// Presents a foreground message as a system notification.
  static Future<void> showForegroundNotification({
    required String title,
    required String body,
    Map<String, dynamic> data = const {},
    int? id,
  }) async {
    final notificationId =
        id ?? DateTime.now().millisecondsSinceEpoch.remainder(1 << 31);

    await _notifications.show(
      notificationId,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          generalChannelId,
          'General',
          channelDescription: 'Appointments, orders and account activity',
          importance: Importance.high,
          priority: Priority.high,
          icon: _defaultIcon,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: encodePayload(data),
    );
  }

  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    DateTime? scheduledDate,
  }) async {
    final scheduleTime =
        scheduledDate ?? DateTime.now().add(const Duration(minutes: 1));

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduleTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          remindersChannelId,
          'Outfit Plan Reminders',
          channelDescription: 'Reminders for your planned outfits',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          subtitle: 'Reminders for outfit plans',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<void> cancel(int id) => _notifications.cancel(id);

  /// Parses a JSON payload string into a string-keyed map.
  static Map<String, dynamic> parsePayload(String? raw) {
    if (raw == null || raw.isEmpty) return const {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return decoded.map((key, value) => MapEntry(key.toString(), value));
      }
    } catch (error) {
      debugPrint('Notification payload ignored: $error');
    }
    return const {};
  }

  /// Encodes notification data as a JSON payload string.
  static String encodePayload(Map<String, dynamic> data) {
    if (data.isEmpty) return '';
    return jsonEncode(data.map((key, value) => MapEntry(key, '$value')));
  }
}

/// Runs in a background isolate: no UI, no navigation, no plugins.
@pragma('vm:entry-point')
void _backgroundTapHandler(NotificationResponse response) {
  // Taps are handled in the main isolate when the app resumes.
}
