import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../app/di/injection.dart';
import '../features/auth/presentation/cubits/auth_cubit.dart';
import '../features/auth/presentation/cubits/auth_state.dart';
import '../features/auth/presentation/pages/change_password_page.dart';
import '../features/auth/presentation/pages/create_profile_page.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/sign_up_page.dart';
import '../features/auth/presentation/pages/welcome_page.dart';
import '../features/board/presentation/cubits/board_cubit.dart';
import '../features/board/presentation/pages/board_page.dart';
import '../features/board/presentation/pages/comment_detail_page.dart';
import '../features/comment/presentation/cubits/comment_cubit.dart';
import '../features/comment/presentation/pages/send_comment_page.dart';
import '../features/favorites/presentation/cubits/favorites_cubit.dart';
import '../features/favorites/presentation/pages/favorites_page.dart';
import '../features/profile/presentation/cubits/profile_cubit.dart';
import '../features/profile/presentation/pages/my_profile_page.dart';
import '../features/profile/presentation/pages/public_profile_page.dart';
import '../features/profile/presentation/pages/settings_page.dart';
import '../features/search/presentation/cubits/search_cubit.dart';
import '../features/search/presentation/pages/search_page.dart';
import '../features/deep_link/presentation/pages/deep_link_page.dart';
import '../features/splash/presentation/pages/splash_page.dart';
import 'route_names.dart';
import 'shell_route.dart';

