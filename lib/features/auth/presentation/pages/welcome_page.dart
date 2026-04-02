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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 2),
              // Logo / Icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: const Center(
                  child: Text(
                    'WTF',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
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
              const Spacer(flex: 3),
              AppButton(
                label: 'Начать',
                onPressed: () => context.goNamed(RouteNames.signUp),
              ).animate(delay: 500.ms).fadeIn(duration: 300.ms).slideY(begin: 0.3, end: 0, duration: 300.ms),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
