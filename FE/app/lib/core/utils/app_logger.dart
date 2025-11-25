import 'package:flutter/foundation.dart';

/// Simple logger cho app - chỉ log trong debug mode
/// Không cần thêm dependencies
class AppLogger {
  // Singleton pattern
  static final AppLogger _instance = AppLogger._internal();
  factory AppLogger() => _instance;
  AppLogger._internal();

  /// Chỉ log khi đang trong debug mode
  bool get _shouldLog => kDebugMode;

  /// Log thông tin debug - tự động disable trong release mode
  void d(String message, [String? tag]) {
    if (_shouldLog) {
      final tagStr = tag != null ? '[$tag] ' : '';
      debugPrint('🔍 $tagStr$message');
    }
  }

  /// Log thông tin quan trọng
  void i(String message, [String? tag]) {
    if (_shouldLog) {
      final tagStr = tag != null ? '[$tag] ' : '';
      debugPrint('ℹ️ $tagStr$message');
    }
  }

  /// Log warning
  void w(String message, [String? tag]) {
    if (_shouldLog) {
      final tagStr = tag != null ? '[$tag] ' : '';
      debugPrint('⚠️ $tagStr$message');
    }
  }

  /// Log error - luôn log cả trong release mode
  void e(String message, [Object? error, String? tag]) {
    final tagStr = tag != null ? '[$tag] ' : '';
    debugPrint('❌ $tagStr$message');
    if (error != null) {
      debugPrint('  └─ Error: $error');
    }
  }
}

// Global instance
final log = AppLogger();
