import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wtf_yandex_sirius/features/auth/presentation/pages/welcome_page.dart';
import 'package:wtf_yandex_sirius/app/theme/app_theme.dart';

void main() {
  testWidgets('WelcomePage renders title and buttons',
      (WidgetTester tester) async {
    // Build the widget
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const WelcomePage(),
      ),
    );

    // Let animations run/finish
    await tester.pumpAndSettle();

    // Verify Title existence
    expect(find.text('What They Feel'), findsOneWidget);

    // Verify Description existence
    expect(find.textContaining('Анонимные сообщения'), findsOneWidget);

    // Verify Buttons existence
    expect(find.text('Начать'), findsOneWidget);
    expect(find.text('У меня есть аккаунт'), findsOneWidget);
  });
}
