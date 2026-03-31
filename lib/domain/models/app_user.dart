class AppUser {
  final String id;
  final String? email;

  AppUser({
    required this.id,
    this.email,
  });

  // Вспомогательный геттер для проверки, залогинен ли кто-то вообще
  static AppUser get empty => AppUser(id: '');
  bool get isEmpty => id.isEmpty;
}