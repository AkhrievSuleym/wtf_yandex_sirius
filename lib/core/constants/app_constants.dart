class AppConstants {
  AppConstants._();

  // Username
  static const int usernameMinLength = 3;
  static const int usernameMaxLength = 20;
  static const String usernamePattern = r'^[a-z0-9_]+$';

  // Display name
  static const int displayNameMinLength = 1;
  static const int displayNameMaxLength = 40;

  // Bio
  static const int bioMaxLength = 200;

  // Comment
  static const int commentMaxLength = 500;

  // Search
  static const int searchHistoryMaxItems = 20;
  static const int searchResultsLimit = 20;
  static const int searchDebounceMs = 300;

  // Hive boxes
  static const String searchHistoryBox = 'search_history';

  // Rate limiting (per Cloud Functions)
  static const int maxCommentsPerMinute = 10;
  static const int maxReactionsPerMinute = 50;
}
