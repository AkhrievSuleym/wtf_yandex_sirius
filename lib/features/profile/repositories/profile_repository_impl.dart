import 'dart:io';

import 'package:dio/dio.dart';

import '../../../core/services/api_client.dart';
import '../../../core/utils/app_logger.dart';
import '../models/profile_model.dart';
import 'profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  static const _tag = 'ProfileRepository';

  final ApiClient _api;

  // Bumped on every avatar upload to force cache invalidation.
  String? _avatarCacheBuster;

  ProfileRepositoryImpl(this._api);

  ProfileModel _toModel(Map<String, dynamic> json) {
    var m = ProfileModel.fromJson(json);
    if (_avatarCacheBuster != null && m.avatarUrl != null) {
      final u = m.avatarUrl!;
      m = m.copyWith(
        avatarUrl: '$u${u.contains('?') ? '&' : '?'}v=$_avatarCacheBuster',
      );
    }
    return m;
  }

  @override
  Future<ProfileModel> getProfile(String uid) async {
    AppLogger.d(_tag, 'getProfile: uid=$uid');
    final response = await _api.dio.get('/users/$uid');
    return _toModel(response.data as Map<String, dynamic>);
  }

  @override
  Future<void> updateProfile({
    String? displayName,
    String? bio,
    String? avatarPath,
  }) async {
    final uid = _api.currentUid;
    if (uid == null) throw Exception('Пользователь не авторизован');
    AppLogger.i(_tag, 'updateProfile: uid=$uid');

    if (avatarPath != null) {
      AppLogger.d(_tag, 'updateProfile: uploading avatar');
      final form = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          avatarPath,
          filename: File(avatarPath).uri.pathSegments.last,
        ),
      });
      await _api.dio.post('/users/$uid/avatar', data: form);
      _avatarCacheBuster = '${DateTime.now().millisecondsSinceEpoch}';
      AppLogger.d(_tag, 'updateProfile: avatar buster=$_avatarCacheBuster');
    }

    if (displayName != null || bio != null) {
      await _api.dio.put('/users/$uid', data: {
        if (displayName != null) 'displayName': displayName.trim(),
        if (bio != null) 'bio': bio.trim(),
      });
    }

    AppLogger.i(_tag, 'updateProfile: done');
  }

  @override
  Future<bool> isUsernameAvailable(String username) async {
    AppLogger.d(_tag, 'isUsernameAvailable: $username');
    final response = await _api.dio.get('/users/check/$username');
    return response.data['available'] as bool;
  }
}
