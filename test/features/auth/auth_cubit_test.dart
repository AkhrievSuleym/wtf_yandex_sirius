import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:wtf_yandex_sirius/features/auth/models/user_model.dart';
import 'package:wtf_yandex_sirius/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:wtf_yandex_sirius/features/auth/presentation/cubits/auth_state.dart';
import 'package:wtf_yandex_sirius/features/auth/repositories/auth_repository.dart';

import 'auth_cubit_test.mocks.dart';

@GenerateMocks([AuthRepository])
void main() {
  late MockAuthRepository mockRepo;

  final now = DateTime(2025, 1, 1);
  final userWithProfile = UserModel(
    uid: 'uid1',
    username: 'testuser',
    displayName: 'Test User',
    bio: '',
    isPublic: true,
    createdAt: now,
    updatedAt: now,
    commentCount: 0,
  );
  final userNoProfile = UserModel(
    uid: 'uid2',
    username: '',
    displayName: '',
    bio: '',
    isPublic: true,
    createdAt: now,
    updatedAt: now,
    commentCount: 0,
  );

  setUp(() {
    mockRepo = MockAuthRepository();
  });

  group('AuthCubit.checkAuthStatus', () {
    blocTest<AuthCubit, AuthState>(
      'emits [Loading, Authenticated] when user has profile',
      build: () {
        when(mockRepo.authStateChanges())
            .thenAnswer((_) => Stream.value(userWithProfile));
        return AuthCubit(mockRepo);
      },
      act: (cubit) => cubit.checkAuthStatus(),
      expect: () => [
        const AuthLoading(),
        AuthAuthenticated(userWithProfile),
      ],
    );

    blocTest<AuthCubit, AuthState>(
      'emits [Loading, NeedsProfile] when username is empty',
      build: () {
        when(mockRepo.authStateChanges())
            .thenAnswer((_) => Stream.value(userNoProfile));
        return AuthCubit(mockRepo);
      },
      act: (cubit) => cubit.checkAuthStatus(),
      expect: () => [
        const AuthLoading(),
        const AuthNeedsProfile('uid2'),
      ],
    );

    blocTest<AuthCubit, AuthState>(
      'emits [Loading, Unauthenticated] when stream emits null',
      build: () {
        when(mockRepo.authStateChanges())
            .thenAnswer((_) => Stream.value(null));
        return AuthCubit(mockRepo);
      },
      act: (cubit) => cubit.checkAuthStatus(),
      expect: () => [
        const AuthLoading(),
        const AuthUnauthenticated(),
      ],
    );

    blocTest<AuthCubit, AuthState>(
      'emits [Loading, Error] on stream error',
      build: () {
        when(mockRepo.authStateChanges())
            .thenAnswer((_) => Stream.error(Exception('network')));
        return AuthCubit(mockRepo);
      },
      act: (cubit) => cubit.checkAuthStatus(),
      expect: () => [
        const AuthLoading(),
        isA<AuthError>(),
      ],
    );
  });

  group('AuthCubit.signUpAnonymous', () {
    blocTest<AuthCubit, AuthState>(
      'emits [Loading, NeedsProfile] for new anonymous user',
      build: () {
        when(mockRepo.signUpAnonymous())
            .thenAnswer((_) async => userNoProfile);
        return AuthCubit(mockRepo);
      },
      act: (cubit) => cubit.signUpAnonymous(),
      expect: () => [
        const AuthLoading(),
        const AuthNeedsProfile('uid2'),
      ],
    );

    blocTest<AuthCubit, AuthState>(
      'emits [Loading, Authenticated] for returning user',
      build: () {
        when(mockRepo.signUpAnonymous())
            .thenAnswer((_) async => userWithProfile);
        return AuthCubit(mockRepo);
      },
      act: (cubit) => cubit.signUpAnonymous(),
      expect: () => [
        const AuthLoading(),
        AuthAuthenticated(userWithProfile),
      ],
    );

    blocTest<AuthCubit, AuthState>(
      'emits [Loading, Error] on failure',
      build: () {
        when(mockRepo.signUpAnonymous())
            .thenThrow(Exception('sign-in failed'));
        return AuthCubit(mockRepo);
      },
      act: (cubit) => cubit.signUpAnonymous(),
      expect: () => [
        const AuthLoading(),
        isA<AuthError>(),
      ],
    );
  });

  group('AuthCubit.signOut', () {
    blocTest<AuthCubit, AuthState>(
      'emits Unauthenticated after sign out',
      build: () {
        when(mockRepo.signOut()).thenAnswer((_) async {});
        return AuthCubit(mockRepo);
      },
      act: (cubit) => cubit.signOut(),
      expect: () => [const AuthUnauthenticated()],
    );
  });

  group('AuthCubit.deleteAccount', () {
    blocTest<AuthCubit, AuthState>(
      'emits [Loading, Unauthenticated] on success',
      build: () {
        when(mockRepo.deleteAccount()).thenAnswer((_) async {});
        return AuthCubit(mockRepo);
      },
      act: (cubit) => cubit.deleteAccount(),
      expect: () => [
        const AuthLoading(),
        const AuthUnauthenticated(),
      ],
    );

    blocTest<AuthCubit, AuthState>(
      'emits [Loading, Error] on failure',
      build: () {
        when(mockRepo.deleteAccount()).thenThrow(Exception('delete failed'));
        return AuthCubit(mockRepo);
      },
      act: (cubit) => cubit.deleteAccount(),
      expect: () => [
        const AuthLoading(),
        isA<AuthError>(),
      ],
    );
  });
}
