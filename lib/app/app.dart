import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../core/utils/app_logger.dart';
import '../features/auth/presentation/cubits/auth_cubit.dart';
import '../navigation/app_router.dart';
import 'cubits/theme_cubit.dart';
import 'di/injection.dart';
import 'theme/app_theme.dart';
import 'theme/app_visual_theme.dart';
import 'theme/gothic_theme.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  static const _tag = 'App';

  late final AuthCubit _authCubit;
  late final ThemeCubit _themeCubit;

  @override
  void initState() {
    super.initState();
    _authCubit = getIt<AuthCubit>();
    _themeCubit = getIt<ThemeCubit>();
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
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _authCubit),
        BlocProvider.value(value: _themeCubit),
      ],
      child: BlocBuilder<ThemeCubit, AppVisualTheme>(
        builder: (context, visualTheme) {
          final light = visualTheme == AppVisualTheme.gothic
              ? GothicTheme.light
              : AppTheme.light;
          final dark = visualTheme == AppVisualTheme.gothic
              ? GothicTheme.dark
              : AppTheme.dark;

          return Builder(
            builder: (context) {
              final router = createRouter(_authCubit);
              return MaterialApp.router(
                title: 'WTF',
                theme: light,
                darkTheme: dark,
                themeMode: ThemeMode.system,
                routerConfig: router,
                debugShowCheckedModeBanner: false,
              );
            },
          );
        },
      ),
    );
  }
}
