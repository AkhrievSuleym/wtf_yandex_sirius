import '../models/user_model.dart';

abstract class AuthRepository {
  Stream<UserModel?> authStateChanges();
  Future<UserModel?> getCurrentUser();
  Future<UserModel> signUpAnonymous();
  Future<void> signOut();
  Future<void> deleteAccount();
}
