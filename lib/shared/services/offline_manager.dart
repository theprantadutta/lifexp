import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/sync_operation.dart';

/// Manager for offline-first data operations and sync queue
class OfflineManager {
  factory OfflineManager() => _instance;
  OfflineManager._internal();
  static final OfflineManager _instance = OfflineManager._internal();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  
  bool _isOnline = true;
  final List<SyncOperation> _syncQueue = [];
  final StreamController<bool> _connectivityController = 
      StreamController<bool>.broadcast();
  
  Timer? _syncTimer;
  bool _isSyncing = false;

  /// Stream of connectivity status
  Stream<bool> get connectivityStream => _connectivityController.stream;

  /// Current online status
  bool get isOnline => _isOnline;

  /// Number of pending sync operations
  int get pendingSyncOperations => _syncQueue.length;

  /// Initialize offline manager
  Future<void> initialize() async {
    await _loadSyncQueue();
    await _checkInitialConnectivity();
    _startConnectivityMonitoring();
    _startPeriodicSync();
  }

  /// Load sync queue from persistent storage
  Future<void> _loadSyncQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queueJson = prefs.getStringList('sync_queue') ?? [];
      
      _syncQueue.clear();
      for (final operationJson in queueJson) {
        final operation = SyncOperation.fromJson(jsonDecode(operationJson));
        _syncQueue.add(operation);
      }
      
