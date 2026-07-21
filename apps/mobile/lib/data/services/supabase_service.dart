import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:last_mile_tracker/domain/models/shipment.dart';
import 'package:last_mile_tracker/core/utils/file_logger.dart';
import 'package:last_mile_tracker/presentation/providers/database_config_provider.dart';
import 'package:last_mile_tracker/presentation/providers/mock_shipments_provider.dart';

class SupabaseService {
  final SupabaseClient? _client;
  final Ref _ref;

  SupabaseService(this._client, this._ref);

  /// Fetch all active shipments
  Future<List<Shipment>> getShipments() async {
    final isDemo = _ref.read(databaseConfigProvider).isDemoMode;
    if (isDemo) {
      return _ref.read(mockShipmentsProvider);
    }

    if (_client == null) return [];

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
    final isDemo = _ref.read(databaseConfigProvider).isDemoMode;
    if (isDemo) {
      _ref.read(mockShipmentsProvider.notifier).addShipment(shipment);
      return;
    }

    if (_client == null) {
      throw Exception("Supabase client is not initialized (Demo Mode is off, but credentials are missing).");
    }

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
    final isDemo = _ref.read(databaseConfigProvider).isDemoMode;
    if (isDemo) {
      final list = _ref.read(mockShipmentsProvider);
      final match = list.where((s) => s.id == id);
      return match.isNotEmpty ? match.first : null;
    }

    if (_client == null) return null;

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
    final isDemo = _ref.read(databaseConfigProvider).isDemoMode;
    if (isDemo) {
      _ref.read(mockShipmentsProvider.notifier).updateStatus(id, status);
      return;
    }

    if (_client == null) {
      throw Exception("Supabase client is not initialized.");
    }

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
    final isDemo = _ref.read(databaseConfigProvider).isDemoMode;
    if (isDemo) {
      late ProviderSubscription<List<Shipment>> providerSubscription;
      late StreamController<List<Shipment>> controller;

      controller = StreamController<List<Shipment>>(
        onListen: () {
          controller.add(_ref.read(mockShipmentsProvider));
          providerSubscription = _ref.listen<List<Shipment>>(
            mockShipmentsProvider,
            (previous, next) {
              if (!controller.isClosed) {
                controller.add(next);
              }
            },
            fireImmediately: false,
          );
        },
        onCancel: () {
          providerSubscription.close();
          controller.close();
        },
      );

      return controller.stream;
    }

    if (_client == null) {
      return Stream.value([]);
    }

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
