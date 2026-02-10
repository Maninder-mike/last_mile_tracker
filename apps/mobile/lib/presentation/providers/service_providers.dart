import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:last_mile_tracker/data/services/sync_manager.dart';
import 'package:last_mile_tracker/data/services/ota_service.dart';
import 'package:last_mile_tracker/presentation/providers/database_providers.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

part 'service_providers.g.dart';

// Secure Storage
@Riverpod(keepAlive: true)
FlutterSecureStorage secureStorage(Ref ref) {
  return const FlutterSecureStorage();
}

// Sync Manager
@Riverpod(keepAlive: true)
SyncManager syncManager(Ref ref) {
  final dao = ref.watch(sensorDaoProvider);
  return SyncManager(dao);
}

// OTA Service
@Riverpod(keepAlive: true)
OtaService otaService(Ref ref) {
  final service = OtaService();
  ref.onDispose(() => service.dispose());
  return service;
}

@Riverpod(keepAlive: true)
Future<PackageInfo> packageInfo(Ref ref) {
  return PackageInfo.fromPlatform();
}
