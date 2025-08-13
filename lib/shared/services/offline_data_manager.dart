import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages offline data operations and sync queue
class OfflineDataManager {

  OfflineDataManager(this._prefs, this._connectivity) {
    _initializeConnectivity();
    _loadSyncQueue();
    _startPeriodicSync();
  }
  static const String _syncQueueKey = 'sync_queue';
  static const String _lastSyncKey = 'last_sync_timestamp';
  
  final SharedPreferences _prefs;
  final Connectivity _connectivity;
  final StreamController<bool> _connectionController = StreamController<bool>.broadcast();
  final StreamController<List<SyncOperation>> _syncQueueController = StreamController<List<SyncOperation>>.broadcast();
  
  bool _isOnline = false;
  List<SyncOperation> _syncQueue = [];
  Timer? _syncTimer;

  /// Stream of connection status changes
  Stream<bool> get connectionStream => _connectionController.stream;
  
  /// Stream of sync queue changes
  Stream<List<SyncOperation>> get syncQueueStream => _syncQueueController.stream;
  
  /// Current connection status
  bool get isOnline => _isOnline;
  
  /// Current sync queue
  List<SyncOperation> get syncQueue => List.unmodifiable(_syncQueue);
  
  /// Number of pending sync operations
  int get pendingSyncCount => _syncQueue.length;

  /// Initialize connectivity monitoring
  Future<void> _initializeConnectivity() async {
    // Check initial connectivity
    final connectivityResult = await _connectivity.checkConnectivity();
    _isOnline = connectivityResult != ConnectivityResult.none;
    _connectionController.add(_isOnline);

    // Listen for connectivity changes
    _connectivity.onConnectivityChanged.listen((ConnectivityResult result) {
      final wasOnline = _isOnline;
      _isOnline = result != ConnectivityResult.none;
      
      if (_isOnline != wasOnline) {
        _connectionController.add(_isOnline);
        
        // If we just came online, trigger sync
        if (_isOnline && _syncQueue.isNotEmpty) {
          _triggerSync();
        }
      }
    });
  }

  /// Load sync queue from persistent storage
  Future<void> _loadSyncQueue() async {
    try {
      final queueJson = _prefs.getString(_syncQueueKey);
      if (queueJson != null) {
        final List<dynamic> queueList = jsonDecode(queueJson);
        _syncQueue = queueList
            .map((item) => SyncOperation.fromJson(item))
            .toList();
        _syncQueueController.add(_syncQueue);
      }
    } catch (e) {
      // If loading fails, start with empty queue
      _syncQueue = [];
    }
  }

  /// Save sync queue to persistent storage
  Future<void> _saveSyncQueue() async {
    try {
      final queueJson = jsonEncode(_syncQueue.map((op) => op.toJson()).toList());
      await _prefs.setString(_syncQueueKey, queueJson);
      _syncQueueController.add(_syncQueue);
    } catch (e) {
      // Handle save error gracefully
      print('Failed to save sync queue: $e');
    }
  }

  /// Add operation to sync queue
  Future<void> queueSyncOperation(SyncOperation operation) async {
    // Check if similar operation already exists and merge if possible
    final existingIndex = _syncQueue.indexWhere((op) => 
        op.entityType == operation.entityType && 
        op.entityId == operation.entityId);
    
    if (existingIndex != -1) {
      // Update existing operation with latest data
      _syncQueue[existingIndex] = operation.copyWith(
        timestamp: DateTime.now(),
        retryCount: 0, // Reset retry count for updated operation
      );
    } else {
      _syncQueue.add(operation);
    }
    
    await _saveSyncQueue();
    
    // If online, trigger immediate sync
    if (_isOnline) {
      _triggerSync();
    }
  }

  /// Remove operation from sync queue
  Future<void> _removeSyncOperation(String operationId) async {
    _syncQueue.removeWhere((op) => op.id == operationId);
    await _saveSyncQueue();
  }

