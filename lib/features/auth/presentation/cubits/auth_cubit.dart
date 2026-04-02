import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/app_logger.dart';
import '../../repositories/auth_repository.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  static const _tag = 'AuthCubit';

  final AuthRepository _authRepository;
  StreamSubscription? _authSubscription;

  AuthCubit(this._authRepository) : super(const AuthInitial());

  void checkAuthStatus() {
    AppLogger.d(_tag, 'checkAuthStatus');
    emit(const AuthLoading());
    _authSubscription?.cancel();
    _authSubscription = _authRepository.authStateChanges().listen(
      (user) {
        if (user == null) {
          AppLogger.i(_tag, 'state → Unauthenticated');
          emit(const AuthUnauthenticated());
        } else if (user.username.isEmpty) {
          AppLogger.i(_tag, 'state → NeedsProfile uid=${user.uid}');
          emit(AuthNeedsProfile(user.uid));
        } else {
          AppLogger.i(_tag, 'state → Authenticated @${user.username}');
          emit(AuthAuthenticated(user));
        }
      },
      onError: (e) {
        AppLogger.e(_tag, 'authStateChanges error', e);
        emit(AuthError(e.toString()));
      },
    );
  }

  Future<void> signUpAnonymous() async {
    AppLogger.i(_tag, 'signUpAnonymous');
    emit(const AuthLoading());
    try {
      final user = await _authRepository.signUpAnonymous();
      if (user.username.isEmpty) {
        AppLogger.i(_tag, 'state → NeedsProfile');
        emit(AuthNeedsProfile(user.uid));
      } else {
        AppLogger.i(_tag, 'state → Authenticated');
        emit(AuthAuthenticated(user));
      }
    } catch (e) {
      AppLogger.e(_tag, 'signUpAnonymous failed', e);
      final message = e is Exception
          ? e.toString().replaceFirst('Exception: ', '')
          : e.toString();
      emit(AuthError(message));
    }
  }

  Future<void> signOut() async {
    AppLogger.i(_tag, 'signOut');
    await _authRepository.signOut();
    emit(const AuthUnauthenticated());
  }

  Future<void> deleteAccount() async {
    AppLogger.w(_tag, 'deleteAccount');
    emit(const AuthLoading());
    try {
      await _authRepository.deleteAccount();
      emit(const AuthUnauthenticated());
    } catch (e) {
      AppLogger.e(_tag, 'deleteAccount failed', e);
      emit(AuthError(e.toString()));
    }
  }

  @override
  Future<void> close() {
    AppLogger.d(_tag, 'close');
    _authSubscription?.cancel();
    return super.close();
  }
}
