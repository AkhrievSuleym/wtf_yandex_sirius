import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../repositories/board_repository.dart';
import 'board_state.dart';

class BoardCubit extends Cubit<BoardState> {
  final BoardRepository _boardRepository;
  StreamSubscription? _subscription;

  BoardCubit(this._boardRepository) : super(const BoardInitial());

  void subscribeToBoard(String ownerId) {
    emit(const BoardLoading());
    _subscription?.cancel();
    _subscription = _boardRepository.watchBoardComments(ownerId).listen(
      (comments) {
        final unread = comments.where((c) => !c.isRead).length;
        emit(BoardLoaded(comments: comments, unreadCount: unread));
      },
      onError: (e) => emit(BoardError(e.toString())),
    );
  }

  Future<void> deleteComment(String commentId) async {
    try {
      await _boardRepository.deleteComment(commentId);
    } catch (e) {
      emit(BoardError(e.toString()));
    }
  }

  Future<void> markAsRead(String commentId) async {
    try {
      await _boardRepository.markAsRead(commentId);
    } catch (_) {}
  }

  Future<void> toggleReaction(
    String commentId,
    String reactionKey,
    String userId,
  ) async {
    // Оптимистичный UI: обновляем локально сразу
    final current = state;
    if (current is BoardLoaded) {
      final updatedComments = current.comments.map((c) {
        if (c.id != commentId) return c;

        final hasReacted = c.hasReacted(reactionKey, userId);
        final newReactions = Map<String, int>.from(c.reactions);
        final newReactedBy = Map<String, List<String>>.from(
          c.reactedBy.map((k, v) => MapEntry(k, List<String>.from(v))),
        );

        if (hasReacted) {
          newReactions[reactionKey] = (newReactions[reactionKey] ?? 1) - 1;
          newReactedBy[reactionKey]?.remove(userId);
        } else {
          newReactions[reactionKey] = (newReactions[reactionKey] ?? 0) + 1;
          newReactedBy[reactionKey]?.add(userId);
        }

        return c.copyWith(reactions: newReactions, reactedBy: newReactedBy);
      }).toList();

      emit(BoardLoaded(
        comments: updatedComments,
        unreadCount: current.unreadCount,
      ));
    }

    // Синхронизируем с Firestore (real-time stream обновит итоговое состояние)
    try {
      await _boardRepository.toggleReaction(
        commentId: commentId,
        reactionKey: reactionKey,
        userId: userId,
      );
    } catch (e) {
      // Откат при ошибке — stream вернёт исходное состояние
      emit(BoardError(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
