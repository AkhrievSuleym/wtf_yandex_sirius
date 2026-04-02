import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants/firestore_collections.dart';
import '../models/user_model.dart';
import 'auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthRepositoryImpl({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<UserModel?> authStateChanges() {
    return _auth.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) return null;
      return _fetchUserModel(firebaseUser.uid);
    });
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return null;
    return _fetchUserModel(firebaseUser.uid);
  }

  @override
  Future<UserModel> signUpAnonymous() async {
    final credential = await _auth.signInAnonymously();
    final uid = credential.user!.uid;

    final doc = await _firestore
        .collection(FirestoreCollections.users)
        .doc(uid)
        .get();

    if (doc.exists) {
      return UserModel.fromFirestore(doc);
    }

    // Новый анонимный пользователь — профиль ещё не создан, вернём минимальную модель
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
    await _auth.signOut();
  }

  @override
  Future<void> deleteAccount() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final batch = _firestore.batch();
    batch.delete(_firestore.collection(FirestoreCollections.users).doc(uid));

    await batch.commit();
    await _auth.currentUser?.delete();
  }

  Future<UserModel?> _fetchUserModel(String uid) async {
    final doc = await _firestore
        .collection(FirestoreCollections.users)
        .doc(uid)
        .get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }
}
