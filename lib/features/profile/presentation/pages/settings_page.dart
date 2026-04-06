import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/cubits/theme_cubit.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_visual_theme.dart';
import '../../../auth/presentation/cubits/auth_cubit.dart';
import '../../../auth/presentation/cubits/auth_state.dart';
import '../cubits/profile_cubit.dart';
import '../cubits/profile_state.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthAuthenticated) {
      context.read<ProfileCubit>().loadProfile(authState.user.uid);
    }
  }

  void _openThemePicker() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<ThemeCubit>(),
        child: const _ThemePickerSheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Настройки')),
      body: BlocBuilder<ProfileCubit, ProfileState>(
        builder: (context, state) {
          final isUpdating = state is ProfileUpdating;

          return ListView(
            children: [
              if (isUpdating) const LinearProgressIndicator(),
              // Visual theme picker
              BlocBuilder<ThemeCubit, AppVisualTheme>(
                builder: (context, current) {
                  return ListTile(
                    leading: Text(
                      current.emoji,
                      style: const TextStyle(fontSize: 22),
                    ),
                    title: const Text('Визуальная тема'),
                    subtitle: Text(current.label),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _openThemePicker,
                  );
                },
              ),
              const Divider(),
              ListTile(
                leading: Icon(
                  Icons.lock_outline,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                title: const Text('Изменить пароль'),
                onTap: () => context.push('/profile/settings/change-password'),
              ),
              const Divider(),
              ListTile(
                leading: Icon(
                  Icons.logout,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                title: const Text('Выйти из аккаунта'),
                onTap: () => _confirmSignOut(context),
              ),
              ListTile(
                leading:
                    const Icon(Icons.delete_forever, color: AppColors.error),
                title: const Text(
                  'Удалить аккаунт',
                  style: TextStyle(color: AppColors.error),
                ),
                onTap: () => _confirmDeleteAccount(context),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmSignOut(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Выйти?'),
        content: const Text(
            'Войти обратно можно только если у вас установлен пароль.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<AuthCubit>().signOut();
            },
            child: const Text('Выйти'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAccount(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Удалить аккаунт?'),
        content: const Text('Все ваши данные будут удалены безвозвратно.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<AuthCubit>().deleteAccount();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }
}

// ─── Theme picker bottom sheet ────────────────────────────────────────────────

class _ThemePickerSheet extends StatelessWidget {
  const _ThemePickerSheet();

  @override
  Widget build(BuildContext context) {
    final current = context.watch<ThemeCubit>().state;
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Визуальная тема', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(
            'Выберите стиль оформления приложения',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 20),
          Row(
            children: AppVisualTheme.values.map((t) {
              final isSelected = t == current;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: t != AppVisualTheme.values.last ? 12 : 0,
                  ),
                  child: _ThemeCard(
                    visualTheme: t,
                    isSelected: isSelected,
                    onTap: () {
                      context.read<ThemeCubit>().setTheme(t);
                      Navigator.pop(context);
                    },
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _ThemeCard extends StatelessWidget {
  final AppVisualTheme visualTheme;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeCard({
    required this.visualTheme,
    required this.isSelected,
    required this.onTap,
  });

  // Mini palette swatches for each theme
  List<Color> get _swatches => switch (visualTheme) {
        AppVisualTheme.meme => [
            AppColors.primary,
            AppColors.secondary,
            AppColors.memeLime,
            AppColors.memeYellow,
          ],
        // Gothic is always dark (dungeon aesthetic)
        AppVisualTheme.gothic => [
            const Color(0xFFC0182A), // blood crimson
            const Color(0xFF9E7C3A), // tarnished gold
            const Color(0xFF1A1A22), // dungeon stone
            const Color(0xFF0D0D12), // abyss
          ],
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = isSelected
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurface.withValues(alpha: 0.15);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.07)
              : theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: borderColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Colour swatches row
            Row(
              children: _swatches.map((c) {
                return Container(
                  width: 20,
                  height: 20,
                  margin: const EdgeInsets.only(right: 4),
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.black.withValues(alpha: 0.12),
                      width: 0.5,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            Text(
              visualTheme.emoji,
              style: const TextStyle(fontSize: 26),
            ),
            const SizedBox(height: 6),
            Text(
              visualTheme.label,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: isSelected ? theme.colorScheme.primary : null,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              visualTheme.description,
              style: theme.textTheme.bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (isSelected) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 14,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Активна',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
