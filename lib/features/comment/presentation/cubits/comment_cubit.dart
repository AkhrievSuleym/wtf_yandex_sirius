import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/app_logger.dart';
import '../../repositories/comment_repository.dart';
import 'comment_state.dart';

class CommentCubit extends Cubit<CommentState> {
  static const _tag = 'CommentCubit';

  final CommentRepository _commentRepository;

  CommentCubit(this._commentRepository) : super(const CommentInitial());

  Future<void> sendComment({
    required String boardOwnerId,
    required String text,
  }) async {
    AppLogger.i(_tag, 'sendComment: to=$boardOwnerId');
    emit(const CommentSending());
    try {
      await _commentRepository.sendComment(
        boardOwnerId: boardOwnerId,
        text: text,
      );
      AppLogger.i(_tag, 'sendComment: success');
      emit(const CommentSuccess());
    } catch (e) {
      AppLogger.e(_tag, 'sendComment failed', e);
      emit(CommentError(e.toString()));
    }
  }

  void reset() {
    AppLogger.d(_tag, 'reset');
    emit(const CommentInitial());
  }
}
