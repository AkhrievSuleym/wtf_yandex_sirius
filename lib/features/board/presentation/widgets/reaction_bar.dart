import 'package:flutter/material.dart';
import '../../../board/models/comment_model.dart';
import '../../../../app/theme/app_colors.dart';

class ReactionBar extends StatelessWidget {
  final CommentModel comment;
  final String currentUserId;
  final void Function(String reactionKey) onToggle;

  const ReactionBar({
    super.key,
    required this.comment,
    required this.currentUserId,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: CommentModel.reactionKeys.map((key) {
        final count = comment.reactions[key] ?? 0;
        final isActive = comment.hasReacted(key, currentUserId);

        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: _ReactionChip(
            emoji: CommentModel.emojiFor(key),
            count: count,
            isActive: isActive,
            onTap: () => onToggle(key),
          ),
        );
      }).toList(),
    );
  }
}

class _ReactionChip extends StatelessWidget {
  final String emoji;
  final int count;
  final bool isActive;
  final VoidCallback onTap;

  const _ReactionChip({
    required this.emoji,
    required this.count,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primary.withValues(alpha: 0.12)
              : Colors.transparent,
          border: Border.all(
            color: isActive ? AppColors.primary : AppColors.divider,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 14)),
            if (count > 0) ...[
              const SizedBox(width: 4),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isActive ? AppColors.primary : null,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
