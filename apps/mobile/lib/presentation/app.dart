import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:last_mile_tracker/core/theme/app_theme.dart';
import 'package:last_mile_tracker/presentation/providers/theme_provider.dart';
import 'pages/home_page.dart';

class LastMileTrackerApp extends ConsumerWidget {
  const LastMileTrackerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return CupertinoApp(
      debugShowCheckedModeBanner: false,
      title: 'Last Mile Tracker',
      theme: _getTheme(themeMode, context),
      home: const HomePage(),
    );
  }

  CupertinoThemeData _getTheme(AppThemeMode mode, BuildContext context) {
    switch (mode) {
      case AppThemeMode.light:
        return AppTheme.lightTheme;
      case AppThemeMode.dark:
        return AppTheme.darkTheme;
      case AppThemeMode.system:
        final brightness = MediaQuery.platformBrightnessOf(context);
        return brightness == Brightness.dark
            ? AppTheme.darkTheme
            : AppTheme.lightTheme;
    }
  }
}
