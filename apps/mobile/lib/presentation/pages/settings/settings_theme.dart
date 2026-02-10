import 'package:flutter/cupertino.dart';

/// Design tokens and shared constants for the Settings pages to ensure
/// visual consistency and eliminate hardcoded values.
abstract final class SettingsTheme {
  // Spacing
  static const sectionMargin = EdgeInsets.fromLTRB(16, 8, 16, 8);
  static const sectionMarginBottom = EdgeInsets.fromLTRB(16, 8, 16, 24);
  static const tileLeadingSize = 32.0;
  static const tileIconSize = 20.0;
  static const heroPadding = EdgeInsets.all(20.0);
  static const heroMargin = EdgeInsets.all(16.0);

  // Colors
  static const subtitleColor = CupertinoColors.systemGrey;
  static const chevronColor = CupertinoColors.systemGrey2;
  static const dividerColorDark = Color(
    0x4D8E8E93,
  ); // systemGrey with 0.3 alpha
  static const dividerColorLight = CupertinoColors.systemGrey5;

  // Glassmorphism
  static const glassOpacityDark = 0.05;
  static const glassOpacityLight = 0.08;
  static const glassBlur = 20.0;
  static const glassBorderOpacity = 0.1;

  // Typography
  static const heroTitleSize = 18.0;
  static const heroValueSize = 16.0;
  static const heroLabelSize = 12.0;
  static const versionNumberSize = 13.0;

  // Animation
  static const fadeDuration = Duration(milliseconds: 400);
}
