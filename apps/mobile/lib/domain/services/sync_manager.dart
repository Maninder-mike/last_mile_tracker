import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:last_mile_tracker/data/database/app_database.dart';
import 'package:last_mile_tracker/presentation/providers/database_providers.dart';
import 'package:last_mile_tracker/core/utils/file_logger.dart';
import 'package:http/http.dart' as http;
import 'package:drift/drift.dart' as drift;
import 'connectivity_service.dart';

final syncManagerProvider = Provider<SyncManager>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final connectivity = ref.watch(connectivityServiceProvider);
  final manager = SyncManager(db, connectivity);
  manager.init();
  return manager;
});

class SyncManager {
  final AppDatabase _db;
  final ConnectivityService _connectivity;
  bool _isProcessing = false;

  SyncManager(this._db, this._connectivity);

  void init() {
    _connectivity.onConnectivityChanged.listen((isConnected) {
      if (isConnected) {
        processQueue();
      }
    });
  }

  Future<void> enqueue(
    String endpoint,
    Map<String, dynamic> payload, {
    String method = 'POST',
  }) async {
    await _db.syncQueueDao.enqueueOperation(
      SyncQueueCompanion.insert(
        endpoint: endpoint,
        payload: jsonEncode(payload),
        method: drift.Value(method),
      ),
    );

    if (await _connectivity.isConnected) {
      processQueue();
    }
  }

  Future<void> processQueue() async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      final operations = await _db.syncQueueDao.getPendingOperations();
      if (operations.isEmpty) {
        _isProcessing = false;
        return;
      }

      FileLogger.log('Processing sync queue with ${operations.length} items');

      for (final op in operations) {
        if (op.retryCount >= 3) {
          // Skip or flag max retries
          FileLogger.log(
            'Operation ID ${op.id} reached max retries, skipping.',
          );
          continue;
        }

        try {
          final uri = Uri.parse(op.endpoint);
          http.Response response;
          final headers = {'Content-Type': 'application/json'};

          if (op.method == 'POST') {
            response = await http.post(uri, headers: headers, body: op.payload);
          } else if (op.method == 'PUT') {
            response = await http.put(uri, headers: headers, body: op.payload);
          } else {
            response = await http.post(uri, headers: headers, body: op.payload);
          }

          if (response.statusCode >= 200 && response.statusCode < 300) {
            // Success
            await _db.syncQueueDao.removeOperation(op.id);
            FileLogger.log('Successfully synced operation ID ${op.id}');
          } else {
            // Fail
            FileLogger.log(
              'Failed to sync operation ID ${op.id}: ${response.statusCode}',
            );
            await _db.syncQueueDao.incrementRetryCount(op.id);
          }
        } catch (e) {
          FileLogger.log('Error syncing operation ID ${op.id}: $e');
          await _db.syncQueueDao.incrementRetryCount(op.id);
        }
      }
    } finally {
      _isProcessing = false;
    }
  }
}
