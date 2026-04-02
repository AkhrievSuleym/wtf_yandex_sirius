import '../../profile/models/profile_model.dart';

abstract class FavoritesRepository {
  Stream<List<ProfileModel>> watchFavorites(String userId);
  Future<void> addToFavorites({
    required String userId,
    required ProfileModel profile,
  });
  Future<void> removeFromFavorites({
    required String userId,
    required String favoriteUid,
  });
  Future<bool> isFavorite({
    required String userId,
    required String targetUid,
  });
}
