import 'package:flutter_bloc/flutter_bloc.dart';
import '../../repositories/comment_repository.dart';
import 'comment_state.dart';

class CommentCubit extends Cubit<CommentState> {
  final CommentRepository _commentRepository;

  CommentCubit(this._commentRepository) : super(const CommentInitial());

  Future<void> sendComment({
    required String boardOwnerId,
    required String text,
  }) async {
    emit(const CommentSending());
    try {
      await _commentRepository.sendComment(
        boardOwnerId: boardOwnerId,
        text: text,
      );
      emit(const CommentSuccess());
    } catch (e) {
      emit(CommentError(e.toString()));
    }
  }

  void reset() => emit(const CommentInitial());
}