      debugPrint('OfflineManager: Loaded ${_syncQueue.length} pending operations');
    } catch (e) {
      debugPrint('OfflineManager: Failed to load sync queue: $e');
    }
  }

  /// Save sync queue to persistent storage
  Future<void> _saveSyncQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queueJson = _syncQueue
          .map((operation) => jsonEncode(operation.toJson()))
          .toList();
      
      await prefs.setStringList('sync_queue', queueJson);
    } catch (e) {
      debugPrint('OfflineManager: Failed to save sync queue: $e');
    }
  }

  /// Check initial connectivity status
  Future<void> _checkInitialConnectivity() async {
    try {
      final connectivityResults = await _connectivity.checkConnectivity();
      _updateConnectivityStatus(connectivityResults);
    } catch (e) {
      debugPrint('OfflineManager: Failed to check initial connectivity: $e');
      _isOnline = false;
    }
  }

  /// Start monitoring connectivity changes
  void _startConnectivityMonitoring() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _updateConnectivityStatus,
      onError: (error) {
        debugPrint('OfflineManager: Connectivity monitoring error: $error');
      },
    );
  }

  /// Update connectivity status
  void _updateConnectivityStatus(List<ConnectivityResult> results) {
    final wasOnline = _isOnline;
    _isOnline = results.any((result) => 
        result != ConnectivityResult.none);

    if (_isOnline != wasOnline) {
      debugPrint('OfflineManager: Connectivity changed - Online: $_isOnline');
      _connectivityController.add(_isOnline);
      
      if (_isOnline && _syncQueue.isNotEmpty) {
        _triggerSync();
      }
    }
  }

  /// Start periodic sync attempts
  void _startPeriodicSync() {
    _syncTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) {
        if (_isOnline && _syncQueue.isNotEmpty && !_isSyncing) {
          _triggerSync();
        }
      },
    );
  }

  /// Add operation to sync queue
  Future<void> queueSyncOperation(SyncOperation operation) async {
    _syncQueue.add(operation);
    await _saveSyncQueue();
    
    debugPrint('OfflineManager: Queued ${operation.type} operation for ${operation.entityType}');
    
    // Try immediate sync if online
    if (_isOnline && !_isSyncing) {
      _triggerSync();
    }
  }

  /// Trigger sync process
  void _triggerSync() {
    if (_isSyncing || _syncQueue.isEmpty || !_isOnline) return;
    
    Timer.run(_performSync);
  }

  /// Perform sync operations
  Future<void> _performSync() async {
    if (_isSyncing || _syncQueue.isEmpty || !_isOnline) return;
    
    _isSyncing = true;
    debugPrint('OfflineManager: Starting sync of ${_syncQueue.length} operations');
    
    final operationsToSync = List<SyncOperation>.from(_syncQueue);
    final successfulOperations = <SyncOperation>[];
    
    try {
      for (final operation in operationsToSync) {
        final success = await _syncOperation(operation);
        if (success) {
          successfulOperations.add(operation);
        } else {
          // Stop syncing on first failure to maintain order
          break;
        }
      }
      
      // Remove successful operations from queue
      for (final operation in successfulOperations) {
        _syncQueue.remove(operation);
      }
      
      if (successfulOperations.isNotEmpty) {
        await _saveSyncQueue();
        debugPrint('OfflineManager: Successfully synced ${successfulOperations.length} operations');
      }
      
    } catch (e) {
      debugPrint('OfflineManager: Sync failed: $e');
    } finally {
      _isSyncing = false;
    }
  }

  /// Sync individual operation
  Future<bool> _syncOperation(SyncOperation operation) async {
    try {
      switch (operation.entityType) {
        case 'task':
          return await _syncTaskOperation(operation);
        case 'avatar':
          return await _syncAvatarOperation(operation);
        case 'achievement':
          return await _syncAchievementOperation(operation);
        case 'progress':
          return await _syncProgressOperation(operation);
        default:
          debugPrint('OfflineManager: Unknown entity type: ${operation.entityType}');
          return false;
      }
    } catch (e) {
      debugPrint('OfflineManager: Failed to sync ${operation.type} for ${operation.entityType}: $e');
      return false;
    }
  }

  /// Sync task operation
  Future<bool> _syncTaskOperation(SyncOperation operation) async {
    // This would integrate with your actual sync service
    // For now, simulate sync with delay
    await Future.delayed(const Duration(milliseconds: 500));
    
    debugPrint('OfflineManager: Synced task ${operation.type}: ${operation.entityId}');
    return true;
  }

  /// Sync avatar operation
  Future<bool> _syncAvatarOperation(SyncOperation operation) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    debugPrint('OfflineManager: Synced avatar ${operation.type}: ${operation.entityId}');
    return true;
  }

  /// Sync achievement operation
  Future<bool> _syncAchievementOperation(SyncOperation operation) async {
    await Future.delayed(const Duration(milliseconds: 200));
    
    debugPrint('OfflineManager: Synced achievement ${operation.type}: ${operation.entityId}');
    return true;
  }

  /// Sync progress operation
  Future<bool> _syncProgressOperation(SyncOperation operation) async {
    await Future.delayed(const Duration(milliseconds: 400));
    
    debugPrint('OfflineManager: Synced progress ${operation.type}: ${operation.entityId}');
    return true;
  }

  /// Force sync all pending operations
  Future<void> forceSyncAll() async {
    if (!_isOnline) {
      throw Exception('Cannot sync while offline');
    }
    
    await _performSync();
  }

  /// Clear sync queue (use with caution)
  Future<void> clearSyncQueue() async {
    _syncQueue.clear();
    await _saveSyncQueue();
    debugPrint('OfflineManager: Cleared sync queue');
  }

  /// Get sync queue status
  Map<String, dynamic> getSyncStatus() {
    final statusByType = <String, int>{};
    for (final operation in _syncQueue) {
      final key = '${operation.entityType}_${operation.type}';
      statusByType[key] = (statusByType[key] ?? 0) + 1;
    }
    
    return {
      'isOnline': _isOnline,
      'isSyncing': _isSyncing,
      'totalPending': _syncQueue.length,
      'operationsByType': statusByType,
      'oldestOperation': _syncQueue.isNotEmpty 
          ? _syncQueue.first.timestamp.toIso8601String()
          : null,
    };
  }

  /// Check if entity has pending sync operations
  bool hasPendingOperations(String entityType, String entityId) => _syncQueue.any((op) => 
        op.entityType == entityType && op.entityId == entityId);

  /// Get pending operations for entity
  List<SyncOperation> getPendingOperations(String entityType, String entityId) => _syncQueue
        .where((op) => op.entityType == entityType && op.entityId == entityId)
        .toList();

  /// Remove pending operations for entity (conflict resolution)
  Future<void> removePendingOperations(String entityType, String entityId) async {
    final initialCount = _syncQueue.length;
    _syncQueue.removeWhere((op) => 
        op.entityType == entityType && op.entityId == entityId);
    
    if (_syncQueue.length != initialCount) {
      await _saveSyncQueue();
      debugPrint('OfflineManager: Removed pending operations for $entityType:$entityId');
    }
  }

  /// Dispose resources
  void dispose() {
    _connectivitySubscription?.cancel();
    _syncTimer?.cancel();
    _connectivityController.close();
  }
}