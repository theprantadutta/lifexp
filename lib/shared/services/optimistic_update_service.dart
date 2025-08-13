import 'dart:async';
import 'package:flutter/material.dart';

/// Service for managing optimistic UI updates during offline operations
class OptimisticUpdateService {
  
  OptimisticUpdateService() {
    _startCleanupTimer();
  }
  final Map<String, OptimisticUpdate> _pendingUpdates = {};
  final StreamController<List<OptimisticUpdate>> _updatesController = 
      StreamController<List<OptimisticUpdate>>.broadcast();
  
  Timer? _cleanupTimer;

  /// Stream of pending optimistic updates
  Stream<List<OptimisticUpdate>> get updatesStream => _updatesController.stream;
  
  /// Get all pending updates
  List<OptimisticUpdate> get pendingUpdates => 
      List.unmodifiable(_pendingUpdates.values);
  
  /// Number of pending updates
  int get pendingCount => _pendingUpdates.length;

  /// Add an optimistic update
  void addUpdate(OptimisticUpdate update) {
    _pendingUpdates[update.id] = update;
    _notifyListeners();
    
    print('OptimisticUpdateService: Added update ${update.id} (${update.operation})');
  }

  /// Confirm an optimistic update (operation succeeded)
  void confirmUpdate(String updateId) {
    final update = _pendingUpdates.remove(updateId);
    if (update != null) {
      print('OptimisticUpdateService: Confirmed update $updateId');
      _notifyListeners();
    }
  }

  /// Revert an optimistic update (operation failed)
  void revertUpdate(String updateId, {String? reason}) {
    final update = _pendingUpdates.remove(updateId);
    if (update != null) {
      print('OptimisticUpdateService: Reverted update $updateId${reason != null ? ' - $reason' : ''}');
      _notifyListeners();
      
      // Notify about the revert
      if (update.onRevert != null) {
        update.onRevert!(reason);
      }
    }
  }

  /// Get specific update by ID
  OptimisticUpdate? getUpdate(String updateId) => _pendingUpdates[updateId];

  /// Get updates for specific entity
  List<OptimisticUpdate> getUpdatesForEntity(String entityType, String entityId) => _pendingUpdates.values
        .where((update) => 
            update.entityType == entityType && 
            update.entityId == entityId)
        .toList();

  /// Get updates by operation type
  List<OptimisticUpdate> getUpdatesByOperation(OptimisticOperation operation) => _pendingUpdates.values
        .where((update) => update.operation == operation)
        .toList();

  /// Check if entity has pending updates
  bool hasUpdatesForEntity(String entityType, String entityId) => _pendingUpdates.values.any((update) => 
        update.entityType == entityType && 
        update.entityId == entityId);

  /// Clear all updates
  void clearAllUpdates() {
    _pendingUpdates.clear();
    _notifyListeners();
    print('OptimisticUpdateService: Cleared all updates');
  }

  /// Clear updates for specific entity
  void clearUpdatesForEntity(String entityType, String entityId) {
    final toRemove = _pendingUpdates.entries
        .where((entry) => 
            entry.value.entityType == entityType && 
            entry.value.entityId == entityId)
        .map((entry) => entry.key)
        .toList();
    
    for (final key in toRemove) {
      _pendingUpdates.remove(key);
    }
    
    if (toRemove.isNotEmpty) {
      _notifyListeners();
      print('OptimisticUpdateService: Cleared ${toRemove.length} updates for $entityType:$entityId');
    }
  }

  /// Batch confirm multiple updates
  void batchConfirmUpdates(List<String> updateIds) {
    var removed = 0;
    for (final id in updateIds) {
      if (_pendingUpdates.remove(id) != null) {
        removed++;
      }
    }
    
    if (removed > 0) {
      _notifyListeners();
      print('OptimisticUpdateService: Batch confirmed $removed updates');
    }
  }

  /// Batch revert multiple updates
  void batchRevertUpdates(List<String> updateIds, {String? reason}) {
    var reverted = 0;
    final revertedUpdates = <OptimisticUpdate>[];
    
    for (final id in updateIds) {
      final update = _pendingUpdates.remove(id);
      if (update != null) {
        revertedUpdates.add(update);
        reverted++;
      }
    }
    
    if (reverted > 0) {
      _notifyListeners();
      print('OptimisticUpdateService: Batch reverted $reverted updates${reason != null ? ' - $reason' : ''}');
      
      // Notify about reverts
      for (final update in revertedUpdates) {
        if (update.onRevert != null) {
          update.onRevert!(reason);
        }
      }
    }
  }

  /// Get update statistics
  Map<String, dynamic> getStatistics() {
    final stats = <String, int>{};
    
    for (final update in _pendingUpdates.values) {
      final key = '${update.entityType}_${update.operation.name}';
      stats[key] = (stats[key] ?? 0) + 1;
    }
    
    return {
      'totalPending': _pendingUpdates.length,
      'byTypeAndOperation': stats,
      'oldestUpdate': _pendingUpdates.values.isNotEmpty
          ? _pendingUpdates.values
              .map((u) => u.timestamp)
              .reduce((a, b) => a.isBefore(b) ? a : b)
              .toIso8601String()
          : null,
    };
  }

