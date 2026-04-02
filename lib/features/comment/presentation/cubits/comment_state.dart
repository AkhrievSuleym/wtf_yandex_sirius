import 'package:equatable/equatable.dart';

sealed class CommentState extends Equatable {
  const CommentState();

  @override
  List<Object?> get props => [];
}

class CommentInitial extends CommentState {
  const CommentInitial();
}

class CommentSending extends CommentState {
  const CommentSending();
}

class CommentSuccess extends CommentState {
  const CommentSuccess();
}

class CommentError extends CommentState {
  final String message;
  const CommentError(this.message);

  @override
  List<Object?> get props => [message];
}
