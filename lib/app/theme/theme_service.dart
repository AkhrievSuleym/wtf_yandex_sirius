import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService {
  final SharedPreferences _prefs;
  final ValueNotifier<ThemeMode> _themeModeNotifier;

  ThemeService(this._prefs)
      : _themeModeNotifier = ValueNotifier<ThemeMode>(ThemeMode.system) {
    _loadThemeMode();
  }

  ValueNotifier<ThemeMode> get themeModeNotifier => _themeModeNotifier;

  Future<void> _loadThemeMode() async {
    final themeIndex = _prefs.getInt('theme_mode');
    if (themeIndex != null) {
      _themeModeNotifier.value = ThemeMode.values[themeIndex];
    } else {
      // Default to dark theme if not set
      _themeModeNotifier.value = ThemeMode.dark;
    }
  }

  Future<void> saveThemeMode(ThemeMode mode) async {
    await _prefs.setInt('theme_mode', mode.index);
    _themeModeNotifier.value = mode;
  }

  Future<void> toggleTheme() async {
    final currentMode = _themeModeNotifier.value;
    final newMode =
        currentMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    await saveThemeMode(newMode);
  }

  bool get isDarkMode => _themeModeNotifier.value == ThemeMode.dark;
}
