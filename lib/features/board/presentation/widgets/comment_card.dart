import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../models/comment_model.dart';
import 'reaction_bar.dart';

class CommentCard extends StatelessWidget {
  final CommentModel comment;
  final String currentUserId;
  final bool isOwner;
  final void Function(String reactionKey) onToggleReaction;
  final VoidCallback onDelete;
  final VoidCallback? onTap;

  const CommentCard({
    super.key,
    required this.comment,
    required this.currentUserId,
    required this.isOwner,
    required this.onToggleReaction,
    required this.onDelete,
    this.onTap,
  });

  void _openDetail(BuildContext context) {
    context.push(
      '/comments/${comment.id}',
      extra: {
        'text': comment.text,
        'createdAt': comment.createdAt,
        'boardOwnerUid': comment.boardOwnerId,
        'isOwner': isOwner,
      },
    );
    onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: () => _openDetail(context),
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.memeYellow.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.ink.withValues(alpha: 0.18),
                        width: 1.25,
                      ),
                    ),
                    child: const Text(
                      'Анонимно',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (!comment.isRead)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.memePeach.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.memeOrange.withValues(alpha: 0.45),
                          width: 1.25,
                        ),
                      ),
                      child: const Text(
                        'Новое',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                  Text(
                    DateFormatter.relative(comment.createdAt),
                    style: theme.textTheme.bodySmall,
                  ),
                  if (isOwner) ...[
                    const SizedBox(width: 4),
                    _DeleteButton(onDelete: onDelete),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              Text(
                comment.text,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ReactionBar(
                      comment: comment,
                      currentUserId: currentUserId,
                      onToggle: onToggleReaction,
                    ),
                  ),
                  if (comment.replyCount > 0)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.chat_bubble_outline,
                          size: 14,
                          color: AppColors.secondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${comment.replyCount}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeleteButton extends StatelessWidget {
  final VoidCallback onDelete;

  const _DeleteButton({required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.delete_outline, size: 18),
      color: AppColors.textSecondaryLight,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      tooltip: 'Удалить',
      onPressed: () => _showDeleteDialog(context),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Удалить сообщение?'),
        content: const Text('Это действие нельзя отменить.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onDelete();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }
}
