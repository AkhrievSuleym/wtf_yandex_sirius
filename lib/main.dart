import 'package:flutter/material.dart';
import 'app/app.dart';
import 'app/di/injection.dart';
import 'core/utils/app_logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppLogger.i('main', 'App starting');
  await setupDependencies();
  AppLogger.i('main', 'DI ready');
  runApp(const App());
}
