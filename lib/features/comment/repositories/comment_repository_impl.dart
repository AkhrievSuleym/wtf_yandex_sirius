import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants/firestore_collections.dart';
import '../../../features/board/models/comment_model.dart';
import 'comment_repository.dart';

class CommentRepositoryImpl implements CommentRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CommentRepositoryImpl({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  @override
  Future<void> sendComment({
    required String boardOwnerId,
    required String text,
  }) async {
    final authorId = _auth.currentUser?.uid;

    await _firestore.collection(FirestoreCollections.comments).add({
      'boardOwnerId': boardOwnerId,
      'authorId': authorId,
      'text': text.trim(),
      'createdAt': Timestamp.now(),
      'reactions': CommentModel.emptyReactions,
      'reactedBy': CommentModel.emptyReactedBy,
      'isRead': false,
    });

    // Increment commentCount on the board owner's user document
    await _firestore
        .collection(FirestoreCollections.users)
        .doc(boardOwnerId)
        .update({'commentCount': FieldValue.increment(1)});
  }
}
