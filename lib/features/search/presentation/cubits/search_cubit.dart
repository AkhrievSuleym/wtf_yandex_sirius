import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../core/utils/error_formatter.dart';
import '../../../auth/repositories/auth_repository.dart';
import '../../../profile/models/profile_model.dart';
import '../../models/search_history_item.dart';
import '../../repositories/search_repository.dart';
import 'search_state.dart';

class SearchCubit extends Cubit<SearchState> {
  static const _tag = 'SearchCubit';

  final SearchRepository _searchRepository;
  final AuthRepository _authRepository;
  Timer? _debounce;

  SearchCubit(this._searchRepository, this._authRepository)
      : super(const SearchInitial());

  Future<String?> _accountUid() async {
    final user = await _authRepository.getCurrentUser();
    return user?.uid;
  }

  Future<void> loadHistory() async {
    AppLogger.d(_tag, 'loadHistory');
    try {
      final uid = await _accountUid();
      if (uid == null || uid.isEmpty) {
        emit(const SearchInitial());
        return;
      }
      final history = await _searchRepository.getSearchHistory(uid);
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
      emit(SearchError(formatError(e)));
    }
  }

  Future<void> addProfileToHistory(ProfileModel profile) async {
    AppLogger.d(_tag, 'addProfileToHistory: @${profile.username}');
    final uid = await _accountUid();
    if (uid == null || uid.isEmpty) return;
    final item = SearchHistoryItem(
      query: profile.username,
      viewedUid: profile.uid,
      viewedUsername: profile.username,
      viewedDisplayName: profile.displayName,
      viewedAvatarUrl: profile.avatarUrl,
      timestamp: DateTime.now(),
    );
    await _searchRepository.addToHistory(uid, item);
  }

  Future<void> clearHistory() async {
    AppLogger.i(_tag, 'clearHistory');
    final uid = await _accountUid();
    if (uid == null || uid.isEmpty) {
      emit(const SearchInitial());
      return;
    }
    await _searchRepository.clearHistory(uid);
    emit(const SearchInitial());
  }

  @override
  Future<void> close() {
    AppLogger.d(_tag, 'close');
    _debounce?.cancel();
    return super.close();
  }
}
