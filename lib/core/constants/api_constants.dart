class ApiConstants {
  ApiConstants._();

  /// Override at build time:
  ///   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080   (Android emulator)
  ///   flutter run --dart-define=API_BASE_URL=http://192.168.1.x:8080 (physical device)
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );
}
