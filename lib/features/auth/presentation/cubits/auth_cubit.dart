import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../core/utils/error_formatter.dart';
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
        emit(AuthError(formatError(e)));
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
      emit(AuthError(formatError(e)));
    }
  }

  Future<void> createProfile({
    required String username,
    required String displayName,
    required String bio,
  }) async {
    AppLogger.i(_tag, 'createProfile: username=$username');
    emit(const AuthLoading());
    try {
      await _authRepository.createProfile(
        username: username,
        displayName: displayName,
        bio: bio,
      );
      checkAuthStatus();
    } catch (e) {
      AppLogger.e(_tag, 'createProfile failed', e);
      emit(AuthError(formatError(e)));
    }
  }

  Future<void> loginWithPassword({
    required String username,
    required String password,
  }) async {
    AppLogger.i(_tag, 'loginWithPassword: username=$username');
    emit(const AuthLoading());
    try {
      final user = await _authRepository.loginWithPassword(
        username: username,
        password: password,
      );
      AppLogger.i(_tag, 'state → Authenticated @${user.username}');
      emit(AuthAuthenticated(user));
    } catch (e) {
      AppLogger.e(_tag, 'loginWithPassword failed', e);
      emit(AuthError(formatError(e)));
    }
  }

  Future<void> setPassword(String password) async {
    AppLogger.i(_tag, 'setPassword');
    try {
      await _authRepository.setPassword(password);
    } catch (e) {
      AppLogger.e(_tag, 'setPassword failed', e);
      rethrow;
    }
  }

  Future<bool> isUsernameAvailable(String username) {
    return _authRepository.isUsernameAvailable(username);
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
      emit(AuthError(formatError(e)));
    }
  }

  @override
  Future<void> close() {
    AppLogger.d(_tag, 'close');
    _authSubscription?.cancel();
    return super.close();
  }
}
