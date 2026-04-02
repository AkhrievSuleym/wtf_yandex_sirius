class RouteNames {
  RouteNames._();

  static const String splash = 'splash';
  static const String welcome = 'welcome';
  static const String signUp = 'sign-up';
  static const String createProfile = 'create-profile';

  // Tabs (ShellRoute)
  static const String board = 'board';
  static const String search = 'search';
  static const String favorites = 'favorites';
  static const String profile = 'profile';

  // Nested
  static const String publicProfile = 'public-profile';
  static const String sendComment = 'send-comment';
  static const String settings = 'settings';
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

  static String publicProfileFromSearch(String uid) => '/search/$uid';
  static String sendCommentFromSearch(String uid) => '/search/$uid/comment';
  static String publicProfileFromFavorites(String uid) => '/favorites/$uid';
  static String sendCommentFromFavorites(String uid) => '/favorites/$uid/comment';
}
