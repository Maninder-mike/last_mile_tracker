import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeMode { system, light, dark }

class ThemeState {
  final AppThemeMode mode;
  final Color accentColor;

  const ThemeState({
    required this.mode,
    this.accentColor = CupertinoColors.activeBlue,
  });

  ThemeState copyWith({AppThemeMode? mode, Color? accentColor}) {
    return ThemeState(
      mode: mode ?? this.mode,
      accentColor: accentColor ?? this.accentColor,
    );
  }
}

class ThemeNotifier extends Notifier<ThemeState> {
  static const _modeKey = 'theme_mode';
  static const _accentKey = 'accent_color';

  @override
  ThemeState build() {
    _loadTheme();
    return const ThemeState(mode: AppThemeMode.system);
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();

    final savedMode = prefs.getString(_modeKey);
    final savedAccentIndex = prefs.getInt(_accentKey);

    AppThemeMode mode = AppThemeMode.system;
    if (savedMode != null) {
      mode = AppThemeMode.values.firstWhere(
        (e) => e.name == savedMode,
        orElse: () => AppThemeMode.system,
      );
    }

    Color accent = CupertinoColors.activeBlue;
    if (savedAccentIndex != null) {
      accent = Color(savedAccentIndex);
    }

    state = ThemeState(mode: mode, accentColor: accent);
  }

  Future<void> setTheme(AppThemeMode mode) async {
    state = state.copyWith(mode: mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_modeKey, mode.name);
  }

  Future<void> setAccentColor(Color color) async {
    state = state.copyWith(accentColor: color);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_accentKey, color.toARGB32());
  }
}

final themeProvider = NotifierProvider<ThemeNotifier, ThemeState>(() {
  return ThemeNotifier();
});
