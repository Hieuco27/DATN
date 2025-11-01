import 'package:flutter/material.dart';
import 'package:another_flushbar/flushbar.dart';

class NotificationService {
  static void showSuccess(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 2),
  }) {
    const color = Colors.green;
    Flushbar(
      message: message,
      icon: Container(
        width: 32,
        height: 32,
        decoration: const BoxDecoration(color: color, shape: BoxShape.circle),
        child: const Icon(Icons.check, size: 20, color: Colors.white),
      ),
      margin: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(12),
      duration: duration,
      flushbarPosition: FlushbarPosition.TOP,
      backgroundColor: Colors.white,
      messageColor: Colors.black87,
      messageSize: 14,
      boxShadows: [
        BoxShadow(
          color: color.withOpacity(0.3),
          offset: const Offset(0, 4),
          blurRadius: 12,
        ),
      ],
      borderColor: color,
      borderWidth: 1,
      isDismissible: true,
      dismissDirection: FlushbarDismissDirection.HORIZONTAL,
      forwardAnimationCurve: Curves.easeOutBack,
    ).show(context);
  }

  static void showError(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    const color = Colors.red;
    Flushbar(
      message: message,
      icon: Container(
        width: 32,
        height: 32,
        decoration: const BoxDecoration(color: color, shape: BoxShape.circle),
        child: const Icon(Icons.close, size: 20, color: Colors.white),
      ),
      margin: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(12),
      duration: duration,
      flushbarPosition: FlushbarPosition.TOP,
      backgroundColor: Colors.white,
      messageColor: Colors.black87,
      messageSize: 14,
      boxShadows: [
        BoxShadow(
          color: color.withOpacity(0.3),
          offset: const Offset(0, 4),
          blurRadius: 12,
        ),
      ],
      borderColor: color,
      borderWidth: 1,
      isDismissible: true,
      dismissDirection: FlushbarDismissDirection.HORIZONTAL,
      forwardAnimationCurve: Curves.easeOutBack,
    ).show(context);
  }

  static void showInfo(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 2),
  }) {
    const color = Colors.blue;
    Flushbar(
      message: message,
      icon: Container(
        width: 32,
        height: 32,
        decoration: const BoxDecoration(color: color, shape: BoxShape.circle),
        child: const Icon(Icons.info, size: 20, color: Colors.white),
      ),
      margin: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(12),
      duration: duration,
      flushbarPosition: FlushbarPosition.TOP,
      backgroundColor: Colors.white,
      messageColor: Colors.black87,
      messageSize: 14,
      boxShadows: [
        BoxShadow(
          color: color.withOpacity(0.3),
          offset: const Offset(0, 4),
          blurRadius: 12,
        ),
      ],
      borderColor: color,
      borderWidth: 1,
      isDismissible: true,
      dismissDirection: FlushbarDismissDirection.HORIZONTAL,
      forwardAnimationCurve: Curves.easeOutBack,
    ).show(context);
  }

  static void showWarning(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 2),
  }) {
    const color = Colors.orange;
    Flushbar(
      message: message,
      icon: Container(
        width: 32,
        height: 32,
        decoration: const BoxDecoration(color: color, shape: BoxShape.circle),
        child: const Icon(Icons.warning, size: 20, color: Colors.white),
      ),
      margin: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(12),
      duration: duration,
      flushbarPosition: FlushbarPosition.TOP,
      backgroundColor: Colors.white,
      messageColor: Colors.black87,
      messageSize: 14,
      boxShadows: [
        BoxShadow(
          color: color.withOpacity(0.3),
          offset: const Offset(0, 4),
          blurRadius: 12,
        ),
      ],
      borderColor: color,
      borderWidth: 1,
      isDismissible: true,
      dismissDirection: FlushbarDismissDirection.HORIZONTAL,
      forwardAnimationCurve: Curves.easeOutBack,
    ).show(context);
  }
}
