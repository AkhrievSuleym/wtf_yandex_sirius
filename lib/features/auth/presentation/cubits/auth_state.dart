import 'package:equatable/equatable.dart';
import '../../models/user_model.dart';

sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

/// Пользователь вошёл И профиль создан (username не пустой)
class AuthAuthenticated extends AuthState {
  final UserModel user;
  const AuthAuthenticated(this.user);

  @override
  List<Object?> get props => [user.uid];
}

/// Вошёл анонимно, но профиль ещё не настроен
class AuthNeedsProfile extends AuthState {
  final String uid;
  const AuthNeedsProfile(this.uid);

  @override
  List<Object?> get props => [uid];
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}
