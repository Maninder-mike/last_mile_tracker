import 'package:flutter/cupertino.dart';
import 'package:last_mile_tracker/core/theme/app_theme.dart';

class ErrorStateView extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;
  final VoidCallback onResetToDemo;

  const ErrorStateView({
    super.key,
    required this.error,
    required this.onRetry,
    required this.onResetToDemo,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              CupertinoIcons.wifi_exclamationmark,
              color: AppTheme.critical,
              size: 64,
            ),
            const SizedBox(height: 20),
            Text(
              'Connection Error',
              style: AppTheme.heading2.copyWith(
                color: AppTheme.resolvedTextPrimary(context),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Failed to reach the database host. Please verify your internet connection or check your database settings.\n\nError: $error',
              style: AppTheme.caption.copyWith(
                color: AppTheme.resolvedTextSecondary(context),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CupertinoButton(
                  color: CupertinoTheme.of(context).primaryColor,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  borderRadius: BorderRadius.circular(20),
                  onPressed: onRetry,
                  child: const Text('Retry'),
                ),
                const SizedBox(width: 16),
                CupertinoButton(
                  color: CupertinoColors.systemGrey.withValues(alpha: 0.2),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  borderRadius: BorderRadius.circular(20),
                  onPressed: onResetToDemo,
                  child: Text(
                    'Use Demo Mode',
                    style: TextStyle(
                      color: AppTheme.resolvedTextPrimary(context),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
