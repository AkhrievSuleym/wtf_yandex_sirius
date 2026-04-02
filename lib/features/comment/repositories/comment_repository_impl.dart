import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants/firestore_collections.dart';
import '../../../core/utils/app_logger.dart';
import '../../../features/board/models/comment_model.dart';
import 'comment_repository.dart';

class CommentRepositoryImpl implements CommentRepository {
  static const _tag = 'CommentRepository';

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
    AppLogger.i(_tag, 'sendComment: to=$boardOwnerId from=$authorId len=${text.length}');

    await _firestore.collection(FirestoreCollections.comments).add({
      'boardOwnerId': boardOwnerId,
      'authorId': authorId,
      'text': text.trim(),
      'createdAt': Timestamp.now(),
      'reactions': CommentModel.emptyReactions,
      'reactedBy': CommentModel.emptyReactedBy,
      'isRead': false,
    });

    await _firestore
        .collection(FirestoreCollections.users)
        .doc(boardOwnerId)
        .update({'commentCount': FieldValue.increment(1)});

    AppLogger.i(_tag, 'sendComment: done');
  }
}
