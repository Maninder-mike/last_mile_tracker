import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:last_mile_tracker/presentation/providers/theme_provider.dart';

class UserGeneratedDynamicColor extends CupertinoDynamicColor {
  final Color Function(BuildContext context, bool isDark) resolver;

  const UserGeneratedDynamicColor(
    this.resolver, {
    Color fallbackLight = const Color(0xFFF3F4F6),
    Color fallbackDark = const Color(0xFF1C1C1E),
  }) : super.withBrightness(
          color: fallbackLight,
          darkColor: fallbackDark,
        );

  @override
  CupertinoDynamicColor resolveFrom(BuildContext context) {
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;
    final resolved = resolver(context, isDark);
    return CupertinoDynamicColor.withBrightness(
      color: resolved,
      darkColor: resolved,
    );
  }
}

class DynamicPalette {
  final Color primary;
  final Color background;
  final Color surface;
  final Color surfaceElevated;
  final Color surfaceBorder;

  DynamicPalette({
    required this.primary,
    required this.background,
    required this.surface,
    required this.surfaceElevated,
    required this.surfaceBorder,
  });

  factory DynamicPalette.generate(Color seedColor, bool isDark) {
    final hsl = HSLColor.fromColor(seedColor);
    
    if (isDark) {
      // Dark Mode Palette
      final primaryColor = hsl.withLightness(math.max(hsl.lightness, 0.65)).toColor();
      
      final bgColor = hsl.withSaturation(math.min(hsl.saturation * 0.12, 0.08))
                         .withLightness(0.06)
                         .toColor();
                         
      final surfaceColor = hsl.withSaturation(math.min(hsl.saturation * 0.18, 0.12))
                              .withLightness(0.12)
                              .toColor();
                              
      final surfaceElev = hsl.withSaturation(math.min(hsl.saturation * 0.22, 0.15))
                             .withLightness(0.16)
                             .toColor();
                             
      final border = primaryColor.withValues(alpha: 0.15);
      
      return DynamicPalette(
        primary: primaryColor,
        background: bgColor,
        surface: surfaceColor,
        surfaceElevated: surfaceElev,
        surfaceBorder: border,
      );
    } else {
      // Light Mode Palette
      final primaryColor = hsl.withLightness(math.min(hsl.lightness, 0.45)).toColor();
      
      final bgColor = hsl.withSaturation(math.min(hsl.saturation * 0.08, 0.05))
                         .withLightness(0.97)
                         .toColor();
                         
      final surfaceColor = hsl.withSaturation(math.min(hsl.saturation * 0.12, 0.08))
                              .withLightness(0.93)
                              .toColor();
                              
      final surfaceElev = CupertinoColors.white;
      
      final border = primaryColor.withValues(alpha: 0.12);
      
      return DynamicPalette(
        primary: primaryColor,
        background: bgColor,
        surface: surfaceColor,
        surfaceElevated: surfaceElev,
        surfaceBorder: border,
      );
    }
  }
}

class AppTheme {
  const AppTheme._();

  static DynamicPalette _palette(BuildContext context) {
    final primaryColor = CupertinoTheme.of(context).primaryColor;
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;
    return DynamicPalette.generate(primaryColor, isDark);
  }

  // Primary Colors - Dynamic seed-based color scheme
  static Color get primary => UserGeneratedDynamicColor((context, isDark) {
        return CupertinoTheme.of(context).primaryColor;
      });

  static Color get background => UserGeneratedDynamicColor((context, isDark) {
        return _palette(context).background;
      });

  static Color get surface => UserGeneratedDynamicColor((context, isDark) {
        return _palette(context).surface;
      });

  static Color get surfaceElevated => UserGeneratedDynamicColor((context, isDark) {
        return _palette(context).surfaceElevated;
      });

  static Color get surfaceBorder => UserGeneratedDynamicColor((context, isDark) {
        return _palette(context).surfaceBorder;
      });

