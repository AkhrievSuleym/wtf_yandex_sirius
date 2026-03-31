import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:wtf_yandex_sirius/domain/repository/i_auth_repository.dart';
import '../../domain/models/app_user.dart';

class AuthRepositoryImpl implements IAuthRepository {
  final firebase.FirebaseAuth _firebaseAuth;

  AuthRepositoryImpl({firebase.FirebaseAuth? firebaseAuth})
      : _firebaseAuth = firebaseAuth ?? firebase.FirebaseAuth.instance;

  // Маппер: превращаем Firebase-юзера в нашу модель AppUser
  AppUser? _mapFirebaseUser(firebase.User? user) {
    if (user == null) return null;
    return AppUser(
      id: user.uid,
      email: user.email,
    );
  }

  @override
  Stream<AppUser?> get authStateChanges {
    return _firebaseAuth.authStateChanges().map(_mapFirebaseUser);
  }

  @override
  AppUser? get currentUser => _mapFirebaseUser(_firebaseAuth.currentUser);

  @override
  Future<AppUser?> signUp({required String email, required String password}) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return _mapFirebaseUser(credential.user);
    } catch (e) {
      // Здесь можно пробросить свою ошибку или обработать исключение
      rethrow;
    }
  }

  @override
  Future<AppUser?> signIn({required String email, required String password}) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return _mapFirebaseUser(credential.user);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }
}