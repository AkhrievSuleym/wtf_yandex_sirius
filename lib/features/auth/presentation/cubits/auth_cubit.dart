import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../repositories/auth_repository.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _authRepository;
  StreamSubscription? _authSubscription;

  AuthCubit(this._authRepository) : super(const AuthInitial());

  void checkAuthStatus() {
    emit(const AuthLoading());
    _authSubscription?.cancel();
    _authSubscription = _authRepository.authStateChanges().listen(
      (user) {
        if (user == null) {
          emit(const AuthUnauthenticated());
        } else if (user.username.isEmpty) {
          emit(AuthNeedsProfile(user.uid));
        } else {
          emit(AuthAuthenticated(user));
        }
      },
      onError: (e) => emit(AuthError(e.toString())),
    );
  }

  Future<void> signUpAnonymous() async {
    emit(const AuthLoading());
    try {
      final user = await _authRepository.signUpAnonymous();
      if (user.username.isEmpty) {
        emit(AuthNeedsProfile(user.uid));
      } else {
        emit(AuthAuthenticated(user));
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> signOut() async {
    await _authRepository.signOut();
    emit(const AuthUnauthenticated());
  }

  Future<void> deleteAccount() async {
    emit(const AuthLoading());
    try {
      await _authRepository.deleteAccount();
      emit(const AuthUnauthenticated());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}
