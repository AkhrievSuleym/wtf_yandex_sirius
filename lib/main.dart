import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'app/app.dart';
import 'app/di/injection.dart';
import 'core/utils/app_logger.dart';
import 'features/notifications/notification_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  AppLogger.i('main', 'App starting');

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  AppLogger.i('main', 'Firebase initialized');

  // Register FCM background handler before runApp
  NotificationService.registerBackgroundHandler();

  await setupDependencies();
  AppLogger.i('main', 'DI ready');

  runApp(const App());
}
