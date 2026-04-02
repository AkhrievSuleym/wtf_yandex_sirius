import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../profile/models/profile_model.dart';
import '../../repositories/favorites_repository.dart';
import 'favorites_state.dart';

class FavoritesCubit extends Cubit<FavoritesState> {
  final FavoritesRepository _favoritesRepository;
  StreamSubscription? _subscription;
  String? _currentUserId;

  FavoritesCubit(this._favoritesRepository) : super(const FavoritesInitial());

  void subscribeFavorites(String userId) {
    _currentUserId = userId;
    emit(const FavoritesLoading());
    _subscription?.cancel();
    _subscription =
        _favoritesRepository.watchFavorites(userId).listen(
      (favorites) => emit(FavoritesLoaded(favorites)),
      onError: (e) => emit(FavoritesError(e.toString())),
    );
  }

  Future<void> addToFavorites(ProfileModel profile) async {
    if (_currentUserId == null) return;
    try {
      await _favoritesRepository.addToFavorites(
        userId: _currentUserId!,
        profile: profile,
      );
    } catch (e) {
      emit(FavoritesError(e.toString()));
    }
  }

  Future<void> removeFromFavorites(String uid) async {
    if (_currentUserId == null) return;
    try {
      await _favoritesRepository.removeFromFavorites(
        userId: _currentUserId!,
        favoriteUid: uid,
      );
    } catch (e) {
      emit(FavoritesError(e.toString()));
    }
  }

  Future<bool> isFavorite(String targetUid) async {
    if (_currentUserId == null) return false;
    return _favoritesRepository.isFavorite(
      userId: _currentUserId!,
      targetUid: targetUid,
    );
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
