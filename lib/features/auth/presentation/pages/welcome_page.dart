import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../navigation/route_names.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.memeGradientStart,
              AppColors.memeGradientMid,
              AppColors.memeGradientEnd,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                const Spacer(flex: 2),
                Transform.rotate(
                  angle: -0.07,
                  child: Container(
                    width: 108,
                    height: 108,
                    decoration: BoxDecoration(
                      color: AppColors.memeLime,
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(color: AppColors.ink, width: 3),
                      boxShadow: const [
                        BoxShadow(
                          color: AppColors.secondary,
                          offset: Offset(8, 8),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        'WTF',
                        style: TextStyle(
                          color: AppColors.ink,
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.8, 0.8), duration: 400.ms),
                const SizedBox(height: 32),
                Text(
                  'What They Feel',
                  style: theme.textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ).animate(delay: 200.ms).fadeIn(duration: 300.ms).slideY(begin: 0.2, end: 0, duration: 300.ms),
                const SizedBox(height: 12),
                Text(
                  'Анонимные сообщения.\nЧестная обратная связь.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                  textAlign: TextAlign.center,
                ).animate(delay: 350.ms).fadeIn(duration: 300.ms).slideY(begin: 0.2, end: 0, duration: 300.ms),
                const SizedBox(height: 20),
                Text(
                  'Если не установить пароль в настройках, при потере устройства или переустановке приложения восстановить аккаунт не получится.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondaryLight,
                    height: 1.35,
                  ),
                  textAlign: TextAlign.center,
                ).animate(delay: 420.ms).fadeIn(duration: 300.ms).slideY(begin: 0.15, end: 0, duration: 300.ms),
                const Spacer(flex: 3),
                AppButton(
                  label: 'Начать',
                  onPressed: () => context.pushNamed(RouteNames.signUp),
                ).animate(delay: 500.ms).fadeIn(duration: 300.ms).slideY(begin: 0.3, end: 0, duration: 300.ms),
                const SizedBox(height: 12),
                AppButton(
                  label: 'У меня есть аккаунт',
                  isOutlined: true,
                  onPressed: () => context.pushNamed(RouteNames.login),
                ).animate(delay: 580.ms).fadeIn(duration: 300.ms).slideY(begin: 0.3, end: 0, duration: 300.ms),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
