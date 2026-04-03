class RouteNames {
  RouteNames._();

  static const String splash = 'splash';
  static const String welcome = 'welcome';
  static const String signUp = 'sign-up';
  static const String createProfile = 'create-profile';
  static const String login = 'login';

  // Tabs (ShellRoute)
  static const String board = 'board';
  static const String search = 'search';
  static const String favorites = 'favorites';
  static const String profile = 'profile';

  // Deep link
  static const String deepLink = 'deep-link';

  // Nested
  static const String publicProfile = 'public-profile';
  static const String sendComment = 'send-comment';
  static const String settings = 'settings';
  static const String changePassword = 'change-password';
  static const String commentDetail = 'comment-detail';
}

class RoutePaths {
  RoutePaths._();

  static const String welcome = '/welcome';
  static const String signUp = '/sign-up';
  static const String createProfile = '/create-profile';
  static const String board = '/board';
  static const String search = '/search';
  static const String favorites = '/favorites';
  static const String profile = '/profile';
  static const String settings = '/profile/settings';
  static const String changePassword = '/profile/settings/change-password';
  static String commentDetail(String id) => '/comments/$id';

  static String publicProfileFromSearch(String uid) => '/search/$uid';
  static String sendCommentFromSearch(String uid) => '/search/$uid/comment';
  static String publicProfileFromFavorites(String uid) => '/favorites/$uid';
  static String sendCommentFromFavorites(String uid) => '/favorites/$uid/comment';
}
