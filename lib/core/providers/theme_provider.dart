import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get_it/get_it.dart';

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});

class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.system) {
    _loadTheme();
  }

  final _prefs = GetIt.instance<SharedPreferences>();
  static const _themeKey = 'theme_mode';

  Future<void> _loadTheme() async {
    final themeIndex = _prefs.getInt(_themeKey);
    if (themeIndex != null && themeIndex < ThemeMode.values.length) {
      state = ThemeMode.values[themeIndex];
    } else {
      state = ThemeMode.system;
    }
  }

  Future<void> setTheme(ThemeMode mode) async {
    state = mode;
    await _prefs.setInt(_themeKey, mode.index);
  }

  void toggleTheme() {
    final newMode = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    setTheme(newMode);
  }
  
  bool get isDarkMode => state == ThemeMode.dark;
}
