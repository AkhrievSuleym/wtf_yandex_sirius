import 'package:flutter/foundation.dart';

/// Centralized logger. In release builds all output is suppressed.
class AppLogger {
  AppLogger._();

  static void d(String tag, String message) {
    if (kDebugMode) debugPrint('🟢 [$tag] $message');
  }

  static void i(String tag, String message) {
    if (kDebugMode) debugPrint('🔵 [$tag] $message');
  }

  static void w(String tag, String message) {
    if (kDebugMode) debugPrint('🟡 [$tag] $message');
  }

  static void e(String tag, String message, [Object? error]) {
    if (kDebugMode) {
      debugPrint('🔴 [$tag] $message');
      if (error != null) debugPrint('   ↳ $error');
    }
  }
}