  /// Start cleanup timer to remove old updates
  void _startCleanupTimer() {
    _cleanupTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _cleanupOldUpdates();
    });
  }

  /// Clean up old updates (older than 1 hour)
  void _cleanupOldUpdates() {
    final cutoff = DateTime.now().subtract(const Duration(hours: 1));
    final toRemove = <String>[];
    
    for (final entry in _pendingUpdates.entries) {
      if (entry.value.timestamp.isBefore(cutoff)) {
        toRemove.add(entry.key);
      }
    }
    
    if (toRemove.isNotEmpty) {
      for (final key in toRemove) {
        _pendingUpdates.remove(key);
      }
      _notifyListeners();
      print('OptimisticUpdateService: Cleaned up ${toRemove.length} old updates');
    }
  }

  /// Notify listeners about changes
  void _notifyListeners() {
    if (!_updatesController.isClosed) {
      _updatesController.add(pendingUpdates);
    }
  }

  /// Dispose resources
  void dispose() {
    _cleanupTimer?.cancel();
    _updatesController.close();
    _pendingUpdates.clear();
  }
}

/// Represents an optimistic update
class OptimisticUpdate {

  const OptimisticUpdate({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.operation,
    required this.data,
    required this.timestamp,
    this.description,
    this.onRevert,
  });

  /// Create an optimistic update for creation
  factory OptimisticUpdate.create({
    required String entityType,
    required String entityId,
    required Map<String, dynamic> data,
    String? description,
    void Function(String? reason)? onRevert,
  }) => OptimisticUpdate(
      id: '${entityId}_create_${DateTime.now().millisecondsSinceEpoch}',
      entityType: entityType,
      entityId: entityId,
      operation: OptimisticOperation.create,
      data: data,
      timestamp: DateTime.now(),
      description: description ?? 'Creating $entityType',
      onRevert: onRevert,
    );

  /// Create an optimistic update for update
  factory OptimisticUpdate.update({
    required String entityType,
    required String entityId,
    required Map<String, dynamic> data,
    String? description,
    void Function(String? reason)? onRevert,
  }) => OptimisticUpdate(
      id: '${entityId}_update_${DateTime.now().millisecondsSinceEpoch}',
      entityType: entityType,
      entityId: entityId,
      operation: OptimisticOperation.update,
      data: data,
      timestamp: DateTime.now(),
      description: description ?? 'Updating $entityType',
      onRevert: onRevert,
    );

  /// Create an optimistic update for deletion
  factory OptimisticUpdate.delete({
    required String entityType,
    required String entityId,
    Map<String, dynamic>? data,
    String? description,
    void Function(String? reason)? onRevert,
  }) => OptimisticUpdate(
      id: '${entityId}_delete_${DateTime.now().millisecondsSinceEpoch}',
      entityType: entityType,
      entityId: entityId,
      operation: OptimisticOperation.delete,
      data: data ?? {},
      timestamp: DateTime.now(),
      description: description ?? 'Deleting $entityType',
      onRevert: onRevert,
    );
  final String id;
  final String entityType;
  final String entityId;
  final OptimisticOperation operation;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final String? description;
  final void Function(String? reason)? onRevert;

  /// Age of the update
  Duration get age => DateTime.now().difference(timestamp);

  /// Whether the update is old (older than 30 minutes)
  bool get isOld => age > const Duration(minutes: 30);

  @override
  String toString() => 'OptimisticUpdate(id: $id, operation: $operation, entity: $entityType:$entityId, age: ${age.inMinutes}m)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OptimisticUpdate && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Types of optimistic operations
enum OptimisticOperation {
  create,
  update,
  delete,
}

/// Mixin for widgets that need optimistic update awareness
mixin OptimisticUpdateMixin<T extends StatefulWidget> on State<T> {
  late OptimisticUpdateService _updateService;
  StreamSubscription<List<OptimisticUpdate>>? _updatesSubscription;
  List<OptimisticUpdate> _pendingUpdates = [];
  
  @override
  void initState() {
    super.initState();
    _updateService = OptimisticUpdateService();
    _pendingUpdates = _updateService.pendingUpdates;
    
    _updatesSubscription = _updateService.updatesStream.listen((updates) {
      if (mounted && _pendingUpdates != updates) {
        setState(() {
          _pendingUpdates = updates;
        });
        onOptimisticUpdatesChanged(updates);
      }
    });
  }
  
  @override
  void dispose() {
    _updatesSubscription?.cancel();
    _updateService.dispose();
    super.dispose();
  }
  
  /// Called when optimistic updates change
  void onOptimisticUpdatesChanged(List<OptimisticUpdate> updates) {}
  
  /// Current pending updates
  List<OptimisticUpdate> get pendingUpdates => _pendingUpdates;
  
  /// Add optimistic update
  void addOptimisticUpdate(OptimisticUpdate update) {
    _updateService.addUpdate(update);
  }
  
  /// Confirm optimistic update
  void confirmOptimisticUpdate(String updateId) {
    _updateService.confirmUpdate(updateId);
  }
  
  /// Revert optimistic update
  void revertOptimisticUpdate(String updateId, {String? reason}) {
    _updateService.revertUpdate(updateId, reason: reason);
  }
  
  /// Check if entity has pending updates
  bool hasOptimisticUpdates(String entityType, String entityId) => _updateService.hasUpdatesForEntity(entityType, entityId);
  
  /// Get updates for entity
  List<OptimisticUpdate> getOptimisticUpdates(String entityType, String entityId) => _updateService.getUpdatesForEntity(entityType, entityId);
}