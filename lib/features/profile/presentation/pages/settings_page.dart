import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Настройки')),
      body: BlocBuilder<ProfileCubit, ProfileState>(
        builder: (context, state) {
          final isPublic = switch (state) {
            ProfileLoaded(:final profile) => profile.isPublic,
            ProfileUpdating(:final profile) => profile.isPublic,
            _ => true,
          };
          final isUpdating = state is ProfileUpdating;

          return ListView(
            children: [
              if (isUpdating) const LinearProgressIndicator(),
              SwitchListTile(
                title: const Text('Публичная доска'),
                subtitle: const Text('Все могут видеть сообщения на вашей доске'),
                value: isPublic,
                activeThumbColor: AppColors.primary,
                onChanged: isUpdating
                    ? null
                    : (value) {
                        context.read<ProfileCubit>().updateProfile(isPublic: value);
                      },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.lock_outline, color: AppColors.textSecondaryLight),
                title: const Text('Изменить пароль'),
                onTap: () => context.push('/profile/settings/change-password'),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout, color: AppColors.textSecondaryLight),
                title: const Text('Выйти из аккаунта'),
                onTap: () => _confirmSignOut(context),
              ),
              ListTile(
                leading: const Icon(Icons.delete_forever, color: AppColors.error),
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
        content: const Text('Войти обратно можно только если у вас установлен пароль.'),
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
