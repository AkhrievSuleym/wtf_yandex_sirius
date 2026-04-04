import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/services/api_client.dart';
import '../../../core/utils/app_logger.dart';
import '../../profile/models/profile_model.dart';
import '../models/search_history_item.dart';
import 'search_repository.dart';

class SearchRepositoryImpl implements SearchRepository {
  static const _tag = 'SearchRepository';
  static const _historyKeyLegacy = 'search_history';

  final ApiClient _api;
  final SharedPreferences _prefs;

  SearchRepositoryImpl(
      {required ApiClient api, required SharedPreferences prefs})
      : _api = api,
        _prefs = prefs;

  String _historyKeyFor(String accountUid) => 'search_history_$accountUid';

  Future<List<String>> _readHistoryRaw(String accountUid) async {
    final key = _historyKeyFor(accountUid);
    var raw = _prefs.getStringList(key);
    if (raw == null || raw.isEmpty) {
      final legacy = _prefs.getStringList(_historyKeyLegacy);
      if (legacy != null && legacy.isNotEmpty) {
        await _prefs.setStringList(key, legacy);
        await _prefs.remove(_historyKeyLegacy);
        raw = legacy;
      }
    }
    return raw ?? [];
  }

  @override
  Future<List<ProfileModel>> searchByUsername(String query) async {
    if (query.isEmpty) return [];
    AppLogger.d(_tag, 'searchByUsername: "$query"');
    final response =
        await _api.dio.get('/search', queryParameters: {'q': query});
    return (response.data as List)
        .map((e) => ProfileModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<String?> resolveUsername(String username) async {
    if (username.isEmpty) return null;
    AppLogger.d(_tag, 'resolveUsername: $username');
    try {
      final response = await _api.dio.get('/users/resolve/$username');
      return response.data['uid'] as String?;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<SearchHistoryItem>> getSearchHistory(String accountUid) async {
    final raw = await _readHistoryRaw(accountUid);
    return raw
        .map((e) =>
            SearchHistoryItem.fromJson(jsonDecode(e) as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> addToHistory(String accountUid, SearchHistoryItem item) async {
    final history = await getSearchHistory(accountUid);
    history.removeWhere(
        (h) => item.viewedUid != null && h.viewedUid == item.viewedUid);
    history.insert(0, item);
    final trimmed = history.take(AppConstants.searchHistoryMaxItems).toList();
    await _prefs.setStringList(
      _historyKeyFor(accountUid),
      trimmed.map((e) => jsonEncode(e.toJson())).toList(),
    );
  }

  @override
  Future<void> clearHistory(String accountUid) async {
    await _prefs.remove(_historyKeyFor(accountUid));
  }
}
