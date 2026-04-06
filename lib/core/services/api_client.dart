import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';
import '../utils/app_logger.dart';

class ApiClient {
  static const _tokenKey = 'auth_token';
  static const _uidKey = 'auth_uid';
  static const _userCacheKey = 'cached_user_json';
  static const _tag = 'ApiClient';

  final Dio dio;
  final FlutterSecureStorage _storage;
  final SharedPreferences _prefs;

  String? _cachedToken;
  String? _cachedUid;

  ApiClient(this._storage, this._prefs)
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
          final t = _cachedToken;
          if (t != null) options.headers['Authorization'] = 'Bearer $t';
          handler.next(options);
        },
        onError: (err, handler) {
          AppLogger.e(
              _tag,
              'HTTP ${err.response?.statusCode} ${err.requestOptions.path}',
              err);
          handler.next(err);
        },
      ),
    );
  }

  String? get token => _cachedToken;
  String? get currentUid => _cachedUid;
  bool get isLoggedIn => _cachedToken != null;

  Future<void> init() async {
    _cachedToken = await _storage.read(key: _tokenKey);
    _cachedUid = await _storage.read(key: _uidKey);
    AppLogger.d(_tag, 'init: isLoggedIn=$isLoggedIn');
  }

  Future<void> saveCredentials(String uid, String token) async {
    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _uidKey, value: uid);
    _cachedToken = token;
    _cachedUid = uid;
  }

  Future<void> clearCredentials() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _uidKey);
    await _prefs.remove(_userCacheKey);
    _cachedToken = null;
    _cachedUid = null;
  }

  Future<void> cacheUserJson(Map<String, dynamic> json) async {
    await _prefs.setString(_userCacheKey, jsonEncode(json));
  }

  Map<String, dynamic>? getCachedUserJson() {
    final raw = _prefs.getString(_userCacheKey);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }
}
