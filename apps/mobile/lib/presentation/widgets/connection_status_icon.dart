import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../providers/providers.dart';

class ConnectionStatusIcon extends ConsumerWidget {
  const ConnectionStatusIcon({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionState = ref.watch(bleConnectionStateProvider);

    return connectionState.when(
      data: (state) {
        IconData iconData = CupertinoIcons.bluetooth;
        Color color = CupertinoColors.systemRed;

        switch (state) {
          case BluetoothConnectionState.connected:
            iconData = CupertinoIcons.bluetooth;
            color = CupertinoColors.activeGreen;
            break;
          case BluetoothConnectionState.disconnected:
          default:
            iconData = CupertinoIcons.bluetooth;
            color = CupertinoColors.systemRed;
            break;
        }

        return Icon(iconData, color: color, size: 24);
      },
      loading: () => const Icon(
        CupertinoIcons.bluetooth,
        color: CupertinoColors.systemGrey,
        size: 20,
      ),
      error: (_, __) => const Icon(
        CupertinoIcons.bluetooth,
        color: CupertinoColors.systemRed,
        size: 20,
      ),
    );
  }
}
