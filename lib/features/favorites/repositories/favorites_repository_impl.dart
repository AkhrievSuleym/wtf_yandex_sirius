import 'dart:async';

import '../../../core/services/api_client.dart';
import '../../../core/utils/app_logger.dart';
import '../../profile/models/profile_model.dart';
import 'favorites_repository.dart';

class FavoritesRepositoryImpl implements FavoritesRepository {
  static const _tag = 'FavoritesRepository';

  final ApiClient _api;
  FavoritesRepositoryImpl(this._api);

  @override
  Future<List<ProfileModel>> fetchFavorites(String userId) async {
    AppLogger.d(_tag, 'fetchFavorites: userId=$userId');
    final response = await _api.dio.get('/users/$userId/favorites');
    final list = (response.data as List)
        .map((e) => ProfileModel.fromJson(e as Map<String, dynamic>))
        .toList();
    AppLogger.d(_tag, 'fetchFavorites: ${list.length} items');
    return list;
  }

  @override
  Stream<List<ProfileModel>> watchFavorites(String userId) async* {
    yield await fetchFavorites(userId);
  }

  @override
  Future<void> addToFavorites({
    required String userId,
    required ProfileModel profile,
  }) async {
    AppLogger.i(_tag, 'addToFavorites: @${profile.username}');
    await _api.dio.post(
      '/users/$userId/favorites',
      data: {'favoriteUid': profile.uid},
    );
  }

  @override
  Future<void> removeFromFavorites({
    required String userId,
    required String favoriteUid,
  }) async {
    AppLogger.i(_tag, 'removeFromFavorites: uid=$favoriteUid');
    await _api.dio.delete('/users/$userId/favorites/$favoriteUid');
  }

  @override
  Future<bool> isFavorite({
    required String userId,
    required String targetUid,
  }) async {
    AppLogger.d(_tag, 'isFavorite: target=$targetUid');
    final response =
        await _api.dio.get('/users/$userId/favorites/$targetUid/check');
    return response.data['isFavorite'] as bool;
  }
}
