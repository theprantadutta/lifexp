import 'dart:async';
import 'dart:convert';

import '../../shared/services/conflict_resolution_service.dart';
import '../../shared/services/offline_data_manager.dart';

/// Base repository class that provides offline-first functionality
abstract class BaseOfflineRepository<T> {
  
  BaseOfflineRepository({
    OfflineDataManager? offlineManager,
    ConflictResolutionService? conflictResolver,
  }) : _offlineManager = offlineManager,
       _conflictResolver = conflictResolver ?? ConflictResolutionService();
  final OfflineDataManager? _offlineManager;
  final ConflictResolutionService _conflictResolver;

  /// Entity type name for sync operations
  String get entityType;
  
  /// Convert entity to map for storage/sync
  Map<String, dynamic> entityToMap(T entity);
  
  /// Convert map to entity
  T entityFromMap(Map<String, dynamic> map);
  
  /// Get entity ID
  String getEntityId(T entity);
  
  /// Save entity to local storage
  Future<void> saveToLocal(T entity, String userId);
  
  /// Load entity from local storage
  Future<T?> loadFromLocal(String entityId);
  
  /// Load all entities from local storage for user
  Future<List<T>> loadAllFromLocal(String userId);
  
  /// Delete entity from local storage
  Future<void> deleteFromLocal(String entityId);

  /// Create entity with offline support
  Future<T> createEntity(T entity, String userId) async {
    // Save to local storage first (offline-first approach)
    await saveToLocal(entity, userId);
    
    // Queue for sync if offline manager is available
    await _queueSyncOperation(
      SyncOperation(
        id: '${getEntityId(entity)}_create_${DateTime.now().millisecondsSinceEpoch}',
        entityType: entityType,
        entityId: getEntityId(entity),
        operationType: SyncOperationType.create,
        data: entityToMap(entity)..['userId'] = userId,
        timestamp: DateTime.now(),
      ),
    );
    
    return entity;
  }

  /// Update entity with offline support
  Future<T> updateEntity(T entity, String userId) async {
    // Update local storage first
    await saveToLocal(entity, userId);
    
    // Queue for sync
    await _queueSyncOperation(
      SyncOperation(
        id: '${getEntityId(entity)}_update_${DateTime.now().millisecondsSinceEpoch}',
        entityType: entityType,
        entityId: getEntityId(entity),
        operationType: SyncOperationType.update,
        data: entityToMap(entity)..['userId'] = userId,
        timestamp: DateTime.now(),
      ),
    );
    
    return entity;
  }

  /// Delete entity with offline support
  Future<void> deleteEntity(String entityId, String userId) async {
    // Delete from local storage first
    await deleteFromLocal(entityId);
    
    // Queue for sync
    await _queueSyncOperation(
      SyncOperation(
        id: '${entityId}_delete_${DateTime.now().millisecondsSinceEpoch}',
        entityType: entityType,
        entityId: entityId,
        operationType: SyncOperationType.delete,
        data: {'userId': userId},
        timestamp: DateTime.now(),
      ),
    );
  }

  /// Get entity by ID with offline support
  Future<T?> getEntity(String entityId) async => loadFromLocal(entityId);

  /// Get all entities for user with offline support
  Future<List<T>> getAllEntities(String userId) async => loadAllFromLocal(userId);

  /// Batch create entities
  Future<List<T>> batchCreateEntities(List<T> entities, String userId) async {
    final results = <T>[];
    
    for (final entity in entities) {
      try {
        final result = await createEntity(entity, userId);
        results.add(result);
      } catch (e) {
        print('BaseOfflineRepository: Failed to create entity ${getEntityId(entity)}: $e');
        // Continue with other entities
      }
    }
    
    return results;
  }

  /// Batch update entities
  Future<List<T>> batchUpdateEntities(List<T> entities, String userId) async {
    final results = <T>[];
    
    for (final entity in entities) {
      try {
        final result = await updateEntity(entity, userId);
        results.add(result);
      } catch (e) {
        print('BaseOfflineRepository: Failed to update entity ${getEntityId(entity)}: $e');
        // Continue with other entities
      }
    }
    
    return results;
  }

  /// Sync entities with remote data
  Future<SyncResult> syncEntities(String userId, List<Map<String, dynamic>> remoteData) async {
    try {
      final localEntities = await loadAllFromLocal(userId);
      final localData = localEntities.map(entityToMap).toList();
      
      // Detect conflicts
      final conflicts = _conflictResolver.detectConflicts(localData, remoteData);
      
      final syncResult = SyncResult(
        totalLocal: localData.length,
        totalRemote: remoteData.length,
        conflicts: conflicts.length,
        resolved: 0,
        errors: [],
      );
      
      // Resolve conflicts
      for (final conflict in conflicts) {
        try {
          final resolution = await _conflictResolver.resolveConflict(conflict);
          final resolvedEntity = entityFromMap(resolution.resolvedData);
          
          await saveToLocal(resolvedEntity, userId);
          syncResult.resolved++;
          
          print('BaseOfflineRepository: Resolved conflict for ${conflict.entityId}: ${resolution.reason}');
        } catch (e) {
          syncResult.errors.add('Failed to resolve conflict for ${conflict.entityId}: $e');
          print('BaseOfflineRepository: Failed to resolve conflict for ${conflict.entityId}: $e');
        }
      }
      
      // Handle new remote entities (not in local)
      final localIds = localData.map((e) => e['id'] as String).toSet();
      final newRemoteEntities = remoteData.where((e) => !localIds.contains(e['id'])).toList();
      
      for (final remoteEntityData in newRemoteEntities) {
        try {
          final entity = entityFromMap(remoteEntityData);
          await saveToLocal(entity, userId);
          syncResult.resolved++;
        } catch (e) {
          syncResult.errors.add('Failed to save new remote entity ${remoteEntityData['id']}: $e');
        }
      }
      
      return syncResult;
    } catch (e) {
      return SyncResult(
        totalLocal: 0,
        totalRemote: remoteData.length,
        conflicts: 0,
        resolved: 0,
        errors: ['Sync failed: $e'],
      );
    }
  }

