import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeMode { system, light, dark }

class ThemeNotifier extends Notifier<AppThemeMode> {
  static const _key = 'theme_mode';

  @override
  AppThemeMode build() {
    // Load theme asynchronously but return default for now.
    // We can't await in build(), so we trigger a load.
    _loadTheme();
    return AppThemeMode.system;
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final savedMode = prefs.getString(_key);
    if (savedMode != null) {
      state = AppThemeMode.values.firstWhere(
        (e) => e.name == savedMode,
        orElse: () => AppThemeMode.system,
      );
    }
  }

  Future<void> setTheme(AppThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, mode.name);
  }
}

final themeProvider = NotifierProvider<ThemeNotifier, AppThemeMode>(() {
  return ThemeNotifier();
});
