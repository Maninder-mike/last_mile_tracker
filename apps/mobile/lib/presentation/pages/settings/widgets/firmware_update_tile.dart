import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/constants/ble_constants.dart';
import '../../../../data/services/ota_service.dart';
import '../../../providers/providers.dart';

class FirmwareUpdateTile extends ConsumerWidget {
  const FirmwareUpdateTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final otaService = ref.watch(otaServiceProvider);

    return StreamBuilder<OtaState>(
      stream: otaService.stateStream,
      initialData: otaService.currentState,
      builder: (context, snapshot) {
        final state = snapshot.data!;

        // Show progress bar if active
        if (state.status == OtaStatus.downloading ||
            state.status == OtaStatus.uploading ||
            state.status == OtaStatus.applying) {
          return _buildProgressTile(context, state);
        }

        // Show update available
        if (state.status == OtaStatus.available) {
          return _buildUpdateAvailableTile(context, ref, state);
        }

        // Show standard tile
        return _buildStandardTile(context, ref, state);
      },
    );
  }

  Widget _buildStandardTile(
    BuildContext context,
    WidgetRef ref,
    OtaState state,
  ) {
    final theme = CupertinoTheme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isChecking = state.status == OtaStatus.checking;

    return CupertinoListTile(
      title: Text(
        'Firmware Update',
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: isDark ? CupertinoColors.white : CupertinoColors.label,
        ),
      ),
      subtitle: Text(
        state.status == OtaStatus.upToDate
            ? 'Up to date (v${BleConstants.currentFirmwareVersion})'
            : state.status == OtaStatus.error
            ? 'Check failed'
            : 'Current v${BleConstants.currentFirmwareVersion}',
        style: TextStyle(
          color: state.status == OtaStatus.error
              ? CupertinoColors.systemRed
              : isDark
              ? CupertinoColors.systemGrey
              : CupertinoColors.secondaryLabel,
        ),
      ),
      leading: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: CupertinoColors.systemOrange.withValues(
            alpha: isDark ? 0.2 : 0.15,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          CupertinoIcons.arrow_2_circlepath,
          color: CupertinoColors.systemOrange,
          size: 20,
        ),
      ),
      trailing: isChecking
          ? const CupertinoActivityIndicator(radius: 8)
          : const Icon(
              CupertinoIcons.chevron_right,
              size: 16,
              color: CupertinoColors.systemGrey2,
            ),
      onTap: isChecking
          ? null
          : () {
              ref.read(otaServiceProvider).checkForUpdate();
            },
    );
  }

  Widget _buildUpdateAvailableTile(
    BuildContext context,
    WidgetRef ref,
    OtaState state,
  ) {
    return Container(
      color: CupertinoColors.activeBlue.withValues(alpha: 0.1),
      child: CupertinoListTile(
        backgroundColor: CupertinoColors.transparent,
        title: const Text(
          'Update Available',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: CupertinoColors.activeBlue,
          ),
        ),
        subtitle: Text(
          'Version ${state.release?.tagName ?? 'New'} ready to install',
          style: const TextStyle(color: CupertinoColors.activeBlue),
        ),
        leading: const Icon(
          CupertinoIcons.cloud_download_fill,
          color: CupertinoColors.activeBlue,
          size: 28,
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Text('Update'),
          onPressed: () {
            _showUpdateDialog(context, ref, state);
          },
        ),
      ),
    );
  }

  Widget _buildProgressTile(BuildContext context, OtaState state) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                state.message,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${(state.progress * 100).toInt()}%',
                style: const TextStyle(
                  fontSize: 14,
                  color: CupertinoColors.systemGrey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: state.progress,
              backgroundColor: CupertinoColors.systemGrey5,
              valueColor: const AlwaysStoppedAnimation(
                CupertinoColors.activeBlue,
              ),
              minHeight: 6,
            ),
          ),
        ],
      ).animate().fadeIn(),
    );
  }

  void _showUpdateDialog(BuildContext context, WidgetRef ref, OtaState state) {
    final release = state.release;
    if (release == null) return;

    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text('Update to ${release.tagName}?'),
        content: Column(
          children: [
            const SizedBox(height: 8),
            Text('Size: ${(release.fileSize / 1024).toStringAsFixed(1)} KB'),
            const SizedBox(height: 8),
            const Text(
              'Keep the phone near the device. The tracker will restart after the update.',
              style: TextStyle(fontSize: 13),
            ),
            if (release.releaseNotes.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey6,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  release.releaseNotes,
                  style: const TextStyle(fontSize: 12),
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: false,
            onPressed: () {
              Navigator.pop(ctx);
              final bleService = ref.read(bleServiceProvider);
              ref.read(otaServiceProvider).performUpdate(bleService);
            },
            child: const Text('Install Now'),
          ),
        ],
      ),
    );
  }
}
