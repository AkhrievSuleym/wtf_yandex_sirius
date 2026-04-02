import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../core/utils/app_logger.dart';
import '../features/auth/presentation/cubits/auth_cubit.dart';
import '../features/auth/presentation/cubits/auth_state.dart';
import '../features/notifications/notification_service.dart';
import '../navigation/app_router.dart';
import 'di/injection.dart';
import 'theme/app_theme.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  static const _tag = 'App';

  late final AuthCubit _authCubit;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _authCubit = getIt<AuthCubit>();
    _authCubit.checkAuthStatus();

    // Init FCM when user becomes authenticated
    _authCubit.stream.listen((state) {
      if (state is AuthAuthenticated) {
        AppLogger.i(_tag, 'User authenticated → init FCM');
        NotificationService().init(navigatorKey: _navigatorKey);
      }
    });
  }

  @override
  void dispose() {
    NotificationService().dispose();
    _authCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _authCubit,
      child: Builder(
        builder: (context) {
          final router = createRouter(_authCubit);
          return MaterialApp.router(
            title: 'WTF',
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: ThemeMode.system,
            routerConfig: router,
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
