import 'package:flutter/cupertino.dart';
import 'package:last_mile_tracker/presentation/providers/theme_provider.dart';

class AppTheme {
  const AppTheme._();

  // Primary Colors
  static const Color primary = CupertinoDynamicColor.withBrightness(
    color: CupertinoColors.activeBlue,
    darkColor: Color(0xFF0A84FF),
  );

  static const Color background = CupertinoDynamicColor.withBrightness(
    color: CupertinoColors.systemGroupedBackground,
    darkColor: CupertinoColors.black,
  );

  static const Color surface = CupertinoDynamicColor.withBrightness(
    color: CupertinoColors.white,
    darkColor: Color(0xFF1C1C1E), // Secondary System Grouped
  );

  // Spacing Tokens
  static const double s4 = 4.0;
  static const double s8 = 8.0;
  static const double s12 = 12.0;
  static const double s16 = 16.0;
  static const double s20 = 20.0;
  static const double s24 = 24.0;
  static const double s32 = 32.0;

  // Radius Tokens
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 16.0;
  static const double radiusLarge = 24.0;

  // Icon Size Tokens
  static const double iconSizeSmall = 16.0;
  static const double iconSizeMedium = 20.0;
  static const double iconSizeLarge = 24.0;

  // Shimmer Colors
  static const Color shimmerBase = CupertinoDynamicColor.withBrightness(
    color: Color(0xFFE1E1E1),
    darkColor: Color(0xFF2C2C2E),
  );

  static const Color shimmerHighlight = CupertinoDynamicColor.withBrightness(
    color: Color(0xFFF5F5F7),
    darkColor: Color(0xFF3A3A3C),
  );

  // Glassmorphism
  static const Color surfaceGlass = CupertinoDynamicColor.withBrightness(
    color: Color(0xCCFFFFFF), // White ~80%
    darkColor: Color(0xCC1C1C1E), // Dark Gray ~80%
  );

  // Text Colors
  static const Color textPrimary = CupertinoDynamicColor.withBrightness(
    color: CupertinoColors.label,
    darkColor: CupertinoColors.white,
  );

  static const Color textSecondary = CupertinoDynamicColor.withBrightness(
    color: CupertinoColors.secondaryLabel,
    darkColor: Color(0xFF8E8E93),
  );

  // Text Styles
  static const TextStyle title = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.4,
    color: textPrimary,
  );

  static const TextStyle heading1 = TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.4,
    color: textPrimary,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.4,
    color: textPrimary,
  );

  static const TextStyle body = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.4,
    color: textPrimary,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: textSecondary,
  );

  static const TextStyle label = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
    color: textSecondary,
  );

  // Semantic Colors
  static const Color critical = CupertinoColors.systemRed;
  static const Color warning = CupertinoColors.systemOrange;
  static const Color success = CupertinoColors.systemGreen;

  // Theme Data
  static CupertinoThemeData getTheme(
    ThemeState themeState,
    BuildContext context,
  ) {
    final Brightness brightness;
    if (themeState.mode == AppThemeMode.system) {
      brightness = MediaQuery.platformBrightnessOf(context);
    } else {
      brightness = themeState.mode == AppThemeMode.dark
          ? Brightness.dark
          : Brightness.light;
    }

    final bool isDark = brightness == Brightness.dark;

    return CupertinoThemeData(
      brightness: brightness,
      primaryColor: themeState.accentColor,
      scaffoldBackgroundColor: isDark
          ? CupertinoColors.black
          : CupertinoColors.systemGroupedBackground,
      barBackgroundColor: isDark
          ? const Color(0xCC1C1C1E)
          : const Color(0xCCF2F2F7),
      textTheme: CupertinoTextThemeData(
        navTitleTextStyle: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 17,
          color: isDark ? CupertinoColors.white : CupertinoColors.label,
        ),
      ),
    );
  }
}
