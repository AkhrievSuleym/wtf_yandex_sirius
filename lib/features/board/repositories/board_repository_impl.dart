import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/firestore_collections.dart';
import '../models/comment_model.dart';
import 'board_repository.dart';

class BoardRepositoryImpl implements BoardRepository {
  final FirebaseFirestore _firestore;

  BoardRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<List<CommentModel>> watchBoardComments(String ownerId) {
    return _firestore
        .collection(FirestoreCollections.comments)
        .where('boardOwnerId', isEqualTo: ownerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(CommentModel.fromFirestore).toList());
  }

  @override
  Future<void> deleteComment(String commentId) async {
    await _firestore
        .collection(FirestoreCollections.comments)
        .doc(commentId)
        .delete();
  }

  @override
  Future<void> markAsRead(String commentId) async {
    await _firestore
        .collection(FirestoreCollections.comments)
        .doc(commentId)
        .update({'isRead': true});
  }

  @override
  Future<void> toggleReaction({
    required String commentId,
    required String reactionKey,
    required String userId,
  }) async {
    final ref = _firestore
        .collection(FirestoreCollections.comments)
        .doc(commentId);

    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;

      final data = snap.data()!;
      final reactedBy = Map<String, dynamic>.from(data['reactedBy'] as Map? ?? {});
      final reactions = Map<String, dynamic>.from(data['reactions'] as Map? ?? {});

      final userList = List<String>.from(reactedBy[reactionKey] as List? ?? []);
      final hasReacted = userList.contains(userId);

      if (hasReacted) {
        userList.remove(userId);
        reactions[reactionKey] = ((reactions[reactionKey] as int?) ?? 1) - 1;
      } else {
        userList.add(userId);
        reactions[reactionKey] = ((reactions[reactionKey] as int?) ?? 0) + 1;
      }

      reactedBy[reactionKey] = userList;

      tx.update(ref, {
        'reactions': reactions,
        'reactedBy': reactedBy,
      });
    });
  }
}
