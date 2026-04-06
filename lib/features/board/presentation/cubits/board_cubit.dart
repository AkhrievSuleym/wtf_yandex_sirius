import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../core/utils/error_formatter.dart';
import '../../repositories/board_repository.dart';
import 'board_state.dart';

class BoardCubit extends Cubit<BoardState> {
  static const _tag = 'BoardCubit';

  final BoardRepository _boardRepository;
  StreamSubscription? _subscription;

  final StreamController<String> _toastController =
      StreamController<String>.broadcast();
  Stream<String> get toastStream => _toastController.stream;

  BoardCubit(this._boardRepository) : super(const BoardInitial());

  void subscribeToBoard(String ownerId) {
    AppLogger.i(_tag, 'subscribeToBoard: ownerId=$ownerId');
    if (state is! BoardLoaded) {
      emit(const BoardLoading());
    }
    _subscription?.cancel();
    _subscription = _boardRepository.watchBoardComments(ownerId).listen(
      (comments) {
        final unread = comments.where((c) => !c.isRead).length;
        AppLogger.d(
            _tag, 'board updated: ${comments.length} comments, $unread unread');
        emit(BoardLoaded(comments: comments, unreadCount: unread));
      },
      onError: (e) {
        AppLogger.e(_tag, 'board stream error', e);
        if (state is! BoardLoaded) {
          emit(BoardError(formatError(e)));
        }
      },
    );
  }

  Future<void> deleteComment(String commentId) async {
    AppLogger.i(_tag, 'deleteComment: id=$commentId');
    try {
      await _boardRepository.deleteComment(commentId);
    } catch (e) {
      AppLogger.e(_tag, 'deleteComment failed', e);
      _toastController.add(formatError(e));
    }
  }

  Future<void> markAsRead(String commentId) async {
    AppLogger.d(_tag, 'markAsRead: id=$commentId');
    try {
      await _boardRepository.markAsRead(commentId);
    } catch (e) {
      AppLogger.e(_tag, 'markAsRead failed', e);
    }
  }

  Future<void> toggleReaction(
    String commentId,
    String reactionKey,
    String userId,
  ) async {
    AppLogger.d(_tag, 'toggleReaction: commentId=$commentId key=$reactionKey');
    final current = state;
    if (current is BoardLoaded) {
      // Optimistic update
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

    try {
      await _boardRepository.toggleReaction(
        commentId: commentId,
        reactionKey: reactionKey,
        userId: userId,
      );
    } catch (e) {
      AppLogger.e(_tag, 'toggleReaction failed, rolling back', e);
      _toastController.add(formatError(e));
      if (state is BoardLoaded) {
        subscribeToBoard((state as BoardLoaded).comments.first.boardOwnerId);
      }
    }
  }

  @override
  Future<void> close() {
    AppLogger.d(_tag, 'close');
    _subscription?.cancel();
    _toastController.close();
    return super.close();
  }
}
