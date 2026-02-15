import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:last_mile_tracker/presentation/providers/theme_provider.dart';

class AppTheme {
  const AppTheme._();

  // Primary Colors - Electric Indigo / Neon Blue
  static const Color primary = CupertinoDynamicColor.withBrightness(
    color: Color(0xFF4F46E5), // Electric Indigo
    darkColor: Color(0xFF6366F1), // Lighter Indigo for Dark Mode
  );

  static const Color background = CupertinoDynamicColor.withBrightness(
    color: Color(0xFFF3F4F6), // Cool Gray 100
    darkColor: Color(0xFF000000), // Pure Black for OLED
  );

  static const Color surface = CupertinoDynamicColor.withBrightness(
    color: Color(0xFFFFFFFF),
    darkColor: Color(0xFF1C1C1E),
  );

  // Gradient Tokens
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
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
  static const double radiusXLarge = 32.0;

  // Icon Size Tokens
  static const double iconSizeSmall = 16.0;
  static const double iconSizeMedium = 20.0;
  static const double iconSizeLarge = 24.0;
  static const double iconSizeXLarge = 32.0;

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

  static const Color surfaceGlassStrong = CupertinoDynamicColor.withBrightness(
    color: Color(0xE6FFFFFF), // White ~90%
    darkColor: Color(0xE61C1C1E), // Dark Gray ~90%
  );

  static const Color surfaceGlassWeak = CupertinoDynamicColor.withBrightness(
    color: Color(0x66FFFFFF), // White ~40%
    darkColor: Color(0x661C1C1E), // Dark Gray ~40%
  );

  // Shadow Tokens
  static const List<BoxShadow> softShadow = [
    BoxShadow(color: Color(0x1A000000), offset: Offset(0, 4), blurRadius: 12),
  ];

  static const List<BoxShadow> glow = [
    BoxShadow(
      color: Color(0x4D4F46E5), // Primary with opacity
      offset: Offset(0, 0),
      blurRadius: 16,
      spreadRadius: 2,
    ),
  ];

  // Text Colors
  static const Color textPrimary = CupertinoDynamicColor.withBrightness(
    color: Color(0xFF111827), // Gray 900
    darkColor: Color(0xFFF9FAFB), // Gray 50
  );

  static const Color textSecondary = CupertinoDynamicColor.withBrightness(
    color: Color(0xFF6B7280), // Gray 500
    darkColor: Color(0xFF9CA3AF), // Gray 400
  );

  // Text Styles - Using Google Fonts
  static TextStyle get title => GoogleFonts.outfit(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.4,
    color: textPrimary,
  );

  static TextStyle get heading1 => GoogleFonts.outfit(
    fontSize: 34,
    fontWeight: FontWeight.w700,
    letterSpacing: -1.0,
    color: textPrimary,
  );

  static TextStyle get heading2 => GoogleFonts.outfit(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.6,
    color: textPrimary,
  );

  static TextStyle get heading3 => GoogleFonts.outfit(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.5,
    color: textPrimary,
  );

  static TextStyle get body => GoogleFonts.inter(
    fontSize: 17,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.4,
    color: textPrimary,
  );

  static TextStyle get bodySmall => GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: textPrimary,
  );

  static TextStyle get caption => GoogleFonts.inter(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: textSecondary,
  );

  static TextStyle get label => GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
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
          ? const Color(0xFF000000)
          : const Color(0xFFF3F4F6),
      barBackgroundColor: isDark
          ? const Color(0xCC1C1C1E)
          : const Color(0xCCFFFFFF),
      textTheme: CupertinoTextThemeData(
        navTitleTextStyle: GoogleFonts.outfit(
          fontWeight: FontWeight.w600,
          fontSize: 17,
          color: isDark ? CupertinoColors.white : CupertinoColors.label,
        ),
        textStyle: GoogleFonts.inter(
          color: isDark ? CupertinoColors.white : CupertinoColors.label,
        ),
      ),
    );
  }
}
