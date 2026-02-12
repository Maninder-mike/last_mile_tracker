import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'network_provider.g.dart';

@Riverpod(keepAlive: true)
Stream<List<ConnectivityResult>> connectivity(Ref ref) {
  return Connectivity().onConnectivityChanged;
}

@riverpod
bool isOnline(Ref ref) {
  final connectivityAsync = ref.watch(connectivityProvider);
  return connectivityAsync.maybeWhen(
    data: (results) => results.any((r) => r != ConnectivityResult.none),
    orElse: () => true, // Assume online if state is loading or error initially
  );
}
