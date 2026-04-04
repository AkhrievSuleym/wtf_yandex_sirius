import '../../../core/services/api_client.dart';
import '../../../core/utils/app_logger.dart';
import 'comment_repository.dart';

class CommentRepositoryImpl implements CommentRepository {
  static const _tag = 'CommentRepository';

  final ApiClient _api;

  CommentRepositoryImpl(this._api);

  @override
  Future<void> sendComment({
    required String boardOwnerId,
    required String text,
  }) async {
    AppLogger.i(_tag, 'sendComment: to=$boardOwnerId len=${text.length}');
    await _api.dio.post('/comments', data: {
      'boardOwnerId': boardOwnerId,
      'text': text.trim(),
    });
    AppLogger.i(_tag, 'sendComment: done');
  }
}
