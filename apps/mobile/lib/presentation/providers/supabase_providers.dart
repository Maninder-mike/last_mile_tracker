import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:last_mile_tracker/domain/models/shipment.dart';
import 'package:last_mile_tracker/data/services/supabase_service.dart';

part 'supabase_providers.g.dart';

@Riverpod(keepAlive: true)
SupabaseClient supabaseClient(Ref ref) {
  return Supabase.instance.client;
}

@Riverpod(keepAlive: true)
SupabaseService supabaseService(Ref ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseService(client);
}

@riverpod
Stream<List<Shipment>> shipments(Ref ref) {
  return ref.watch(supabaseServiceProvider).streamShipments();
}
