import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/services/api_client.dart';
import '../cubits/theme_cubit.dart';
import '../../features/auth/presentation/cubits/auth_cubit.dart';
import '../../features/auth/repositories/auth_repository.dart';
import '../../features/auth/repositories/auth_repository_impl.dart';
import '../../features/board/presentation/cubits/board_cubit.dart';
import '../../features/board/repositories/board_repository.dart';
import '../../features/board/repositories/board_repository_impl.dart';
import '../../features/comment/presentation/cubits/comment_cubit.dart';
import '../../features/comment/repositories/comment_repository.dart';
import '../../features/comment/repositories/comment_repository_impl.dart';
import '../../features/favorites/presentation/cubits/favorites_cubit.dart';
import '../../features/favorites/repositories/favorites_repository.dart';
import '../../features/favorites/repositories/favorites_repository_impl.dart';
import '../../features/profile/presentation/cubits/profile_cubit.dart';
import '../../features/profile/repositories/profile_repository.dart';
import '../../features/profile/repositories/profile_repository_impl.dart';
import '../../features/search/presentation/cubits/search_cubit.dart';
import '../../features/search/repositories/search_repository.dart';
import '../../features/search/repositories/search_repository_impl.dart';

final getIt = GetIt.instance;

Future<void> setupDependencies() async {
  final prefs = await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(prefs);

  // Theme
  getIt.registerLazySingleton<ThemeCubit>(() => ThemeCubit(prefs));

  // Core
  getIt.registerLazySingleton<ApiClient>(() => ApiClient(prefs));

  // Repositories
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(getIt<ApiClient>()),
  );
  getIt.registerLazySingleton<BoardRepository>(
    () => BoardRepositoryImpl(getIt<ApiClient>()),
  );
  getIt.registerLazySingleton<CommentRepository>(
    () => CommentRepositoryImpl(getIt<ApiClient>()),
  );
  getIt.registerLazySingleton<ProfileRepository>(
    () => ProfileRepositoryImpl(getIt<ApiClient>()),
  );
  getIt.registerLazySingleton<SearchRepository>(
    () => SearchRepositoryImpl(
      api: getIt<ApiClient>(),
      prefs: getIt<SharedPreferences>(),
    ),
  );
  getIt.registerLazySingleton<FavoritesRepository>(
    () => FavoritesRepositoryImpl(getIt<ApiClient>()),
  );

  // Cubits (factory — новый экземпляр на каждый вызов)
  getIt.registerFactory<AuthCubit>(
    () => AuthCubit(getIt<AuthRepository>()),
  );
  getIt.registerFactory<BoardCubit>(
    () => BoardCubit(getIt<BoardRepository>()),
  );
  getIt.registerFactory<CommentCubit>(
    () => CommentCubit(getIt<CommentRepository>()),
  );
  getIt.registerLazySingleton<ProfileCubit>(
    () => ProfileCubit(getIt<ProfileRepository>()),
  );
  getIt.registerFactory<SearchCubit>(
    () => SearchCubit(
      getIt<SearchRepository>(),
      getIt<AuthRepository>(),
    ),
  );
  getIt.registerLazySingleton<FavoritesCubit>(
    () => FavoritesCubit(getIt<FavoritesRepository>()),
  );
}
