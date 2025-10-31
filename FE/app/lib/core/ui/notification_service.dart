import 'package:flutter/material.dart';
import 'package:another_flushbar/flushbar.dart';

class NotificationService {
  static Future<void> showSuccess(
    BuildContext context, {
    required String message,
    String? title,
  }) async {
    final overlayContext =
        Navigator.of(context, rootNavigator: true).overlay?.context ?? context;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Flushbar(
        title: title,
        message: message,
        icon: const Icon(Icons.check_circle_rounded, color: Colors.white),
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.all(12),
        borderRadius: BorderRadius.circular(12),
        backgroundGradient: const LinearGradient(
          colors: [Color(0xFF00C853), Color(0xFF64DD17)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadows: const [
          BoxShadow(
            color: Color(0x33000000),
            offset: Offset(0, 6),
            blurRadius: 12,
          ),
        ],
        flushbarPosition: FlushbarPosition.TOP,
      ).show(overlayContext);
    });
  }

  static Future<void> showError(
    BuildContext context, {
    required String message,
    String? title,
  }) async {
    final overlayContext =
        Navigator.of(context, rootNavigator: true).overlay?.context ?? context;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Flushbar(
        title: title,
        message: message,
        icon: const Icon(Icons.error_rounded, color: Colors.white),
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(12),
        borderRadius: BorderRadius.circular(12),
        backgroundGradient: const LinearGradient(
          colors: [Color(0xFFFF1744), Color(0xFFFF5252)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadows: const [
          BoxShadow(
            color: Color(0x33000000),
            offset: Offset(0, 6),
            blurRadius: 12,
          ),
        ],
        flushbarPosition: FlushbarPosition.TOP,
      ).show(overlayContext);
    });
  }

  static Future<void> showInfo(
    BuildContext context, {
    required String message,
    String? title,
  }) async {
    final overlayContext =
        Navigator.of(context, rootNavigator: true).overlay?.context ?? context;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Flushbar(
        title: title,
        message: message,
        icon: const Icon(Icons.info_rounded, color: Colors.white),
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.all(12),
        borderRadius: BorderRadius.circular(12),
        backgroundGradient: const LinearGradient(
          colors: [Color(0xFF2979FF), Color(0xFF00B0FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadows: const [
          BoxShadow(
            color: Color(0x33000000),
            offset: Offset(0, 6),
            blurRadius: 12,
          ),
        ],
        flushbarPosition: FlushbarPosition.TOP,
      ).show(overlayContext);
    });
  }
}
