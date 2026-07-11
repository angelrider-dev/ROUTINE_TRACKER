import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _prefsKey = 'themeMode';

/// Persists the user's theme choice (System/Light/Dark) across restarts.
///
/// The initial value is loaded in main() BEFORE runApp() and injected via
/// an override — not loaded asynchronously after first frame — so there's
/// no flash of the wrong theme on cold start (see main.dart).
class ThemeModeNotifier extends Notifier<ThemeMode> {
  final ThemeMode _initial;
  ThemeModeNotifier([this._initial = ThemeMode.system]);

  @override
  ThemeMode build() => _initial;

  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, mode.name);
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

/// Call once, before runApp(), to read the saved theme choice synchronously
/// relative to first frame.
Future<ThemeMode> loadInitialThemeMode() async {
  final prefs = await SharedPreferences.getInstance();
  final saved = prefs.getString(_prefsKey);
  return ThemeMode.values.firstWhere(
    (m) => m.name == saved,
    orElse: () => ThemeMode.dark, // dark is this app's designed-first theme
  );
}
