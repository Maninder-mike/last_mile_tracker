import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:last_mile_tracker/l10n/app_localizations.dart';
import 'package:last_mile_tracker/core/theme/app_theme.dart';
import 'package:last_mile_tracker/presentation/providers/service_providers.dart';

class MaintenancePage extends ConsumerWidget {
  const MaintenancePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;

    return CupertinoPageScaffold(
      backgroundColor: isDark
          ? CupertinoColors.black
          : CupertinoColors.systemBackground,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Icon(
                CupertinoIcons.wrench,
                size: 80,
                color: isDark
                    ? CupertinoColors.systemGrey3
                    : CupertinoColors.systemGrey2,
              ),
              const SizedBox(height: 24),
              Text(
                l10n.maintenanceTitle,
                style: AppTheme.heading2.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? CupertinoColors.white : CupertinoColors.black,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                l10n.maintenanceMessage,
                style: AppTheme.body.copyWith(
                  color: isDark
                      ? CupertinoColors.systemGrey4
                      : CupertinoColors.systemGrey,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              CupertinoButton.filled(
                child: Text(l10n.retryButton),
                onPressed: () async {
                  // Fetch remote config manually
                  await ref.read(configServiceProvider).fetchAndActivate();
                  // Re-invalidate the provider state
                  ref.invalidate(maintenanceModeProvider);
                },
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}
