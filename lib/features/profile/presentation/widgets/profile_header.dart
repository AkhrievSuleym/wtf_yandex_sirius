import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../models/profile_model.dart';
import 'profile_avatar.dart';

class ProfileHeader extends StatelessWidget {
  final ProfileModel profile;
  final VoidCallback? onAvatarTap;
  final Widget? action;

  const ProfileHeader({
    super.key,
    required this.profile,
    this.onAvatarTap,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          ProfileAvatar(
            avatarUrl: profile.avatarUrl,
            size: 88,
            onTap: onAvatarTap,
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
                color: AppColors.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _StatChip(
                label: 'Сообщений',
                value: '${profile.commentCount}',
              ),
            ],
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
