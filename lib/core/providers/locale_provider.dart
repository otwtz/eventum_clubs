import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get_it/get_it.dart';

const _keyLocale = 'playgo_locale';

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale?>((ref) {
  return LocaleNotifier(GetIt.instance<SharedPreferences>());
});

class LocaleNotifier extends StateNotifier<Locale?> {
  LocaleNotifier(this._prefs) : super(null) {
    _load();
  }

  final SharedPreferences _prefs;

  void _load() {
    final code = _prefs.getString(_keyLocale);
    if (code != null && code.isNotEmpty) {
      state = Locale(code);
    }
  }

  Future<void> setLocale(Locale locale) async {
    await _prefs.setString(_keyLocale, locale.languageCode);
    state = locale;
  }
}
