import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';
import '../utils/app_logger.dart';

class ApiClient {
  static const _tokenKey = 'auth_token';
  static const _uidKey = 'auth_uid';
  static const _tag = 'ApiClient';

  final Dio dio;
  final SharedPreferences _prefs;

  ApiClient(this._prefs)
      : dio = Dio(
          BaseOptions(
            baseUrl: ApiConstants.baseUrl,
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 15),
            headers: {'Content-Type': 'application/json'},
          ),
        ) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final t = token;
          if (t != null) options.headers['Authorization'] = 'Bearer $t';
          handler.next(options);
        },
        onError: (err, handler) {
          AppLogger.e(_tag, 'HTTP ${err.response?.statusCode} ${err.requestOptions.path}', err);
          handler.next(err);
        },
      ),
    );
  }

  String? get token => _prefs.getString(_tokenKey);
  String? get currentUid => _prefs.getString(_uidKey);
  bool get isLoggedIn => token != null;

  Future<void> saveCredentials(String uid, String token) async {
    await _prefs.setString(_tokenKey, token);
    await _prefs.setString(_uidKey, uid);
  }

  Future<void> clearCredentials() async {
    await _prefs.remove(_tokenKey);
    await _prefs.remove(_uidKey);
  }
}
