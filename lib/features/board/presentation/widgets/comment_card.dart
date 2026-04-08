import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../profile/presentation/widgets/profile_avatar.dart';
import '../../models/comment_model.dart';
import 'reaction_bar.dart';

enum _CommentKind { anonymous, mine, boardOwnerAuthor, other }

class CommentCard extends StatelessWidget {
  final CommentModel comment;
  final String currentUserId;
  final bool isBoardOwnerView;
  final Future<void> Function(String reactionKey) onToggleReaction;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  const CommentCard({
    super.key,
    required this.comment,
    required this.currentUserId,
    required this.isBoardOwnerView,
    required this.onToggleReaction,
    this.onDelete,
    this.onTap,
  });

  _CommentKind get _kind {
    if (comment.authorId == null) return _CommentKind.anonymous;
    if (comment.authorId == currentUserId) return _CommentKind.mine;
    if (comment.authorId == comment.boardOwnerId) {
      return _CommentKind.boardOwnerAuthor;
    }
    return _CommentKind.other;
  }

  String get _roleLabel {
    switch (_kind) {
      case _CommentKind.anonymous:
        return 'Анонимно';
      case _CommentKind.mine:
        return 'Ты';
      case _CommentKind.boardOwnerAuthor:
        return 'Владелец доски';
      case _CommentKind.other:
        return 'Участник';
    }
  }

  Color get _chipBg {
    switch (_kind) {
      case _CommentKind.anonymous:
        return AppColors.memeYellow.withValues(alpha: 0.9);
      case _CommentKind.mine:
        return AppColors.primaryDark.withValues(alpha: 0.22);
      case _CommentKind.boardOwnerAuthor:
        return AppColors.memeViolet.withValues(alpha: 0.35);
      case _CommentKind.other:
        return AppColors.primary.withValues(alpha: 0.14);
    }
  }

  Color get _cardBorder {
    switch (_kind) {
      case _CommentKind.anonymous:
        return AppColors.ink.withValues(alpha: 0.1);
      case _CommentKind.mine:
        return AppColors.primaryDark.withValues(alpha: 0.15);
      case _CommentKind.boardOwnerAuthor:
        return AppColors.memeViolet.withValues(alpha: 0.55);
      case _CommentKind.other:
        return AppColors.primary.withValues(alpha: 0.35);
    }
  }

  double get _cardBorderWidth {
    switch (_kind) {
      case _CommentKind.anonymous:
        return 1.25;
      default:
        return 2;
    }
  }

  void _openDetail(BuildContext context) {
    context.push(
      '/comments/${comment.id}',
      extra: {
        'text': comment.text,
        'createdAt': comment.createdAt,
        'boardOwnerUid': comment.boardOwnerId,
        'isOwner': isBoardOwnerView,
        'authorId': comment.authorId,
        'authorAvatarUrl': comment.authorAvatarUrl,
      },
    );
    onTap?.call();
  }

  static const _newBadgeMaxAge = Duration(minutes: 5);

  bool get _showNewBadge {
    if (comment.isRead) return false;
    final cutoff = DateTime.now().toUtc().subtract(_newBadgeMaxAge);
    return comment.createdAt.toUtc().isAfter(cutoff);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: _cardBorder, width: _cardBorderWidth),
      ),
      child: InkWell(
        onTap: () => _openDetail(context),
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ProfileAvatar(
                    avatarUrl: comment.authorAvatarUrl,
                    size: 44,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _chipBg,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppColors.ink.withValues(alpha: 0.18),
                                width: 1.25,
                              ),
                            ),
                            child: Text(
                              _roleLabel,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: AppColors.ink,
                              ),
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (_showNewBadge)
                          Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  AppColors.secondary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color:
                                    AppColors.secondary.withValues(alpha: 0.45),
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
                        if (onDelete != null) ...[
                          const SizedBox(width: 4),
                          _DeleteButton(onDelete: onDelete!),
                        ],
                      ],
                    ),
                  ),
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
                            color: AppColors.textSecondaryDark,
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
      color: AppColors.textSecondaryDark,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      tooltip: 'Удалить',
      onPressed: () => _showDeleteDialog(context),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Удалить сообщение?'),
        content: const Text('Это действие нельзя отменить.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
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
