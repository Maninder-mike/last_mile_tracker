import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:last_mile_tracker/domain/models/shipment.dart';
import 'package:last_mile_tracker/core/utils/file_logger.dart';

class SupabaseService {
  // ignore: unused_field
  final SupabaseClient _client;

  SupabaseService(this._client);

  /// Fetch all active shipments
  Future<List<Shipment>> getShipments() async {
    // STUB: Return mock data for now
    await Future.delayed(const Duration(milliseconds: 500));
    return Shipment.mockData;

    /* IMPACT: Future Implementation
    final response = await _client
        .from('shipments')
        .select()
        .order('last_update', ascending: false);
    return response.map((json) => Shipment.fromJson(json)).toList();
    */
  }

  /// Create a new shipment
  Future<void> createShipment(Shipment shipment) async {
    FileLogger.log("Supabase: Creating shipment ${shipment.id}");
    // STUB: Simulate network request
    await Future.delayed(const Duration(seconds: 1));

    /* IMPACT: Future Implementation
    await _client
        .from('shipments')
        .insert(shipment.toJson());
    */
  }

  /// Get details for a specific shipment
  Future<Shipment?> getShipment(String id) async {
    // STUB: Find in mock data
    await Future.delayed(const Duration(milliseconds: 300));
    try {
      return Shipment.mockData.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }

    /* IMPACT: Future Implementation
    final response = await _client
        .from('shipments')
        .select()
        .eq('id', id)
        .single();
    return Shipment.fromJson(response);
    */
  }

  /// Update shipment status
  Future<void> updateShipmentStatus(String id, ShipmentStatus status) async {
    FileLogger.log("Supabase: Updating shipment $id to $status");
    // STUB: Simulate network request
    await Future.delayed(const Duration(seconds: 1));

    /* IMPACT: Future Implementation
    await _client
        .from('shipments')
        .update({'status': status.name})
        .eq('id', id);
    */
  }

  /// Subscribe to shipment updates
  Stream<List<Shipment>> streamShipments() {
    // STUB: Return single emission of mock data
    return Stream.value(Shipment.mockData);

    /* IMPACT: Future Implementation
    return _client
        .from('shipments')
        .stream(primaryKey: ['id'])
        .map((data) => data.map((json) => Shipment.fromJson(json)).toList());
    */
  }
}
