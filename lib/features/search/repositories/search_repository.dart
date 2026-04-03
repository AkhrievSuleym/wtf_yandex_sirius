import '../../profile/models/profile_model.dart';
import '../models/search_history_item.dart';

abstract class SearchRepository {
  Future<List<ProfileModel>> searchByUsername(String query);
  Future<String?> resolveUsername(String username);
  Future<List<SearchHistoryItem>> getSearchHistory(String accountUid);
  Future<void> addToHistory(String accountUid, SearchHistoryItem item);
  Future<void> clearHistory(String accountUid);
}
