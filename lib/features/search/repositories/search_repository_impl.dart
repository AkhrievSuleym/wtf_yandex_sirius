import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/firestore_collections.dart';
import '../../profile/models/profile_model.dart';
import '../models/search_history_item.dart';
import 'search_repository.dart';

class SearchRepositoryImpl implements SearchRepository {
  final FirebaseFirestore _firestore;
  final SharedPreferences _prefs;

  static const _historyKey = 'search_history';

  SearchRepositoryImpl({
    required FirebaseFirestore firestore,
    required SharedPreferences prefs,
  })  : _firestore = firestore,
        _prefs = prefs;

  @override
  Future<List<ProfileModel>> searchByUsername(String query) async {
    if (query.isEmpty) return [];

    final normalized = query.toLowerCase().trim();
    final snap = await _firestore
        .collection(FirestoreCollections.users)
        .where('username', isGreaterThanOrEqualTo: normalized)
        .where('username', isLessThan: '$normalized\uf8ff')
        .limit(AppConstants.searchResultsLimit)
        .get();

    return snap.docs.map(ProfileModel.fromFirestore).toList();
  }

  @override
  Future<List<SearchHistoryItem>> getSearchHistory() async {
    final raw = _prefs.getStringList(_historyKey) ?? [];
    return raw
        .map((e) => SearchHistoryItem.fromJson(
            jsonDecode(e) as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> addToHistory(SearchHistoryItem item) async {
    final history = await getSearchHistory();

    // Удаляем дубликат по uid, если есть
    history.removeWhere((h) =>
        item.viewedUid != null && h.viewedUid == item.viewedUid);

    // Новый элемент — в начало
    history.insert(0, item);

    // Ограничиваем размер
    final trimmed = history.take(AppConstants.searchHistoryMaxItems).toList();

    await _prefs.setStringList(
      _historyKey,
      trimmed.map((e) => jsonEncode(e.toJson())).toList(),
    );
  }

  @override
  Future<void> clearHistory() async {
    await _prefs.remove(_historyKey);
  }
}
