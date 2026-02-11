import 'package:flutter/cupertino.dart';

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

  // Semantic Colors
  static const Color critical = CupertinoColors.systemRed;
  static const Color warning = CupertinoColors.systemOrange;
  static const Color success = CupertinoColors.systemGreen;

  // Theme Data
  static const CupertinoThemeData lightTheme = CupertinoThemeData(
    brightness: Brightness.light,
    primaryColor: primary,
    scaffoldBackgroundColor: background,
    barBackgroundColor: Color(0xCCF2F2F7),
    textTheme: CupertinoTextThemeData(
      navTitleTextStyle: TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 17,
        color: CupertinoColors.label,
      ),
    ),
  );

  static const CupertinoThemeData darkTheme = CupertinoThemeData(
    brightness: Brightness.dark,
    primaryColor: primary,
    scaffoldBackgroundColor: background,
    barBackgroundColor: Color(0xCC1C1C1E),
    textTheme: CupertinoTextThemeData(
      navTitleTextStyle: TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 17,
        color: CupertinoColors.white,
      ),
    ),
  );
}
