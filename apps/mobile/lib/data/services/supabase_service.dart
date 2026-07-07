import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:last_mile_tracker/domain/models/shipment.dart';
import 'package:last_mile_tracker/core/utils/file_logger.dart';

class SupabaseService {
  final SupabaseClient _client;

  SupabaseService(this._client);

  /// Fetch all active shipments
  Future<List<Shipment>> getShipments() async {
    try {
      final List<dynamic> response = await _client
          .from('shipments')
          .select()
          .order('lastUpdate', ascending: false);
      return response
          .map((json) => Shipment.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      FileLogger.log("Supabase: Failed to fetch shipments: $e");
      return [];
    }
  }

  /// Create a new shipment
  Future<void> createShipment(Shipment shipment) async {
    FileLogger.log("Supabase: Creating shipment ${shipment.id}");
    try {
      await _client.from('shipments').insert(shipment.toJson());
    } catch (e) {
      FileLogger.log("Supabase: Failed to create shipment: $e");
      rethrow;
    }
  }

  /// Get details for a specific shipment
  Future<Shipment?> getShipment(String id) async {
    try {
      final response = await _client
          .from('shipments')
          .select()
          .eq('id', id)
          .maybeSingle();
      if (response == null) return null;
      return Shipment.fromJson(response);
    } catch (e) {
      FileLogger.log("Supabase: Failed to fetch shipment $id: $e");
      return null;
    }
  }

  /// Update shipment status
  Future<void> updateShipmentStatus(String id, ShipmentStatus status) async {
    FileLogger.log("Supabase: Updating shipment $id to $status");
    try {
      await _client
          .from('shipments')
          .update({'status': status.name})
          .eq('id', id);
    } catch (e) {
      FileLogger.log("Supabase: Failed to update shipment status: $e");
      rethrow;
    }
  }

  /// Subscribe to shipment updates
  Stream<List<Shipment>> streamShipments() {
    try {
      return _client
          .from('shipments')
          .stream(primaryKey: ['id'])
          .map((data) => data.map((json) => Shipment.fromJson(json)).toList());
    } catch (e) {
      FileLogger.log("Supabase: Error in shipments stream: $e");
      return Stream.value([]);
    }
  }
}
