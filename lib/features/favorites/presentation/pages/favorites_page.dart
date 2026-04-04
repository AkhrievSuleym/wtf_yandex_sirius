import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_error_widget.dart';
import '../../../../core/widgets/shimmer_widgets.dart';
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
      body: BlocListener<AuthCubit, AuthState>(
        listenWhen: (prev, curr) =>
            curr is AuthAuthenticated && prev is! AuthAuthenticated,
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            context.read<FavoritesCubit>().subscribeFavorites(state.user.uid);
          }
        },
        child: BlocBuilder<FavoritesCubit, FavoritesState>(
          builder: (context, state) {
            return switch (state) {
              FavoritesInitial() ||
              FavoritesLoading() =>
                const FavoritesShimmer(),
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
                        )
                            .animate(delay: Duration(milliseconds: 40 * i))
                            .fadeIn(duration: 200.ms)
                            .slideX(begin: 0.05, end: 0, duration: 200.ms);
                      },
                    ),
            };
          },
        ),
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
