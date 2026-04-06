import 'package:dio/dio.dart';
import '../../../core/services/api_client.dart';
import '../../../core/utils/app_logger.dart';
import '../models/user_model.dart';
import 'auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  static const _tag = 'AuthRepository';

  final ApiClient _api;

  AuthRepositoryImpl(this._api);

  @override
  Stream<UserModel?> authStateChanges() async* {
    AppLogger.d(_tag, 'authStateChanges: reading stored credentials');
    yield await getCurrentUser();
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    final uid = _api.currentUid;
    if (uid == null) {
      AppLogger.d(_tag, 'getCurrentUser: no stored uid');
      return null;
    }
    AppLogger.d(_tag, 'getCurrentUser: uid=$uid');
    try {
      final response = await _api.dio.get('/users/$uid');
      final json = response.data as Map<String, dynamic>;
      await _api.cacheUserJson(json);
      return UserModel.fromJson(json);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        AppLogger.w(_tag, 'getCurrentUser: user not found, clearing credentials');
        await _api.clearCredentials();
        return null;
      }
      AppLogger.w(_tag, 'getCurrentUser: no network, trying local cache');
      final cached = _api.getCachedUserJson();
      if (cached != null) {
        AppLogger.i(_tag, 'getCurrentUser: serving from local cache');
        return UserModel.fromJson(cached);
      }
      AppLogger.e(_tag, 'getCurrentUser failed, no cache', e);
      rethrow;
    }
  }

  @override
  Future<UserModel> signUpAnonymous() async {
    AppLogger.i(_tag, 'signUpAnonymous: starting');
    try {
      final response = await _api.dio.post('/auth/anonymous');
      final uid = response.data['uid'] as String;
      final token = response.data['token'] as String;
      await _api.saveCredentials(uid, token);
      AppLogger.i(_tag, 'signUpAnonymous: success uid=$uid');
      return UserModel.empty(uid: uid);
    } on DioException catch (e) {
      AppLogger.e(_tag, 'signUpAnonymous failed', e);
      throw Exception('Ошибка входа. Попробуйте ещё раз.');
    }
  }

  @override
  Future<UserModel> loginWithPassword({
    required String username,
    required String password,
  }) async {
    AppLogger.i(_tag, 'loginWithPassword: username=$username');
    try {
      final response = await _api.dio.post('/auth/login', data: {
        'username': username.toLowerCase().trim(),
        'password': password,
      });
      final uid = response.data['uid'] as String;
      final token = response.data['token'] as String;
      await _api.saveCredentials(uid, token);
      AppLogger.i(_tag, 'loginWithPassword: success uid=$uid');
      final user = await getCurrentUser();
      return user!;
    } on DioException catch (e) {
      AppLogger.e(_tag, 'loginWithPassword failed', e);
      final msg = e.response?.data?.toString() ?? 'Ошибка входа';
      throw Exception(msg);
    }
  }

  @override
  Future<void> createProfile({
    required String username,
    required String displayName,
    required String bio,
  }) async {
    AppLogger.i(_tag, 'createProfile: username=$username');
    try {
      await _api.dio.post('/users', data: {
        'username': username.toLowerCase().trim(),
        'displayName': displayName.trim(),
        'bio': bio.trim(),
      });
      AppLogger.i(_tag, 'createProfile: done');
    } on DioException catch (e) {
      AppLogger.e(_tag, 'createProfile failed', e);
      if (e.response?.statusCode == 409) {
        throw Exception('Этот никнейм уже занят');
      }
      throw Exception('Ошибка создания профиля. Попробуйте ещё раз.');
    }
  }

  @override
  Future<void> setPassword(String password) async {
    AppLogger.i(_tag, 'setPassword');
    try {
      await _api.dio.put('/auth/password', data: {'password': password});
    } on DioException catch (e) {
      AppLogger.e(_tag, 'setPassword failed', e);
      final msg = e.response?.data?.toString() ?? 'Ошибка установки пароля';
      throw Exception(msg);
    }
  }

  @override
  Future<bool> isUsernameAvailable(String username) async {
    AppLogger.d(_tag, 'isUsernameAvailable: $username');
    try {
      final response = await _api.dio.get('/users/check/$username');
      return response.data['available'] as bool;
    } on DioException catch (e) {
      AppLogger.e(_tag, 'isUsernameAvailable failed', e);
      return false;
    }
  }

  @override
  Future<void> signOut() async {
    AppLogger.i(_tag, 'signOut');
    await _api.clearCredentials();
  }

  @override
  Future<void> deleteAccount() async {
    final uid = _api.currentUid;
    AppLogger.w(_tag, 'deleteAccount: uid=$uid');
    if (uid == null) return;
    await _api.dio.delete('/users/$uid');
    await _api.clearCredentials();
    AppLogger.i(_tag, 'deleteAccount: done');
  }
}
