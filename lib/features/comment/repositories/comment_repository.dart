abstract class CommentRepository {
  Future<void> sendComment({
    required String boardOwnerId,
    required String text,
  });
}
