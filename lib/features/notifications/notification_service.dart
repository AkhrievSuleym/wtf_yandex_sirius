import 'package:flutter/material.dart';
import '../../core/utils/app_logger.dart';

/// Stub: Firebase Messaging removed. Push notifications can be re-added
/// via a self-hosted solution (e.g. ntfy, OneSignal) when needed.
class NotificationService {
  static const _tag = 'NotificationService';

  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  static void registerBackgroundHandler() {
    AppLogger.i(_tag, 'registerBackgroundHandler: no-op (FCM removed)');
  }

  Future<void> init({required GlobalKey<NavigatorState> navigatorKey}) async {
    AppLogger.i(_tag, 'init: no-op (FCM removed)');
  }

  void dispose() {}
}
