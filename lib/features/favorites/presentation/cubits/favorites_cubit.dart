import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../profile/models/profile_model.dart';
import '../../repositories/favorites_repository.dart';
import 'favorites_state.dart';

class FavoritesCubit extends Cubit<FavoritesState> {
  static const _tag = 'FavoritesCubit';

  final FavoritesRepository _favoritesRepository;
  StreamSubscription? _subscription;
  String? _currentUserId;

  FavoritesCubit(this._favoritesRepository) : super(const FavoritesInitial());

  void subscribeFavorites(String userId) {
    if (userId.isEmpty) {
      AppLogger.w(_tag, 'subscribeFavorites: empty userId, skip');
      return;
    }
    AppLogger.i(_tag, 'subscribeFavorites: userId=$userId');
    _currentUserId = userId;
    emit(const FavoritesLoading());
    _subscription?.cancel();
    _subscription = _favoritesRepository.watchFavorites(userId).listen(
      (favorites) {
        AppLogger.d(_tag, 'favorites updated: ${favorites.length} items');
        emit(FavoritesLoaded(favorites));
      },
      onError: (e) {
        AppLogger.e(_tag, 'favorites stream error', e);
        emit(FavoritesError(e.toString()));
      },
    );
  }

  Future<void> addToFavorites(ProfileModel profile) async {
    if (_currentUserId == null) return;
    AppLogger.i(_tag, 'addToFavorites: @${profile.username}');
    try {
      await _favoritesRepository.addToFavorites(
        userId: _currentUserId!,
        profile: profile,
      );
    } catch (e) {
      AppLogger.e(_tag, 'addToFavorites failed', e);
      emit(FavoritesError(e.toString()));
    }
  }

  Future<void> removeFromFavorites(String uid) async {
    if (_currentUserId == null) return;
    AppLogger.i(_tag, 'removeFromFavorites: uid=$uid');
    try {
      await _favoritesRepository.removeFromFavorites(
        userId: _currentUserId!,
        favoriteUid: uid,
      );
    } catch (e) {
      AppLogger.e(_tag, 'removeFromFavorites failed', e);
      emit(FavoritesError(e.toString()));
    }
  }

  Future<bool> isFavorite(String targetUid) async {
    if (_currentUserId == null) return false;
    AppLogger.d(_tag, 'isFavorite: targetUid=$targetUid');
    return _favoritesRepository.isFavorite(
      userId: _currentUserId!,
      targetUid: targetUid,
    );
  }

  @override
  Future<void> close() {
    AppLogger.d(_tag, 'close');
    _subscription?.cancel();
    return super.close();
  }
}
