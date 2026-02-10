import 'package:flutter/cupertino.dart';

class AppTheme {
  const AppTheme._();

  // Primary Colors (Dynamic Light/Dark)
  static const Color primary = CupertinoDynamicColor.withBrightness(
    color: Color(0xFF007AFF), // iOS Blue (Light)
    darkColor: Color(0xFF0A84FF), // iOS Blue (Dark)
  );

  static const Color background = CupertinoDynamicColor.withBrightness(
    color: Color(0xFFF2F2F7), // iOS System Grouped Background (Light)
    darkColor: Color(0xFF000000), // iOS Black (Dark)
  );

  static const Color surface = CupertinoDynamicColor.withBrightness(
    color: CupertinoColors.white,
    darkColor: Color(
      0xFF1C1C1E,
    ), // iOS Secondary System Grouped Background (Dark)
  );

  // Glassmorphism Colors
  static const Color surfaceGlass = CupertinoDynamicColor.withBrightness(
    color: Color(0xCCFFFFFF), // White with 80% opacity
    darkColor: Color(0xCC1C1C1E), // Dark Gray with 80% opacity
  );

  // Semantic Colors
  static const Color critical = CupertinoDynamicColor.withBrightness(
    color: Color(0xFFFF3B30), // iOS Red
    darkColor: Color(0xFFFF453A),
  );

  static const Color warning = CupertinoDynamicColor.withBrightness(
    color: Color(0xFFFF9500), // iOS Orange
    darkColor: Color(0xFFFF9F0A),
  );

  static const Color success = CupertinoDynamicColor.withBrightness(
    color: Color(0xFF34C759), // iOS Green
    darkColor: Color(0xFF30D158),
  );

  static const Color textPrimary = CupertinoDynamicColor.withBrightness(
    color: Color(0xFF000000),
    darkColor: Color(0xFFFFFFFF),
  );

  static const Color textSecondary = CupertinoDynamicColor.withBrightness(
    color: Color(0xFF8E8E93), // iOS Gray
    darkColor: Color(0xFF8E8E93),
  );

  // Typography (Inter/SF Pro style)
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

  static const TextStyle title = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.4,
    color: textPrimary,
  );

  static const TextStyle body = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.2,
    color: textPrimary,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: textSecondary,
  );
}
