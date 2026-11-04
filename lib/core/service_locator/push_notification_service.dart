import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:fashionista/core/notifications/notification_navigator.dart';
import 'package:fashionista/core/service_locator/local_notification_service.dart';
import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/data/models/notification/device_registration_model.dart';
import 'package:fashionista/data/services/firebase/firebase_device_service.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Top-level FCM handler for messages received while the app is backgrounded or
/// terminated. Runs in its own isolate, so it must not touch UI, Hive or the
/// navigation layer.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint(
    'Background push received: ${message.messageId} '
    '(${message.data['type'] ?? 'unknown'})',
  );
}

/// Owns the FCM lifecycle: permission, token, device registration, foreground
/// presentation and tap routing.
///
/// Safe to call [initialize] more than once; listeners are registered once.
class PushNotificationService {
  PushNotificationService._();

  static const String _deviceIdKey = 'push_device_id';

  static bool _initialized = false;
  static StreamSubscription<String>? _tokenRefreshSubscription;
  static StreamSubscription<User?>? _authSubscription;
  static StreamSubscription<RemoteMessage>? _foregroundSubscription;
  static StreamSubscription<RemoteMessage>? _openedSubscription;
  static StreamSubscription<Map<String, dynamic>>? _localTapSubscription;

  static String? _deviceId;
  static String? _currentUserId;
  static String? _currentToken;

  static FirebaseMessaging get _messaging => FirebaseMessaging.instance;

  static FirebaseDeviceService get _deviceService =>
      sl<FirebaseDeviceService>();

  /// Test seam: lets unit tests observe payloads without navigation.
  @visibleForTesting
  static void debugResetForTest() {
    _initialized = false;
    _deviceId = null;
    _currentUserId = null;
    _currentToken = null;
    _tokenRefreshSubscription?.cancel();
    _authSubscription?.cancel();
    _foregroundSubscription?.cancel();
    _openedSubscription?.cancel();
    _localTapSubscription?.cancel();
  }

  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    await LocalNotificationService.init();
    _deviceId ??= await _loadOrCreateDeviceId();

    // Never block startup on the permission prompt.
    unawaited(_requestPermission());

    _foregroundSubscription = FirebaseMessaging.onMessage.listen(
      _handleForegroundMessage,
    );
    _openedSubscription = FirebaseMessaging.onMessageOpenedApp.listen(
      (message) => NotificationNavigator.open(message.data),
    );

    // Taps on notifications we presented ourselves (foreground messages).
    _localTapSubscription = LocalNotificationService.onNotificationTap.listen(
      NotificationNavigator.open,
    );

    _tokenRefreshSubscription = _messaging.onTokenRefresh.listen((token) {
      _currentToken = token;
      unawaited(_syncCurrentUser(token: token));
    });

    _authSubscription = FirebaseAuth.instance.authStateChanges().listen(
      _handleAuthChange,
    );

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      NotificationNavigator.open(initialMessage.data);
    }

    final launchPayload = LocalNotificationService.consumeLaunchPayload();
    if (launchPayload != null) {
      NotificationNavigator.open(launchPayload);
    }
  }

  /// Call before signing out: the device doc can only be written while the
  /// current user is still authenticated.
  static Future<void> onSignOut() async {
    final userId = _currentUserId ?? FirebaseAuth.instance.currentUser?.uid;
    final deviceId = _deviceId;
    if (userId == null || deviceId == null) return;

    await _deviceService.deactivateDevice(userId: userId, deviceId: deviceId);
    _currentUserId = null;
  }

  /// Deactivates the current device then forgets in-memory state.
  static Future<void> signOut() => onSignOut();

  static Future<void> _requestPermission() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('Push permission denied; in-app inbox still works.');
      }
    } catch (error) {
      debugPrint('Push permission request failed: $error');
    }
  }

  static void _handleAuthChange(User? user) {
    if (user == null) {
      // Best effort: the explicit sign-out hook normally handles this before
      // the credential disappears.
      final previous = _currentUserId;
      if (previous != null) {
        unawaited(_deactivateFor(previous));
        _currentUserId = null;
      }
      return;
    }

    if (user.uid == _currentUserId) {
      unawaited(_syncCurrentUser());
      return;
    }

    final previous = _currentUserId;
    _currentUserId = user.uid;

    unawaited(() async {
      if (previous != null && previous != user.uid) {
        await _deactivateFor(previous);
      }
      await _syncCurrentUser();
    }());
  }

  static Future<void> _deactivateFor(String userId) async {
    final deviceId = _deviceId;
    if (deviceId == null) return;
    await _deviceService.deactivateDevice(userId: userId, deviceId: deviceId);
  }

  static Future<void> _syncCurrentUser({String? token}) async {
    final user = FirebaseAuth.instance.currentUser;
    final deviceId = _deviceId;
    if (user == null || deviceId == null) return;

    final fcmToken = token ?? _currentToken ?? await _safeToken();
    if (fcmToken == null || fcmToken.isEmpty) return;

    _currentToken = fcmToken;
    _currentUserId = user.uid;

    final registration = DeviceRegistration(
      fcmToken: fcmToken,
      platform: _platformName,
      deviceName: _deviceName(),
      isActive: true,
      createdAt: DateTime.now().toUtc(),
    );

    await _deviceService.registerDevice(
      userId: user.uid,
      deviceId: deviceId,
      registration: registration,
    );
  }

  static Future<String?> _safeToken() async {
    try {
      return await _messaging.getToken();
    } catch (error) {
      debugPrint('Unable to obtain an FCM token: $error');
      return null;
    }
  }

  static Future<String> _loadOrCreateDeviceId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existing = prefs.getString(_deviceIdKey);
      if (existing != null && existing.isNotEmpty) return existing;

      final generated = const Uuid().v4();
      await prefs.setString(_deviceIdKey, generated);
      return generated;
    } catch (error) {
      debugPrint('Device id unavailable, using a session id: $error');
      return const Uuid().v4();
    }
  }

  /// Web is not a supported push target for this app, but the value must still
  /// be one of the platform strings the device rules accept.
  static String get _platformName {
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.android:
        return 'android';
      default:
        return 'android';
    }
  }

  static String _deviceName() {
    return _platformName == 'ios' ? 'iOS device' : 'Android device';
  }

  static void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    final title = notification?.title ?? message.data['title']?.toString();
    final body = notification?.body ?? message.data['body']?.toString();

    // Data-only pushes may legitimately carry no user-facing text.
    if ((title == null || title.isEmpty) && (body == null || body.isEmpty)) {
      // Still surface it to listeners (e.g. to refresh the inbox).
      return;
    }

    unawaited(
      LocalNotificationService.showForegroundNotification(
        title: title ?? 'Fashionista',
        body: body ?? '',
        data: message.data,
        id: message.messageId?.hashCode,
      ),
    );
  }
}
