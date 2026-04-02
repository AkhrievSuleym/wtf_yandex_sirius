import 'package:equatable/equatable.dart';
import '../../models/comment_model.dart';

sealed class BoardState extends Equatable {
  const BoardState();

  @override
  List<Object?> get props => [];
}

class BoardInitial extends BoardState {
  const BoardInitial();
}

class BoardLoading extends BoardState {
  const BoardLoading();
}

class BoardLoaded extends BoardState {
  final List<CommentModel> comments;
  final int unreadCount;

  const BoardLoaded({required this.comments, required this.unreadCount});

  @override
  List<Object?> get props => [comments, unreadCount];
}

class BoardError extends BoardState {
  final String message;
  const BoardError(this.message);

  @override
  List<Object?> get props => [message];
}
