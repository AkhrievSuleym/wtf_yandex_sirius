import '../models/app_user.dart';

abstract class IAuthRepository {
  // Стрим, который будет "кричать" каждый раз, когда статус входа меняется
  Stream<AppUser?> get authStateChanges;

  // Регистрация
  Future<AppUser?> signUp({
    required String email,
    required String password,
  });

  // Вход
  Future<AppUser?> signIn({
    required String email,
    required String password,
  });

  // Выход
  Future<void> signOut();

  // Получить текущего пользователя (синхронно)
  AppUser? get currentUser;
}