import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_error_widget.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../auth/presentation/cubits/auth_cubit.dart';
import '../../../auth/presentation/cubits/auth_state.dart';
import '../cubits/favorites_cubit.dart';
import '../cubits/favorites_state.dart';
import '../widgets/favorite_profile_tile.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthAuthenticated) {
      context.read<FavoritesCubit>().subscribeFavorites(authState.user.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Избранное')),
      body: BlocBuilder<FavoritesCubit, FavoritesState>(
        builder: (context, state) {
          return switch (state) {
            FavoritesInitial() || FavoritesLoading() => const LoadingIndicator(),
            FavoritesError(:final message) => AppErrorWidget(
                message: message,
                onRetry: () {
                  final authState = context.read<AuthCubit>().state;
                  if (authState is AuthAuthenticated) {
                    context
                        .read<FavoritesCubit>()
                        .subscribeFavorites(authState.user.uid);
                  }
                },
              ),
            FavoritesLoaded(:final favorites) => favorites.isEmpty
                ? _EmptyFavorites()
                : ListView.builder(
                    itemCount: favorites.length,
                    itemBuilder: (_, i) {
                      final profile = favorites[i];
                      return FavoriteProfileTile(
                        profile: profile,
                        onTap: () =>
                            context.push('/favorites/${profile.uid}'),
                        onRemove: () {
                          final authState = context.read<AuthCubit>().state;
                          if (authState is AuthAuthenticated) {
                            context
                                .read<FavoritesCubit>()
                                .removeFromFavorites(profile.uid);
                          }
                        },
                      );
                    },
                  ),
          };
        },
      ),
    );
  }
}

class _EmptyFavorites extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('⭐', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 20),
            Text(
              'Избранное пусто',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Text(
              'Добавляйте профили в избранное\nдля быстрого доступа',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
