import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class AppToast {
  AppToast._();

  static void _show(
    BuildContext context,
    String message,
    Color backgroundColor,
    Color textColor,
  ) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final bottomOffset = keyboardHeight > 0
        ? 80 + (keyboardHeight / 2)
        : 80; // adjust above keyboard

    final fToast = FToast();
    fToast.init(context);

    fToast.showToast(
      gravity: ToastGravity.BOTTOM,
      toastDuration: const Duration(seconds: 2),
      child: Container(
        margin: EdgeInsets.only(bottom: bottomOffset.toDouble()),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: backgroundColor.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(color: textColor, fontSize: 14),
        ),
      ),
    );
  }

  /// 🔵 Info toast
  static void info(BuildContext context, String message) {
    final colorScheme = Theme.of(context).colorScheme;
    _show(context, message, colorScheme.primary, colorScheme.onPrimary);
  }

  /// ✅ Success toast
  static void success(BuildContext context, String message) {
    _show(context, message, Colors.green.shade600, Colors.white);
  }

  /// ❌ Error toast
  static void error(BuildContext context, String message) {
    _show(context, message, Colors.red.shade600, Colors.white);
  }

  /// ⚪ Neutral toast
  static void normal(BuildContext context, String message) {
    final colorScheme = Theme.of(context).colorScheme;
    _show(context, message, colorScheme.surfaceVariant, colorScheme.onSurface);
  }
}
