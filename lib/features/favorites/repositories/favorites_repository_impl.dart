import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/firestore_collections.dart';
import '../../profile/models/profile_model.dart';
import 'favorites_repository.dart';

class FavoritesRepositoryImpl implements FavoritesRepository {
  final FirebaseFirestore _firestore;

  FavoritesRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference _favRef(String userId) => _firestore
      .collection(FirestoreCollections.users)
      .doc(userId)
      .collection(FirestoreCollections.favorites);

  @override
  Stream<List<ProfileModel>> watchFavorites(String userId) {
    return _favRef(userId)
        .orderBy('addedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return ProfileModel(
                uid: data['favoriteUid'] as String,
                username: data['username'] as String,
                displayName: data['displayName'] as String,
                bio: '',
                avatarUrl: data['avatarUrl'] as String?,
                commentCount: 0,
                isPublic: true,
              );
            }).toList());
  }

  @override
  Future<void> addToFavorites({
    required String userId,
    required ProfileModel profile,
  }) async {
    await _favRef(userId).doc(profile.uid).set({
      'favoriteUid': profile.uid,
      'username': profile.username,
      'displayName': profile.displayName,
      'avatarUrl': profile.avatarUrl,
      'addedAt': Timestamp.now(),
    });
  }

  @override
  Future<void> removeFromFavorites({
    required String userId,
    required String favoriteUid,
  }) async {
    await _favRef(userId).doc(favoriteUid).delete();
  }

  @override
  Future<bool> isFavorite({
    required String userId,
    required String targetUid,
  }) async {
    final doc = await _favRef(userId).doc(targetUid).get();
    return doc.exists;
  }
}
