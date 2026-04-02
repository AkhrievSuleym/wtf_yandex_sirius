import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  // External
  getIt.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  getIt.registerLazySingleton<FirebaseFirestore>(() {
    final firestore = FirebaseFirestore.instance;
    // Enable offline persistence with 100 MB cache
    firestore.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
    return firestore;
  });
  getIt.registerLazySingleton<FirebaseStorage>(() => FirebaseStorage.instance);

  final prefs = await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(prefs);

  // Repositories
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      auth: getIt<FirebaseAuth>(),
      firestore: getIt<FirebaseFirestore>(),
    ),
  );

  getIt.registerLazySingleton<BoardRepository>(
    () => BoardRepositoryImpl(firestore: getIt<FirebaseFirestore>()),
  );

  getIt.registerLazySingleton<CommentRepository>(
    () => CommentRepositoryImpl(
      firestore: getIt<FirebaseFirestore>(),
      auth: getIt<FirebaseAuth>(),
    ),
  );

  getIt.registerLazySingleton<ProfileRepository>(
    () => ProfileRepositoryImpl(
      firestore: getIt<FirebaseFirestore>(),
      auth: getIt<FirebaseAuth>(),
      storage: getIt<FirebaseStorage>(),
    ),
  );

  getIt.registerLazySingleton<SearchRepository>(
    () => SearchRepositoryImpl(
      firestore: getIt<FirebaseFirestore>(),
      prefs: getIt<SharedPreferences>(),
    ),
  );

  getIt.registerLazySingleton<FavoritesRepository>(
    () => FavoritesRepositoryImpl(firestore: getIt<FirebaseFirestore>()),
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
  getIt.registerFactory<ProfileCubit>(
    () => ProfileCubit(getIt<ProfileRepository>()),
  );
  getIt.registerFactory<SearchCubit>(
    () => SearchCubit(getIt<SearchRepository>()),
  );
  getIt.registerFactory<FavoritesCubit>(
    () => FavoritesCubit(getIt<FavoritesRepository>()),
  );
}
