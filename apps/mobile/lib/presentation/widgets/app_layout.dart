import 'package:flutter/cupertino.dart';
import 'package:last_mile_tracker/core/theme/app_theme.dart';

/// Standard padding utilities for consistent layout across the app
class AppPadding {
  AppPadding._();

  /// Standard horizontal padding for page content
  static const EdgeInsets horizontal = EdgeInsets.symmetric(
    horizontal: AppTheme.s16,
  );

  /// Standard vertical padding for page content
  static const EdgeInsets vertical = EdgeInsets.symmetric(
    vertical: AppTheme.s16,
  );

  /// Standard padding for page content (all sides)
  static const EdgeInsets all = EdgeInsets.all(AppTheme.s16);

  /// Standard padding for list items
  static const EdgeInsets listItem = EdgeInsets.symmetric(
    horizontal: AppTheme.s16,
    vertical: AppTheme.s8,
  );

  /// Standard padding for cards
  static const EdgeInsets card = EdgeInsets.all(AppTheme.s16);

  /// Standard padding for search bars
  static const EdgeInsets searchBar = EdgeInsets.symmetric(
    horizontal: AppTheme.s16,
    vertical: AppTheme.s8,
  );

  /// Standard padding for sections
  static const EdgeInsets section = EdgeInsets.symmetric(
    horizontal: AppTheme.s16,
    vertical: AppTheme.s12,
  );

  /// Safe area padding (top) for content below headers
  static EdgeInsets safeTop(BuildContext context) {
    return EdgeInsets.only(
      top: MediaQuery.of(context).padding.top + 60,
    );
  }

  /// Safe area padding (bottom) for content above bottom nav
  static const EdgeInsets safeBottom = EdgeInsets.only(bottom: 100);
}

/// Standard gap utilities for consistent spacing between elements
class AppGaps {
  AppGaps._();

  /// Small gap (4px)
  static const SizedBox small = SizedBox(height: AppTheme.s4);

  /// Medium gap (8px)
  static const SizedBox medium = SizedBox(height: AppTheme.s8);

  /// Standard gap (12px)
  static const SizedBox standard = SizedBox(height: AppTheme.s12);

  /// Large gap (16px)
  static const SizedBox large = SizedBox(height: AppTheme.s16);

  /// Extra large gap (24px)
  static const SizedBox xLarge = SizedBox(height: AppTheme.s24);

  /// Extra extra large gap (32px)
  static const SizedBox xxLarge = SizedBox(height: AppTheme.s32);

  /// Horizontal small gap
  static const SizedBox horizontalSmall = SizedBox(width: AppTheme.s4);

  /// Horizontal medium gap
  static const SizedBox horizontalMedium = SizedBox(width: AppTheme.s8);

  /// Horizontal standard gap
  static const SizedBox horizontalStandard = SizedBox(width: AppTheme.s12);

  /// Horizontal large gap
  static const SizedBox horizontalLarge = SizedBox(width: AppTheme.s16);
}