  /// Check if entity exists locally
  Future<bool> entityExists(String entityId) async {
    final entity = await loadFromLocal(entityId);
    return entity != null;
  }

  /// Get entities modified since timestamp
  Future<List<T>> getEntitiesModifiedSince(String userId, DateTime timestamp) async {
    final allEntities = await loadAllFromLocal(userId);
    return allEntities.where((entity) {
      final entityMap = entityToMap(entity);
      final updatedAt = entityMap['updatedAt'];
      
      if (updatedAt is String) {
        final entityTimestamp = DateTime.tryParse(updatedAt);
        return entityTimestamp != null && entityTimestamp.isAfter(timestamp);
      } else if (updatedAt is int) {
        final entityTimestamp = DateTime.fromMillisecondsSinceEpoch(updatedAt);
        return entityTimestamp.isAfter(timestamp);
      }
      
      return false;
    }).toList();
  }

  /// Get sync statistics
  Future<Map<String, dynamic>> getSyncStats(String userId) async {
    final localEntities = await loadAllFromLocal(userId);
    final pendingSyncCount = _offlineManager?.pendingSyncCount ?? 0;
    final lastSyncTime = _offlineManager?.getLastSyncTime();
    
    return {
      'localCount': localEntities.length,
      'pendingSyncCount': pendingSyncCount,
      'lastSyncTime': lastSyncTime?.toIso8601String(),
      'isOnline': _offlineManager?.isOnline ?? false,
    };
  }

  /// Clear all local data for user
  Future<void> clearLocalData(String userId) async {
    final entities = await loadAllFromLocal(userId);
    for (final entity in entities) {
      await deleteFromLocal(getEntityId(entity));
    }
  }

  /// Export entities to JSON
  Future<String> exportEntities(String userId) async {
    final entities = await loadAllFromLocal(userId);
    final data = entities.map(entityToMap).toList();
    return jsonEncode({
      'entityType': entityType,
      'exportTime': DateTime.now().toIso8601String(),
      'userId': userId,
      'entities': data,
    });
  }

  /// Import entities from JSON
  Future<ImportResult> importEntities(String jsonData, String userId) async {
    try {
      final data = jsonDecode(jsonData) as Map<String, dynamic>;
      final entitiesData = data['entities'] as List<dynamic>;
      
      final importResult = ImportResult(
        total: entitiesData.length,
        imported: 0,
        skipped: 0,
        errors: [],
      );
      
      for (final entityData in entitiesData) {
        try {
          final entity = entityFromMap(entityData as Map<String, dynamic>);
          final exists = await entityExists(getEntityId(entity));
          
          if (exists) {
            importResult.skipped++;
          } else {
            await saveToLocal(entity, userId);
            importResult.imported++;
          }
        } catch (e) {
          importResult.errors.add('Failed to import entity: $e');
        }
      }
      
      return importResult;
    } catch (e) {
      return ImportResult(
        total: 0,
        imported: 0,
        skipped: 0,
        errors: ['Import failed: $e'],
      );
    }
  }

  /// Queue sync operation
  Future<void> _queueSyncOperation(SyncOperation operation) async {
    if (_offlineManager == null) return;
    
    try {
      await _offlineManager.queueSyncOperation(operation);
    } catch (e) {
      print('BaseOfflineRepository: Failed to queue sync operation: $e');
      // Continue execution - offline support is not critical for core functionality
    }
  }

  /// Get offline manager (for subclasses)
  OfflineDataManager? get offlineManager => _offlineManager;
  
  /// Get conflict resolver (for subclasses)
  ConflictResolutionService get conflictResolver => _conflictResolver;
}

/// Result of sync operation
class SyncResult {

  SyncResult({
    required this.totalLocal,
    required this.totalRemote,
    required this.conflicts,
    required this.resolved,
    required this.errors,
  });
  final int totalLocal;
  final int totalRemote;
  final int conflicts;
  int resolved;
  final List<String> errors;

  bool get hasErrors => errors.isNotEmpty;
  bool get hasConflicts => conflicts > 0;
  bool get isSuccessful => errors.isEmpty && resolved >= conflicts;

  @override
  String toString() => 'SyncResult(local: $totalLocal, remote: $totalRemote, conflicts: $conflicts, resolved: $resolved, errors: ${errors.length})';
}

/// Result of import operation
class ImportResult {

  ImportResult({
    required this.total,
    required this.imported,
    required this.skipped,
    required this.errors,
  });
  final int total;
  int imported;
  int skipped;
  final List<String> errors;

  bool get hasErrors => errors.isNotEmpty;
  bool get isSuccessful => errors.isEmpty;
  double get successRate => total > 0 ? imported / total : 0.0;

  @override
  String toString() => 'ImportResult(total: $total, imported: $imported, skipped: $skipped, errors: ${errors.length})';
}