  /// Start periodic sync attempts
  void _startPeriodicSync() {
    _syncTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      if (_isOnline && _syncQueue.isNotEmpty) {
        _triggerSync();
      }
    });
  }

  /// Trigger sync process
  Future<void> _triggerSync() async {
    if (!_isOnline || _syncQueue.isEmpty) return;

    final operationsToSync = List<SyncOperation>.from(_syncQueue);
    
    for (final operation in operationsToSync) {
      try {
        await _processSyncOperation(operation);
        await _removeSyncOperation(operation.id);
      } catch (e) {
        // Increment retry count
        final updatedOperation = operation.copyWith(
          retryCount: operation.retryCount + 1,
          lastError: e.toString(),
        );
        
        // Remove if max retries exceeded
        if (updatedOperation.retryCount >= 3) {
          await _removeSyncOperation(operation.id);
          print('Max retries exceeded for operation ${operation.id}: $e');
        } else {
          // Update operation with new retry count
          final index = _syncQueue.indexWhere((op) => op.id == operation.id);
          if (index != -1) {
            _syncQueue[index] = updatedOperation;
            await _saveSyncQueue();
          }
        }
      }
    }
    
    // Update last sync timestamp
    await _prefs.setInt(_lastSyncKey, DateTime.now().millisecondsSinceEpoch);
  }

  /// Process individual sync operation
  Future<void> _processSyncOperation(SyncOperation operation) async {
    // This would be implemented by specific sync handlers
    // For now, we'll simulate the operation
    switch (operation.operationType) {
      case SyncOperationType.create:
        await _handleCreateOperation(operation);
        break;
      case SyncOperationType.update:
        await _handleUpdateOperation(operation);
        break;
      case SyncOperationType.delete:
        await _handleDeleteOperation(operation);
        break;
    }
  }

  /// Handle create operation
  Future<void> _handleCreateOperation(SyncOperation operation) async {
    // Implementation would depend on the entity type and cloud service
    print('Processing create operation for ${operation.entityType}:${operation.entityId}');
    
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    
    // In real implementation, this would make API calls to cloud service
    // and handle responses/errors appropriately
  }

  /// Handle update operation
  Future<void> _handleUpdateOperation(SyncOperation operation) async {
    print('Processing update operation for ${operation.entityType}:${operation.entityId}');
    await Future.delayed(const Duration(milliseconds: 300));
  }

  /// Handle delete operation
  Future<void> _handleDeleteOperation(SyncOperation operation) async {
    print('Processing delete operation for ${operation.entityType}:${operation.entityId}');
    await Future.delayed(const Duration(milliseconds: 200));
  }

  /// Force sync all pending operations
  Future<void> forceSyncAll() async {
    if (_isOnline) {
      await _triggerSync();
    }
  }

  /// Clear all pending sync operations
  Future<void> clearSyncQueue() async {
    _syncQueue.clear();
    await _saveSyncQueue();
  }

  /// Get last sync timestamp
  DateTime? getLastSyncTime() {
    final timestamp = _prefs.getInt(_lastSyncKey);
    return timestamp != null ? DateTime.fromMillisecondsSinceEpoch(timestamp) : null;
  }

  /// Check if data is stale (needs sync)
  bool isDataStale({Duration threshold = const Duration(hours: 1)}) {
    final lastSync = getLastSyncTime();
    if (lastSync == null) return true;
    
    return DateTime.now().difference(lastSync) > threshold;
  }

  /// Dispose resources
  void dispose() {
    _syncTimer?.cancel();
    _connectionController.close();
    _syncQueueController.close();
  }
}

/// Represents a sync operation to be performed when online
class SyncOperation {

  const SyncOperation({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.operationType,
    required this.data,
    required this.timestamp,
    this.retryCount = 0,
    this.lastError,
  });

  /// Create from JSON
  factory SyncOperation.fromJson(Map<String, dynamic> json) => SyncOperation(
      id: json['id'],
      entityType: json['entityType'],
      entityId: json['entityId'],
      operationType: SyncOperationType.values.firstWhere(
        (e) => e.name == json['operationType'],
      ),
      data: Map<String, dynamic>.from(json['data']),
      timestamp: DateTime.parse(json['timestamp']),
      retryCount: json['retryCount'] ?? 0,
      lastError: json['lastError'],
    );
  final String id;
  final String entityType;
  final String entityId;
  final SyncOperationType operationType;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final int retryCount;
  final String? lastError;

  /// Create a copy with updated fields
  SyncOperation copyWith({
    String? id,
    String? entityType,
    String? entityId,
    SyncOperationType? operationType,
    Map<String, dynamic>? data,
    DateTime? timestamp,
    int? retryCount,
    String? lastError,
  }) => SyncOperation(
      id: id ?? this.id,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      operationType: operationType ?? this.operationType,
      data: data ?? this.data,
      timestamp: timestamp ?? this.timestamp,
      retryCount: retryCount ?? this.retryCount,
      lastError: lastError ?? this.lastError,
    );

  /// Convert to JSON for persistence
  Map<String, dynamic> toJson() => {
      'id': id,
      'entityType': entityType,
      'entityId': entityId,
      'operationType': operationType.name,
      'data': data,
      'timestamp': timestamp.toIso8601String(),
      'retryCount': retryCount,
      'lastError': lastError,
    };

  @override
  String toString() => 'SyncOperation(id: $id, type: $operationType, entity: $entityType:$entityId, retries: $retryCount)';
}

/// Types of sync operations
enum SyncOperationType {
  create,
  update,
  delete,
}