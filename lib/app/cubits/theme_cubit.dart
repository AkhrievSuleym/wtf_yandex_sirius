import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_visual_theme.dart';

class ThemeCubit extends Cubit<AppVisualTheme> {
  static const _key = 'visual_theme';

  final SharedPreferences _prefs;

  ThemeCubit(this._prefs)
      : super(_load(_prefs));

  static AppVisualTheme _load(SharedPreferences prefs) {
    final saved = prefs.getString(_key);
    return AppVisualTheme.values.firstWhere(
      (t) => t.name == saved,
      orElse: () => AppVisualTheme.meme,
    );
  }

  Future<void> setTheme(AppVisualTheme theme) async {
    await _prefs.setString(_key, theme.name);
    emit(theme);
  }
}
