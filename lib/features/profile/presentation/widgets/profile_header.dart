import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../board/models/comment_model.dart';
import '../../models/profile_model.dart';
import 'profile_avatar.dart';

class ProfileHeader extends StatelessWidget {
  final ProfileModel profile;
  final VoidCallback? onAvatarTap;
  final Widget? action;
  final bool avatarEditBadge;

  const ProfileHeader({
    super.key,
    required this.profile,
    this.onAvatarTap,
    this.action,
    this.avatarEditBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final secondary = theme.brightness == Brightness.dark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          ProfileAvatar(
            avatarUrl: profile.avatarUrl,
            size: 88,
            onTap: onAvatarTap,
            showCameraBadge: avatarEditBadge,
          ),
          const SizedBox(height: 16),
          Text(
            profile.displayName,
            style: theme.textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            '@${profile.username}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (profile.bio.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              profile.bio,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: secondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _StatChip(
                label: 'Сообщений',
                value: '${profile.commentCount}',
              ),
            ],
          ),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Реакции на доске',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: secondary,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: CommentModel.reactionKeys.map((key) {
              final n = profile.reactionStats[key] ?? 0;
              final emoji = CommentModel.emojiFor(key);
              final tint = AppColors.reactionTintForKey(key);
              return _ReactionStatPill(
                emoji: emoji,
                count: n,
                tint: tint,
              );
            }).toList(),
          ),
          if (action != null) ...[
            const SizedBox(height: 16),
            action!,
          ],
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;

  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.headlineSmall,
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _ReactionStatPill extends StatelessWidget {
  final String emoji;
  final int count;
  final Color tint;

  const _ReactionStatPill({
    required this.emoji,
    required this.count,
    required this.tint,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: tint.withValues(alpha: 0.35),
          width: 1.25,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 6),
          Text(
            '$count',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