  // Dynamic Gradient helpers
  static Gradient primaryGradient(BuildContext context) {
    final primaryColor = CupertinoTheme.of(context).primaryColor;
    final hsl = HSLColor.fromColor(primaryColor);
    final secondaryColor = hsl.withHue((hsl.hue + 25) % 360).toColor();
    return LinearGradient(
      colors: [primaryColor, secondaryColor],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  static Gradient primaryGradientDark(BuildContext context) {
    final primaryColor = CupertinoTheme.of(context).primaryColor;
    final hsl = HSLColor.fromColor(primaryColor);
    final secondaryColor = hsl.withHue((hsl.hue + 35) % 360).toColor();
    return LinearGradient(
      colors: [primaryColor, secondaryColor],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

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
  static Color get surfaceGlass => UserGeneratedDynamicColor((context, isDark) {
        return _palette(context).surface.withValues(alpha: 0.8);
      });

  static Color get surfaceGlassStrong => UserGeneratedDynamicColor((context, isDark) {
        return _palette(context).surface.withValues(alpha: 0.9);
      });

  static Color get surfaceGlassWeak => UserGeneratedDynamicColor((context, isDark) {
        return _palette(context).surface.withValues(alpha: 0.45);
      });

  // Shadow Tokens
  static const List<BoxShadow> softShadow = [
    BoxShadow(color: Color(0x1A000000), offset: Offset(0, 4), blurRadius: 12),
  ];

  static List<BoxShadow> glowOf(BuildContext context) {
    final primaryColor = CupertinoTheme.of(context).primaryColor;
    return [
      BoxShadow(
        color: primaryColor.withValues(alpha: 0.3),
        offset: const Offset(0, 0),
        blurRadius: 16,
        spreadRadius: 2,
      ),
    ];
  }

  // Animation & Elevation Tokens
  static const Duration pageTransitionDuration = Duration(milliseconds: 300);
  static const double cardElevation = 8.0;

  // Text Colors
  static const Color textPrimary = CupertinoDynamicColor.withBrightness(
    color: Color(0xFF111827), // Gray 900
    darkColor: Color(0xFFF9FAFB), // Gray 50
  );

  static const Color textSecondary = CupertinoDynamicColor.withBrightness(
    color: Color(0xFF6B7280), // Gray 500
    darkColor: Color(0xFF9CA3AF), // Gray 400
  );

  // Helper methods to resolve dynamic colors against BuildContext
  static Color resolvedTextPrimary(BuildContext context) {
    return CupertinoDynamicColor.resolve(textPrimary, context);
  }

  static Color resolvedTextSecondary(BuildContext context) {
    return CupertinoDynamicColor.resolve(textSecondary, context);
  }

  // --- Material 3 Typography Specifications ---
  
  // Display Styles (Outfit)
  static TextStyle get displayLarge => GoogleFonts.outfit(
        fontSize: 57,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.25,
        height: 64 / 57,
        color: textPrimary,
      );

  static TextStyle get displayMedium => GoogleFonts.outfit(
        fontSize: 45,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.0,
        height: 52 / 45,
        color: textPrimary,
      );

  static TextStyle get displaySmall => GoogleFonts.outfit(
        fontSize: 36,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.0,
        height: 44 / 36,
        color: textPrimary,
      );

  // Headline Styles (Outfit)
  static TextStyle get headlineLarge => GoogleFonts.outfit(
        fontSize: 32,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.0,
        height: 40 / 32,
        color: textPrimary,
      );

  static TextStyle get headlineMedium => GoogleFonts.outfit(
        fontSize: 28,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.0,
        height: 36 / 28,
        color: textPrimary,
      );

  static TextStyle get headlineSmall => GoogleFonts.outfit(
        fontSize: 24,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.0,
        height: 32 / 24,
        color: textPrimary,
      );

  // Title Styles (Outfit)
  static TextStyle get titleLarge => GoogleFonts.outfit(
        fontSize: 22,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.0,
        height: 28 / 22,
        color: textPrimary,
      );

  static TextStyle get titleMedium => GoogleFonts.outfit(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.15,
        height: 24 / 16,
        color: textPrimary,
      );

  static TextStyle get titleSmall => GoogleFonts.outfit(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        height: 20 / 14,
        color: textPrimary,
      );

  // Label Styles (Inter)
  static TextStyle get labelLarge => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        height: 20 / 14,
        color: textPrimary,
      );

  static TextStyle get labelMedium => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        height: 16 / 12,
        color: textSecondary,
      );

  static TextStyle get labelSmall => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        height: 16 / 11,
        color: textSecondary,
      );

  // Body Styles (Inter)
  static TextStyle get bodyLarge => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
        height: 24 / 16,
        color: textPrimary,
      );

  static TextStyle get bodyMedium => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
        height: 20 / 14,
        color: textPrimary,
      );

  static TextStyle get bodySmall => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
        height: 16 / 12,
        color: textPrimary,
      );

  // --- Legacy Mappings for Backward Compatibility ---
  static TextStyle get title => titleMedium.copyWith(fontWeight: FontWeight.w600, fontSize: 17, letterSpacing: -0.4);
  static TextStyle get heading1 => headlineLarge.copyWith(fontWeight: FontWeight.w700, fontSize: 34, letterSpacing: -1.0);
  static TextStyle get heading2 => headlineSmall.copyWith(fontWeight: FontWeight.w700, fontSize: 22, letterSpacing: -0.6);
  static TextStyle get heading3 => titleLarge.copyWith(fontWeight: FontWeight.w600, fontSize: 20, letterSpacing: -0.5);
  static TextStyle get body => bodyLarge.copyWith(fontSize: 17, letterSpacing: -0.4);
  static TextStyle get caption => bodySmall.copyWith(color: textSecondary, fontSize: 13, letterSpacing: -0.4);
  static TextStyle get label => labelSmall.copyWith(fontWeight: FontWeight.w600);

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
    
    // Generate tonal palette from the themeState's accentColor (seed color)
    final palette = DynamicPalette.generate(themeState.accentColor, isDark);

    return CupertinoThemeData(
      brightness: brightness,
      primaryColor: palette.primary,
      scaffoldBackgroundColor: palette.background,
      barBackgroundColor: palette.surface.withValues(alpha: 0.85),
      textTheme: CupertinoTextThemeData(
        navTitleTextStyle: GoogleFonts.outfit(
          fontWeight: FontWeight.w600,
          fontSize: 17,
          color: isDark ? const Color(0xFFF5F5F7) : const Color(0xFF1D1D1F),
        ),
        textStyle: GoogleFonts.inter(
          color: isDark ? const Color(0xFFF5F5F7) : const Color(0xFF1D1D1F),
        ),
      ),
    );
  }
}
