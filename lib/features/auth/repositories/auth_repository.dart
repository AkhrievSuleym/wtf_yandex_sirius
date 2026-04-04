import '../models/user_model.dart';

abstract class AuthRepository {
  Stream<UserModel?> authStateChanges();
  Future<UserModel?> getCurrentUser();
  Future<UserModel> signUpAnonymous();
  Future<UserModel> loginWithPassword({
    required String username,
    required String password,
  });
  Future<void> createProfile({
    required String username,
    required String displayName,
    required String bio,
  });
  Future<void> setPassword(String password);
  Future<bool> isUsernameAvailable(String username);
  Future<void> signOut();
  Future<void> deleteAccount();
}
