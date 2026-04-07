import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../models/search_history_item.dart';

class SearchHistoryList extends StatelessWidget {
  final List<SearchHistoryItem> items;
  final void Function(SearchHistoryItem item) onItemTap;
  final VoidCallback onClear;

  const SearchHistoryList({
    super.key,
    required this.items,
    required this.onItemTap,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.history,
                  size: 48, color: AppColors.textSecondaryDark),
              const SizedBox(height: 12),
              Text(
                'История просмотров пуста',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondaryDark,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text(
                'Недавние',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondaryDark,
                    ),
              ),
              const Spacer(),
              TextButton(
                onPressed: onClear,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textSecondaryDark,
                  padding: EdgeInsets.zero,
                ),
                child: const Text('Очистить'),
              ),
            ],
          ),
        ),
        ...items.map(
          (item) => ListTile(
            onTap: () => onItemTap(item),
            leading: CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              child: item.viewedAvatarUrl != null
                  ? ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: item.viewedAvatarUrl!,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                      ),
                    )
                  : const Icon(Icons.person,
                      color: AppColors.primary, size: 20),
            ),
            title: Text(item.viewedDisplayName ?? item.query),
            subtitle: item.viewedUsername != null
                ? Text(
                    '@${item.viewedUsername}',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                    ),
                  )
                : null,
            trailing: const Icon(Icons.north_west,
                size: 16, color: AppColors.textSecondaryDark),
          ),
        ),
      ],
    );
  }
}
