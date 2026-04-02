import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../../core/constants/firestore_collections.dart';
import '../../../core/utils/app_logger.dart';
import '../models/profile_model.dart';
import 'profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  static const _tag = 'ProfileRepository';

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
    AppLogger.d(_tag, 'getProfile: uid=$uid');
    final doc = await _firestore
        .collection(FirestoreCollections.users)
        .doc(uid)
        .get();
    if (!doc.exists) {
      AppLogger.w(_tag, 'getProfile: not found uid=$uid');
      throw Exception('Профиль не найден');
    }
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
    AppLogger.i(_tag, 'updateProfile: uid=$uid');

    final updates = <String, dynamic>{'updatedAt': Timestamp.now()};
    if (displayName != null) updates['displayName'] = displayName.trim();
    if (bio != null) updates['bio'] = bio.trim();
    if (isPublic != null) updates['isPublic'] = isPublic;

    if (avatarPath != null) {
      AppLogger.d(_tag, 'updateProfile: uploading avatar');
      final url = await _uploadAvatar(uid, avatarPath);
      updates['avatarUrl'] = url;
      AppLogger.d(_tag, 'updateProfile: avatar uploaded url=$url');
    }

    await _firestore
        .collection(FirestoreCollections.users)
        .doc(uid)
        .update(updates);
    AppLogger.i(_tag, 'updateProfile: done');
  }

  @override
  Future<bool> isUsernameAvailable(String username) async {
    AppLogger.d(_tag, 'isUsernameAvailable: $username');
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
