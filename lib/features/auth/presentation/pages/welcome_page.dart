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
                Image.asset(
                  'assets/images/splash_logo.png',
                  width: 108,
                  height: 108,
                  fit: BoxFit.contain,
                )
                    .animate()
                    .fadeIn(duration: 400.ms)
                    .scale(begin: const Offset(0.8, 0.8), duration: 400.ms),
                const SizedBox(height: 32),
                Text(
                  'What They Feel',
                  style: theme.textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                )
                    .animate(delay: 200.ms)
                    .fadeIn(duration: 300.ms)
                    .slideY(begin: 0.2, end: 0, duration: 300.ms),
                const SizedBox(height: 12),
                Text(
                  'Анонимные сообщения.\nЧестная обратная связь.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondaryDark,
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
  const WelcomePagePreview({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.dark,
      home: const WelcomePage(),
    );
  }
}
