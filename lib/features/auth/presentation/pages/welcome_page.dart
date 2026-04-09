import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../navigation/route_names.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final gradientColors = isDark
        ? [
            AppColors.memeGradientStart,
            AppColors.memeGradientMid,
            AppColors.memeGradientEnd,
          ]
        : [
            const Color(0xFFFDFBFF),
            const Color(0xFFF3EDFF),
            const Color(0xFFEBE0FF),
          ];

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                const Spacer(flex: 2),
                Image.asset(
                  'assets/images/splash_logo.png',
                  width: 108,
                  height: 108,
                  fit: BoxFit.contain,
                  color: isDark ? null : AppColors.primary,
                )
                    .animate()
                    .fadeIn(duration: 400.ms)
                    .scale(begin: const Offset(0.8, 0.8), duration: 400.ms),
                const SizedBox(height: 32),
                Text(
                  'What They Feel',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color:
                        isDark ? AppColors.textPrimaryDark : AppColors.primary,
                  ),
                  textAlign: TextAlign.center,
                )
                    .animate(delay: 200.ms)
                    .fadeIn(duration: 300.ms)
                    .slideY(begin: 0.2, end: 0, duration: 300.ms),
                const SizedBox(height: 12),
                Text(
                  'Анонимные сообщения.\nЧестная обратная связь.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: isDark
                        ? AppColors.textPrimaryDark.withValues(alpha: 0.7)
                        : AppColors.textSecondaryLight,
                  ),
                  textAlign: TextAlign.center,
                )
                    .animate(delay: 350.ms)
                    .fadeIn(duration: 300.ms)
                    .slideY(begin: 0.2, end: 0, duration: 300.ms),
                const Spacer(flex: 3),
                AppButton(
                  label: 'Начать',
                  onPressed: () => context.pushNamed(RouteNames.signUp),
                )
                    .animate(delay: 500.ms)
                    .fadeIn(duration: 300.ms)
                    .slideY(begin: 0.3, end: 0, duration: 300.ms),
                const SizedBox(height: 12),
                AppButton(
                  label: 'У меня есть аккаунт',
                  isOutlined: true,
                  onPressed: () => context.pushNamed(RouteNames.login),
                )
                    .animate(delay: 580.ms)
                    .fadeIn(duration: 300.ms)
                    .slideY(begin: 0.3, end: 0, duration: 300.ms),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class WelcomePagePreview extends StatelessWidget {
  final ThemeMode themeMode;
  const WelcomePagePreview({super.key, this.themeMode = ThemeMode.system});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      home: const WelcomePage(),
    );
  }
}
