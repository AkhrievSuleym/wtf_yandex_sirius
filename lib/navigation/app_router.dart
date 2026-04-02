import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../app/di/injection.dart';
import '../features/auth/presentation/cubits/auth_cubit.dart';
import '../features/auth/presentation/cubits/auth_state.dart';
import '../features/auth/presentation/pages/create_profile_page.dart';
import '../features/auth/presentation/pages/sign_up_page.dart';
import '../features/auth/presentation/pages/welcome_page.dart';
import '../features/board/presentation/cubits/board_cubit.dart';
import '../features/board/presentation/pages/board_page.dart';
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
import 'route_names.dart';
import 'shell_route.dart';

GoRouter createRouter(AuthCubit authCubit) {
  return GoRouter(
    initialLocation: '/board',
    refreshListenable: _AuthStateListenable(authCubit),
    redirect: (context, state) {
      final authState = authCubit.state;
      final path = state.uri.path;

      final isOnAuth = path == '/welcome' ||
          path == '/sign-up' ||
          path == '/create-profile';

      if (authState is AuthLoading || authState is AuthInitial) return null;

      if (authState is AuthUnauthenticated) {
        return isOnAuth ? null : '/welcome';
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
        path: '/create-profile',
        name: RouteNames.createProfile,
        builder: (_, __) => const CreateProfilePage(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, __, navigationShell) =>
            ScaffoldWithBottomNav(navigationShell: navigationShell),
        branches: [
          // Tab 0 — Board
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/board',
                name: RouteNames.board,
                builder: (_, __) => BlocProvider(
                  create: (_) => getIt<BoardCubit>(),
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
                    builder: (_, state) => MultiBlocProvider(
                      providers: [
                        BlocProvider(create: (_) => getIt<ProfileCubit>()),
                        BlocProvider(create: (_) => getIt<BoardCubit>()),
                        BlocProvider(create: (_) => getIt<FavoritesCubit>()
                          ..subscribeFavorites(
                            (authCubit.state as AuthAuthenticated?)?.user.uid ?? '',
                          )),
                      ],
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
                builder: (_, __) => BlocProvider(
                  create: (_) => getIt<FavoritesCubit>(),
                  child: const FavoritesPage(),
                ),
                routes: [
                  GoRoute(
                    path: ':uid',
                    builder: (_, state) => MultiBlocProvider(
                      providers: [
                        BlocProvider(create: (_) => getIt<ProfileCubit>()),
                        BlocProvider(create: (_) => getIt<BoardCubit>()),
                        BlocProvider(create: (_) => getIt<FavoritesCubit>()
                          ..subscribeFavorites(
                            (authCubit.state as AuthAuthenticated?)?.user.uid ?? '',
                          )),
                      ],
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
                builder: (_, __) => BlocProvider(
                  create: (_) => getIt<ProfileCubit>(),
                  child: const MyProfilePage(),
                ),
                routes: [
                  GoRoute(
                    path: 'settings',
                    name: RouteNames.settings,
                    builder: (_, __) => BlocProvider(
                      create: (_) => getIt<ProfileCubit>(),
                      child: const SettingsPage(),
                    ),
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
