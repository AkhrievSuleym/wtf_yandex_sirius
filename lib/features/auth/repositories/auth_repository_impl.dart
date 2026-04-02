import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants/firestore_collections.dart';
import '../../../core/utils/app_logger.dart';
import '../models/user_model.dart';
import 'auth_repository.dart';

String _mapFirebaseAuthError(FirebaseAuthException e) {
  switch (e.code) {
    case 'admin-restricted-operation':
      return 'Анонимный вход отключён. Обратитесь к администратору.';
    case 'network-request-failed':
      return 'Нет подключения к интернету.';
    case 'too-many-requests':
      return 'Слишком много попыток. Попробуйте позже.';
    default:
      return 'Ошибка входа. Попробуйте ещё раз.';
  }
}

bool _isTransient(Object e) {
  if (e is FirebaseException) {
    return e.code == 'unavailable' ||
        e.code == 'deadline-exceeded' ||
        e.code == 'resource-exhausted';
  }
  return false;
}

class AuthRepositoryImpl implements AuthRepository {
  static const _tag = 'AuthRepository';

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthRepositoryImpl({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<UserModel?> authStateChanges() {
    AppLogger.d(_tag, 'Subscribing to authStateChanges');
    return _auth.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) {
        AppLogger.i(_tag, 'Auth state: unauthenticated');
        return null;
      }
      AppLogger.i(_tag, 'Auth state: authenticated uid=${firebaseUser.uid}');

      // Retry up to 3 times for transient Firestore errors
      return _fetchUserModelWithRetry(firebaseUser.uid);
    });
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) {
      AppLogger.d(_tag, 'getCurrentUser: no current user');
      return null;
    }
    AppLogger.d(_tag, 'getCurrentUser: uid=${firebaseUser.uid}');
    return _fetchUserModelWithRetry(firebaseUser.uid);
  }

  @override
  Future<UserModel> signUpAnonymous() async {
    AppLogger.i(_tag, 'signUpAnonymous: starting');
    final UserCredential credential;
    try {
      credential = await _auth.signInAnonymously();
    } on FirebaseAuthException catch (e) {
      AppLogger.e(_tag, 'signUpAnonymous failed: ${e.code}', e);
      throw Exception(_mapFirebaseAuthError(e));
    }
    final uid = credential.user!.uid;
    AppLogger.i(_tag, 'signUpAnonymous: success uid=$uid');

    final doc = await _firestore
        .collection(FirestoreCollections.users)
        .doc(uid)
        .get();

    if (doc.exists) {
      AppLogger.d(_tag, 'signUpAnonymous: existing profile found');
      return UserModel.fromFirestore(doc);
    }

    AppLogger.d(_tag, 'signUpAnonymous: new user, profile not yet created');
    final now = DateTime.now();
    return UserModel(
      uid: uid,
      username: '',
      displayName: '',
      bio: '',
      isPublic: true,
      createdAt: now,
      updatedAt: now,
      commentCount: 0,
    );
  }

  @override
  Future<void> signOut() async {
    AppLogger.i(_tag, 'signOut: uid=${_auth.currentUser?.uid}');
    await _auth.signOut();
  }

  @override
  Future<void> deleteAccount() async {
    final uid = _auth.currentUser?.uid;
    AppLogger.w(_tag, 'deleteAccount: uid=$uid');
    if (uid == null) return;

    final batch = _firestore.batch();
    batch.delete(_firestore.collection(FirestoreCollections.users).doc(uid));
    await batch.commit();
    await _auth.currentUser?.delete();
    AppLogger.i(_tag, 'deleteAccount: done');
  }

  /// Fetches user model with up to [maxAttempts] retries on transient errors.
  Future<UserModel?> _fetchUserModelWithRetry(
    String uid, {
    int maxAttempts = 3,
  }) async {
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        return await _fetchUserModel(uid);
      } catch (e) {
        if (_isTransient(e) && attempt < maxAttempts) {
          final delay = Duration(milliseconds: 500 * attempt);
          AppLogger.w(
            _tag,
            '_fetchUserModel transient error (attempt $attempt/$maxAttempts), retry in ${delay.inMilliseconds}ms',
          );
          await Future.delayed(delay);
        } else {
          AppLogger.e(_tag, '_fetchUserModel failed after $attempt attempt(s)', e);
          rethrow;
        }
      }
    }
    return null;
  }

  Future<UserModel?> _fetchUserModel(String uid) async {
    AppLogger.d(_tag, '_fetchUserModel: uid=$uid');
    final doc = await _firestore
        .collection(FirestoreCollections.users)
        .doc(uid)
        .get();
    if (!doc.exists) {
      AppLogger.w(_tag, '_fetchUserModel: document not found uid=$uid');
      return null;
    }
    return UserModel.fromFirestore(doc);
  }
}
