import '../models/comment_model.dart';

abstract class BoardRepository {
  Stream<List<CommentModel>> watchBoardComments(String ownerId);
  Future<void> deleteComment(String commentId);
  Future<void> markAsRead(String commentId);
  Future<void> toggleReaction({
    required String commentId,
    required String reactionKey,
    required String userId,
  });
}
