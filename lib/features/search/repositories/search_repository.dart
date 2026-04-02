import '../../profile/models/profile_model.dart';
import '../models/search_history_item.dart';

abstract class SearchRepository {
  Future<List<ProfileModel>> searchByUsername(String query);
  Future<List<SearchHistoryItem>> getSearchHistory();
  Future<void> addToHistory(SearchHistoryItem item);
  Future<void> clearHistory();
}
