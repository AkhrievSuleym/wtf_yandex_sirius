import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../profile/models/profile_model.dart';

class SearchResultTile extends StatelessWidget {
  final ProfileModel profile;
  final VoidCallback onTap;

  const SearchResultTile({
    super.key,
    required this.profile,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        radius: 22,
        backgroundColor: AppColors.primary.withValues(alpha: 0.12),
        child: profile.avatarUrl != null
            ? ClipOval(
                child: CachedNetworkImage(
                  imageUrl: profile.avatarUrl!,
                  width: 44,
                  height: 44,
                  fit: BoxFit.cover,
                ),
              )
            : const Icon(Icons.person, color: AppColors.primary),
      ),
      title: Text(
        profile.displayName,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        '@${profile.username}',
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 13,
        ),
      ),
      trailing: const Icon(Icons.chevron_right),
    );
  }
}
