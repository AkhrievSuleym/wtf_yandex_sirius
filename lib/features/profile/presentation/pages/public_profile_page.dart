import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/app_error_widget.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../core/widgets/shimmer_widgets.dart';
import '../../../auth/presentation/cubits/auth_cubit.dart';
import '../../../auth/presentation/cubits/auth_state.dart';
import '../../../board/presentation/cubits/board_cubit.dart';
import '../../../board/presentation/cubits/board_state.dart';
import '../../../board/presentation/widgets/comment_card.dart';
import '../../../favorites/presentation/cubits/favorites_cubit.dart';
import '../cubits/profile_cubit.dart';
import '../cubits/profile_state.dart';
import '../widgets/profile_header.dart';

class PublicProfilePage extends StatefulWidget {
  final String uid;

  const PublicProfilePage({super.key, required this.uid});

  @override
  State<PublicProfilePage> createState() => _PublicProfilePageState();
}

class _PublicProfilePageState extends State<PublicProfilePage> {
  bool _isFavorite = false;
  bool _favoriteLoading = false;

  @override
  void initState() {
    super.initState();
    context.read<ProfileCubit>().loadProfile(widget.uid);
    context.read<BoardCubit>().subscribeToBoard(widget.uid);
    _checkFavorite();
  }

  Future<void> _checkFavorite() async {
    final result =
        await context.read<FavoritesCubit>().isFavorite(widget.uid);
    if (mounted) setState(() => _isFavorite = result);
  }

  Future<void> _toggleFavorite() async {
    final profileState = context.read<ProfileCubit>().state;
    if (profileState is! ProfileLoaded) return;

    setState(() => _favoriteLoading = true);

    if (_isFavorite) {
      await context.read<FavoritesCubit>().removeFromFavorites(widget.uid);
    } else {
      await context
          .read<FavoritesCubit>()
          .addToFavorites(profileState.profile);
    }

    if (mounted) {
      setState(() {
        _isFavorite = !_isFavorite;
        _favoriteLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    final currentUserId =
        authState is AuthAuthenticated ? authState.user.uid : '';

    return Scaffold(
      appBar: AppBar(
        actions: [
          _favoriteLoading
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : IconButton(
                  icon: Icon(
                    _isFavorite ? Icons.star : Icons.star_outline,
                    color: _isFavorite ? Colors.amber : null,
                  ),
                  tooltip: _isFavorite ? 'Убрать из избранного' : 'В избранное',
                  onPressed: _toggleFavorite,
                ),
        ],
      ),
      body: BlocBuilder<ProfileCubit, ProfileState>(
        builder: (context, profileState) {
          if (profileState is ProfileLoading || profileState is ProfileInitial) {
            return const ProfileHeaderShimmer();
          }
          if (profileState is ProfileError) {
            return AppErrorWidget(
              message: profileState.message,
              onRetry: () =>
                  context.read<ProfileCubit>().loadProfile(widget.uid),
            );
          }

          final profile = (profileState as ProfileLoaded).profile;

          return NestedScrollView(
            headerSliverBuilder: (_, __) => [
              SliverToBoxAdapter(
                child: ProfileHeader(
                  profile: profile,
                  action: _WriteButton(uid: widget.uid),
                ),
              ),
              const SliverToBoxAdapter(child: Divider()),
            ],
            body: BlocBuilder<BoardCubit, BoardState>(
              builder: (context, boardState) {
                return switch (boardState) {
                  BoardLoading() || BoardInitial() => const LoadingIndicator(),
                  BoardError(:final message) => AppErrorWidget(message: message),
                  BoardLoaded(:final comments) => comments.isEmpty
                      ? const Center(child: Text('Пока нет сообщений'))
                      : ListView.builder(
                          itemCount: comments.length,
                          itemBuilder: (_, i) {
                            final comment = comments[i];
                            return CommentCard(
                              comment: comment,
                              currentUserId: currentUserId,
                              isOwner: false,
                              onToggleReaction: (key) => context
                                  .read<BoardCubit>()
                                  .toggleReaction(
                                      comment.id, key, currentUserId),
                              onDelete: () {},
                            );
                          },
                        ),
                };
              },
            ),
          );
        },
      ),
    );
  }
}

class _WriteButton extends StatelessWidget {
  final String uid;

  const _WriteButton({required this.uid});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final isFromFavorites = location.startsWith('/favorites');
    final commentPath =
        isFromFavorites ? '/favorites/$uid/comment' : '/search/$uid/comment';

    return ElevatedButton.icon(
      onPressed: () => context.push(commentPath),
      icon: const Icon(Icons.edit_outlined, size: 18),
      label: const Text('Написать анонимно'),
      style: ElevatedButton.styleFrom(minimumSize: const Size(0, 44)),
    );
  }
}
