import 'package:fashionista/core/notifications/notification_router.dart';
import 'package:fashionista/core/routes/app_router.dart';
import 'package:flutter/foundation.dart';

/// Performs the navigation decided by [NotificationRouter].
///
/// Guarantees:
///  * nothing happens before the router is ready (the app sets [markReady]
///    after the first frame),
///  * the same payload delivered through two lifecycle callbacks (for example
///    `onMessageOpenedApp` and `getInitialMessage` on cold start) navigates
///    once.
class NotificationNavigator {
  NotificationNavigator._();

  static bool _ready = false;
  static String? _lastPayloadKey;
  static DateTime? _lastHandledAt;

  /// Two deliveries of the same payload inside this window are treated as one.
  static const Duration duplicateWindow = Duration(seconds: 2);

  static void markReady() {
    _ready = true;
    flushPending();
  }

  static Map<String, dynamic>? _pending;

  static bool get isReady => _ready;

  /// Navigation requested before the router was ready is replayed once.
  static void open(Map<String, dynamic> data) {
    if (data.isEmpty) return;

    if (!_ready) {
      _pending = data;
      return;
    }

    final key = _keyOf(data);
    final now = DateTime.now();
    final isDuplicate =
        key == _lastPayloadKey &&
        _lastHandledAt != null &&
        now.difference(_lastHandledAt!) < duplicateWindow;

    if (isDuplicate) {
      debugPrint('Notification tap ignored (duplicate)');
      return;
    }

    _lastPayloadKey = key;
    _lastHandledAt = now;

    final destination = NotificationRouter.resolve(data);
    appRouter.push(destination.path);
  }

  /// Replays a tap that arrived before the router was mounted.
  static void flushPending() {
    final pending = _pending;
    if (pending == null) return;
    _pending = null;
    open(pending);
  }

  /// Test/account-switch helper.
  static void reset() {
    _ready = false;
    _pending = null;
    _lastPayloadKey = null;
    _lastHandledAt = null;
  }

  static String _keyOf(Map<String, dynamic> data) {
    return [
      data['type'],
      data['event'],
      data['ref_id'],
      data['refId'],
      data['booking_id'],
      data['work_order_id'],
    ].where((value) => value != null && '$value'.isNotEmpty).join('|');
  }
}
