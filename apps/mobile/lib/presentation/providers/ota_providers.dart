import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/services/ota_service.dart';
import 'service_providers.dart';

part 'ota_providers.g.dart';

@riverpod
Stream<OtaState> otaState(Ref ref) {
  final service = ref.watch(otaServiceProvider);
  return service.stateStream;
}
