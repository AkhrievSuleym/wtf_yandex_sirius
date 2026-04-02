import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../../core/constants/firestore_collections.dart';
import '../models/profile_model.dart';
import 'profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final FirebaseStorage _storage;

  ProfileRepositoryImpl({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _storage = storage ?? FirebaseStorage.instance;

  @override
  Future<ProfileModel> getProfile(String uid) async {
    final doc = await _firestore
        .collection(FirestoreCollections.users)
        .doc(uid)
        .get();
    if (!doc.exists) throw Exception('Профиль не найден');
    return ProfileModel.fromFirestore(doc);
  }

  @override
  Future<void> updateProfile({
    String? displayName,
    String? bio,
    bool? isPublic,
    String? avatarPath,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('Пользователь не авторизован');

    final updates = <String, dynamic>{
      'updatedAt': Timestamp.now(),
    };

    if (displayName != null) updates['displayName'] = displayName.trim();
    if (bio != null) updates['bio'] = bio.trim();
    if (isPublic != null) updates['isPublic'] = isPublic;

    if (avatarPath != null) {
      final url = await _uploadAvatar(uid, avatarPath);
      updates['avatarUrl'] = url;
    }

    await _firestore
        .collection(FirestoreCollections.users)
        .doc(uid)
        .update(updates);
  }

  @override
  Future<bool> isUsernameAvailable(String username) async {
    final doc = await _firestore
        .collection(FirestoreCollections.usernames)
        .doc(username.toLowerCase())
        .get();
    return !doc.exists;
  }

  Future<String> _uploadAvatar(String uid, String localPath) async {
    final file = File(localPath);
    final ext = localPath.split('.').last;
    final ref = _storage.ref('avatars/$uid/avatar.$ext');
    final task = await ref.putFile(
      file,
      SettableMetadata(contentType: 'image/$ext'),
    );
    return task.ref.getDownloadURL();
  }
}
