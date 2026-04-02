import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../profile/models/profile_model.dart';
import '../../models/search_history_item.dart';
import '../../repositories/search_repository.dart';
import 'search_state.dart';

class SearchCubit extends Cubit<SearchState> {
  final SearchRepository _searchRepository;
  Timer? _debounce;

  SearchCubit(this._searchRepository) : super(const SearchInitial());

  Future<void> loadHistory() async {
    try {
      final history = await _searchRepository.getSearchHistory();
      emit(SearchInitial(history: history));
    } catch (_) {
      emit(const SearchInitial());
    }
  }

  void onQueryChanged(String query) {
    _debounce?.cancel();

    if (query.trim().isEmpty) {
      loadHistory();
      return;
    }

    emit(const SearchLoading());
    _debounce = Timer(
      const Duration(milliseconds: 300),
      () => _performSearch(query.trim()),
    );
  }

  Future<void> _performSearch(String query) async {
    try {
      final results = await _searchRepository.searchByUsername(query);
      if (results.isEmpty) {
        emit(SearchEmpty(query: query));
      } else {
        emit(SearchResults(results: results, query: query));
      }
    } catch (e) {
      emit(SearchError(e.toString()));
    }
  }

  Future<void> addProfileToHistory(ProfileModel profile) async {
    final item = SearchHistoryItem(
      query: profile.username,
      viewedUid: profile.uid,
      viewedUsername: profile.username,
      viewedDisplayName: profile.displayName,
      viewedAvatarUrl: profile.avatarUrl,
      timestamp: DateTime.now(),
    );
    await _searchRepository.addToHistory(item);
  }

  Future<void> clearHistory() async {
    await _searchRepository.clearHistory();
    emit(const SearchInitial());
  }

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }
}
