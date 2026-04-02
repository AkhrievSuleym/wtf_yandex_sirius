import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_error_widget.dart';
import '../../../../core/widgets/shimmer_widgets.dart';
import '../../../auth/presentation/cubits/auth_cubit.dart';
import '../../../auth/presentation/cubits/auth_state.dart';
import '../cubits/board_cubit.dart';
import '../cubits/board_state.dart';
import '../widgets/comment_card.dart';
import '../widgets/empty_board.dart';

class BoardPage extends StatefulWidget {
  const BoardPage({super.key});

  @override
  State<BoardPage> createState() => _BoardPageState();
}

class _BoardPageState extends State<BoardPage> {
  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthAuthenticated) {
      context.read<BoardCubit>().subscribeToBoard(authState.user.uid);
    }
  }

  void _share(String username) {
    Share.share(
      'Напиши мне анонимно: wtf://u/$username',
      subject: 'Мой профиль WTF',
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    final username = authState is AuthAuthenticated
        ? authState.user.username
        : '';
    final userId = authState is AuthAuthenticated
        ? authState.user.uid
        : '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Моя доска'),
        actions: [
          BlocBuilder<BoardCubit, BoardState>(
            builder: (context, state) {
              final unread =
                  state is BoardLoaded ? state.unreadCount : 0;
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.share_outlined),
                    onPressed: () => _share(username),
                    tooltip: 'Поделиться профилем',
                  ),
                  if (unread > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: AppColors.unreadBadge,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          unread > 99 ? '99+' : '$unread',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<BoardCubit, BoardState>(
        builder: (context, state) {
          return switch (state) {
            BoardInitial() || BoardLoading() => const BoardShimmer(),
            BoardError(:final message) => AppErrorWidget(
                message: message,
                onRetry: () {
                  if (userId.isNotEmpty) {
                    context.read<BoardCubit>().subscribeToBoard(userId);
                  }
                },
              ),
            BoardLoaded(:final comments) => comments.isEmpty
                ? EmptyBoard(onShare: () => _share(username))
                : RefreshIndicator(
                    onRefresh: () async {
                      if (userId.isNotEmpty) {
                        context.read<BoardCubit>().subscribeToBoard(userId);
                      }
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: comments.length,
                      itemBuilder: (context, index) {
                        final comment = comments[index];
                        return CommentCard(
                          comment: comment,
                          currentUserId: userId,
                          isOwner: true,
                          onToggleReaction: (key) {
                            context
                                .read<BoardCubit>()
                                .toggleReaction(comment.id, key, userId);
                          },
                          onDelete: () {
                            context
                                .read<BoardCubit>()
                                .deleteComment(comment.id);
                          },
                          onTap: comment.isRead
                              ? null
                              : () => context
                                  .read<BoardCubit>()
                                  .markAsRead(comment.id),
                        )
                            .animate(delay: Duration(milliseconds: 40 * index))
                            .fadeIn(duration: 200.ms)
                            .slideY(begin: 0.08, end: 0, duration: 200.ms);
                      },
                    ),
                  ),
          };
        },
      ),
    );
  }
}
