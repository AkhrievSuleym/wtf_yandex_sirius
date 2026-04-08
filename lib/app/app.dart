import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../core/utils/app_logger.dart';
import '../features/auth/presentation/cubits/auth_cubit.dart';
import '../navigation/app_router.dart';
import 'di/injection.dart';
import 'theme/app_theme.dart';
import 'theme/theme_service.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  static const _tag = 'App';

  late final AuthCubit _authCubit;
  late final GoRouter _router;
  late final ThemeService _themeService;

  @override
  void initState() {
    super.initState();
    _authCubit = getIt<AuthCubit>();
    _router = createRouter(_authCubit);
    _themeService = getIt<ThemeService>();
    AppLogger.i(_tag, 'checkAuthStatus');
    _authCubit.checkAuthStatus();
  }

  @override
  void dispose() {
    _authCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _authCubit,
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: _themeService.themeModeNotifier,
        builder: (context, themeMode, child) {
          return MaterialApp.router(
            title: 'WTF',
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeMode,
            routerConfig: _router,
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