GoRouter createRouter(AuthCubit authCubit) {
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: _AuthStateListenable(authCubit),
    redirect: (context, state) {
      final uri = state.uri;
      if (uri.scheme == 'wtf') {
        if (uri.host == 'u' && uri.pathSegments.isNotEmpty) {
          return '/u/${Uri.encodeComponent(uri.pathSegments.first)}';
        }
        if (uri.path.startsWith('/u/') && uri.path.length > 3) {
          return uri.path;
        }
      }

      final authState = authCubit.state;
      final path = state.uri.path;

      // Let splash screen show without redirect
      if (path == '/splash') return null;

      final isOnAuth = path == '/welcome' ||
          path == '/sign-up' ||
          path == '/login' ||
          path == '/create-profile';

      if (authState is AuthLoading || authState is AuthInitial) return null;

      if (authState is AuthUnauthenticated) {
        if (isOnAuth) return null;
        if (_isPublicPathWhenLoggedOut(path)) return null;
        return '/welcome';
      }

      if (authState is AuthNeedsProfile) {
        return path == '/create-profile' ? null : '/create-profile';
      }

      if (authState is AuthAuthenticated) {
        return isOnAuth ? '/board' : null;
      }

      return null;
    },
    routes: [
      // Splash screen
      GoRoute(
        path: '/splash',
        name: RouteNames.splash,
        builder: (_, __) => const SplashPage(),
      ),
      // Deep link: wtf://u/{username}
      GoRoute(
        path: '/u/:username',
        name: RouteNames.deepLink,
        builder: (_, state) => DeepLinkPage(
          username: state.pathParameters['username']!,
        ),
      ),
      GoRoute(
        path: '/welcome',
        name: RouteNames.welcome,
        builder: (_, __) => const WelcomePage(),
      ),
      GoRoute(
        path: '/sign-up',
        name: RouteNames.signUp,
        builder: (_, __) => const SignUpPage(),
      ),
      GoRoute(
        path: '/login',
        name: RouteNames.login,
        builder: (_, __) => const LoginPage(),
      ),
      GoRoute(
        path: '/create-profile',
        name: RouteNames.createProfile,
        builder: (_, __) => const CreateProfilePage(),
      ),
      // Comment detail — accessible from anywhere via context.push
      GoRoute(
        path: '/comments/:id',
        name: RouteNames.commentDetail,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return BlocProvider(
            create: (_) => getIt<BoardCubit>(),
            child: CommentDetailPage(
              commentId: state.pathParameters['id']!,
              commentText: extra['text'] as String? ?? '',
              commentCreatedAt:
                  extra['createdAt'] as DateTime? ?? DateTime.now(),
              boardOwnerUid: extra['boardOwnerUid'] as String? ?? '',
              isOwner: extra['isOwner'] as bool? ?? false,
              commentAuthorId: extra['authorId'] as String?,
              commentAuthorAvatarUrl: extra['authorAvatarUrl'] as String?,
            ),
          );
        },
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, __, navigationShell) => MultiBlocProvider(
          providers: [
            BlocProvider.value(value: getIt<FavoritesCubit>()),
            BlocProvider.value(value: getIt<ProfileCubit>()),
          ],
          child: ScaffoldWithBottomNav(navigationShell: navigationShell),
        ),
        branches: [
          // Tab 0 — Board
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/board',
                name: RouteNames.board,
                builder: (_, __) => BlocProvider.value(
                  value: getIt<BoardCubit>(instanceName: 'myBoard'),
                  child: const BoardPage(),
                ),
              ),
            ],
          ),
          // Tab 1 — Search
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/search',
                name: RouteNames.search,
                builder: (_, __) => BlocProvider(
                  create: (_) => getIt<SearchCubit>(),
                  child: const SearchPage(),
                ),
                routes: [
                  GoRoute(
                    path: ':uid',
                    name: RouteNames.publicProfile,
                    builder: (_, state) => BlocProvider(
                      create: (_) => getIt<BoardCubit>(),
                      child: PublicProfilePage(
                        uid: state.pathParameters['uid']!,
                      ),
                    ),
                    routes: [
                      GoRoute(
                        path: 'comment',
                        name: RouteNames.sendComment,
                        builder: (_, state) => BlocProvider(
                          create: (_) => getIt<CommentCubit>(),
                          child: SendCommentPage(
                            uid: state.pathParameters['uid']!,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          // Tab 2 — Favorites
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/favorites',
                name: RouteNames.favorites,
                builder: (_, __) => const FavoritesPage(),
                routes: [
                  GoRoute(
                    path: ':uid',
                    builder: (_, state) => BlocProvider(
                      create: (_) => getIt<BoardCubit>(),
                      child: PublicProfilePage(
                        uid: state.pathParameters['uid']!,
                      ),
                    ),
                    routes: [
                      GoRoute(
                        path: 'comment',
                        builder: (_, state) => BlocProvider(
                          create: (_) => getIt<CommentCubit>(),
                          child: SendCommentPage(
                            uid: state.pathParameters['uid']!,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          // Tab 3 — Profile
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                name: RouteNames.profile,
                builder: (_, __) => const MyProfilePage(),
                routes: [
                  GoRoute(
                    path: 'settings',
                    name: RouteNames.settings,
                    builder: (_, __) => const SettingsPage(),
                    routes: [
                      GoRoute(
                        path: 'change-password',
                        name: RouteNames.changePassword,
                        builder: (_, __) => const ChangePasswordPage(),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

class _AuthStateListenable extends ChangeNotifier {
  _AuthStateListenable(AuthCubit cubit) {
    cubit.stream.listen((_) => notifyListeners());
  }
}

bool _isPublicPathWhenLoggedOut(String path) {
  final segments = path.split('/').where((s) => s.isNotEmpty).toList();
  if (segments.length >= 2 && segments[0] == 'u' && segments[1].isNotEmpty) {
    return true;
  }
  if (segments.length >= 2 &&
      segments[0] == 'search' &&
      segments[1].isNotEmpty) {
    if (segments.length == 2) return true;
    if (segments.length == 3 && segments[2] == 'comment') return true;
  }
  if (segments.length >= 2 &&
      segments[0] == 'comments' &&
      segments[1].isNotEmpty &&
      segments.length == 2) {
    return true;
  }
  return false;
}
