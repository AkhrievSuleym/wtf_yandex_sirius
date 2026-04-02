import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../profile/models/profile_model.dart';
import '../../models/search_history_item.dart';
import '../../repositories/search_repository.dart';
import 'search_state.dart';

class SearchCubit extends Cubit<SearchState> {
  static const _tag = 'SearchCubit';

  final SearchRepository _searchRepository;
  Timer? _debounce;

  SearchCubit(this._searchRepository) : super(const SearchInitial());

  Future<void> loadHistory() async {
    AppLogger.d(_tag, 'loadHistory');
    try {
      final history = await _searchRepository.getSearchHistory();
      AppLogger.d(_tag, 'loadHistory: ${history.length} items');
      emit(SearchInitial(history: history));
    } catch (e) {
      AppLogger.e(_tag, 'loadHistory failed', e);
      emit(const SearchInitial());
    }
  }

  void onQueryChanged(String query) {
    _debounce?.cancel();

    if (query.trim().isEmpty) {
      AppLogger.d(_tag, 'query cleared → loadHistory');
      loadHistory();
      return;
    }

    AppLogger.d(_tag, 'query changed: "$query" — debouncing');
    emit(const SearchLoading());
    _debounce = Timer(
      const Duration(milliseconds: 300),
      () => _performSearch(query.trim()),
    );
  }

  Future<void> _performSearch(String query) async {
    AppLogger.i(_tag, 'search: "$query"');
    try {
      final results = await _searchRepository.searchByUsername(query);
      AppLogger.i(_tag, 'search: ${results.length} results for "$query"');
      if (results.isEmpty) {
        emit(SearchEmpty(query: query));
      } else {
        emit(SearchResults(results: results, query: query));
      }
    } catch (e) {
      AppLogger.e(_tag, 'search failed', e);
      emit(SearchError(e.toString()));
    }
  }

  Future<void> addProfileToHistory(ProfileModel profile) async {
    AppLogger.d(_tag, 'addProfileToHistory: @${profile.username}');
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
    AppLogger.i(_tag, 'clearHistory');
    await _searchRepository.clearHistory();
    emit(const SearchInitial());
  }

  @override
  Future<void> close() {
    AppLogger.d(_tag, 'close');
    _debounce?.cancel();
    return super.close();
  }
}
