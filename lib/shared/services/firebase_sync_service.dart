import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'conflict_resolution_service.dart';
import 'offline_data_manager.dart';

/// Service for syncing data with Firebase Cloud Firestore
class FirebaseSyncService {
  
  FirebaseSyncService({
    required OfflineDataManager offlineManager, FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    ConflictResolutionService? conflictResolver,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _conflictResolver = conflictResolver ?? ConflictResolutionService(),
       _offlineManager = offlineManager {
    _initializeBackgroundSync();
  }
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final ConflictResolutionService _conflictResolver;
  final OfflineDataManager _offlineManager;
  
  Timer? _backgroundSyncTimer;
  bool _isSyncing = false;
  final StreamController<SyncStatus> _syncStatusController = StreamController<SyncStatus>.broadcast();

  /// Stream of sync status updates
  Stream<SyncStatus> get syncStatusStream => _syncStatusController.stream;
  
  /// Whether sync is currently in progress
  bool get isSyncing => _isSyncing;
  
  /// Current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  /// Initialize background sync
  void _initializeBackgroundSync() {
    // Start background sync every 5 minutes when online
    _backgroundSyncTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      if (_offlineManager.isOnline && !_isSyncing && currentUserId != null) {
        _performBackgroundSync();
      }
    });
    
    // Listen for connection changes to trigger sync
    _offlineManager.connectionStream.listen((isOnline) {
      if (isOnline && !_isSyncing && currentUserId != null) {
        _performBackgroundSync();
      }
    });
  }

  /// Perform background sync
  Future<void> _performBackgroundSync() async {
    try {
      await syncAllData();
    } catch (e) {
      print('FirebaseSyncService: Background sync failed: $e');
    }
  }

  /// Sync all user data
  Future<SyncResult> syncAllData() async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }
    
    if (_isSyncing) {
      throw Exception('Sync already in progress');
    }

    _isSyncing = true;
    _updateSyncStatus(SyncStatus.syncing('Starting sync...'));
    
    try {
      final result = SyncResult();
      
      // Sync each entity type
      final taskResult = await _syncEntityType('tasks');
      final avatarResult = await _syncEntityType('avatars');
      final achievementResult = await _syncEntityType('achievements');
      final progressResult = await _syncEntityType('progress');
      
      result.merge(taskResult);
      result.merge(avatarResult);
      result.merge(achievementResult);
      result.merge(progressResult);
      
      _updateSyncStatus(SyncStatus.completed(result));
      return result;
    } catch (e) {
      final error = 'Sync failed: $e';
      _updateSyncStatus(SyncStatus.error(error));
      rethrow;
    } finally {
      _isSyncing = false;
    }
  }

  /// Sync specific entity type
  Future<EntitySyncResult> _syncEntityType(String entityType) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    _updateSyncStatus(SyncStatus.syncing('Syncing $entityType...'));
    
    try {
      // Get local pending operations for this entity type
      final pendingOps = _offlineManager.syncQueue
          .where((op) => op.entityType == entityType)
          .toList();
      
      // Upload pending changes first
      final uploadResult = await _uploadPendingChanges(entityType, pendingOps);
      
      // Download remote changes
      final downloadResult = await _downloadRemoteChanges(entityType);
      
      // Combine results
      return EntitySyncResult(
        entityType: entityType,
        uploaded: uploadResult.uploaded,
        downloaded: downloadResult.downloaded,
        conflicts: uploadResult.conflicts + downloadResult.conflicts,
        errors: [...uploadResult.errors, ...downloadResult.errors],
      );
    } catch (e) {
      return EntitySyncResult(
        entityType: entityType,
        errors: ['Failed to sync $entityType: $e'],
      );
    }
  }

  /// Upload pending changes to Firebase
  Future<EntitySyncResult> _uploadPendingChanges(String entityType, List<SyncOperation> operations) async {
    final result = EntitySyncResult(entityType: entityType);
    
    for (final operation in operations) {
      try {
        await _uploadSingleOperation(operation);
        result.uploaded++;
        
        // Remove from offline queue after successful upload
        // Note: This would need to be coordinated with OfflineDataManager
      } catch (e) {
        result.errors.add('Failed to upload ${operation.entityId}: $e');
      }
    }
    
    return result;
  }

  /// Upload single operation to Firebase
  Future<void> _uploadSingleOperation(SyncOperation operation) async {
    if (currentUserId == null) return;
    
    final collection = _firestore
        .collection('users')
        .doc(currentUserId)
        .collection(operation.entityType);
    
    final docRef = collection.doc(operation.entityId);
    
    switch (operation.operationType) {
      case SyncOperationType.create:
      case SyncOperationType.update:
        await docRef.set({
          ...operation.data,
          'lastModified': FieldValue.serverTimestamp(),
          'syncVersion': FieldValue.increment(1),
        }, SetOptions(merge: true));
        break;
        
      case SyncOperationType.delete:
        await docRef.delete();
        break;
    }
  }

  /// Download remote changes from Firebase
  Future<EntitySyncResult> _downloadRemoteChanges(String entityType) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }
    
    final result = EntitySyncResult(entityType: entityType);
    
    try {
      final collection = _firestore
          .collection('users')
          .doc(currentUserId)
          .collection(entityType);
      
      // Get last sync timestamp
      final lastSync = _offlineManager.getLastSyncTime();
      Query query = collection;
      
      if (lastSync != null) {
        // Only get documents modified since last sync
        query = collection.where('lastModified', isGreaterThan: Timestamp.fromDate(lastSync));
      }
      
      final snapshot = await query.get();
      
      for (final doc in snapshot.docs) {
        try {
          await _processRemoteDocument(doc, entityType);
          result.downloaded++;
        } catch (e) {
          result.errors.add('Failed to process ${doc.id}: $e');
        }
      }
      
      return result;
    } catch (e) {
      result.errors.add('Failed to download $entityType: $e');
      return result;
    }
  }

  /// Process a remote document
  Future<void> _processRemoteDocument(QueryDocumentSnapshot doc, String entityType) async {
    final remoteData = doc.data()! as Map<String, dynamic>;
    remoteData['id'] = doc.id;
    
    // Check if we have local version
    final hasLocal = await _hasLocalEntity(entityType, doc.id);
    
    if (!hasLocal) {
      // New remote entity - save locally
      await _saveLocalEntity(entityType, remoteData);
    } else {
      // Potential conflict - resolve
      final localData = await _getLocalEntity(entityType, doc.id);
      if (localData != null) {
        await _resolveConflict(entityType, localData, remoteData);
      }
    }
  }

  /// Resolve conflict between local and remote data
  Future<void> _resolveConflict(String entityType, Map<String, dynamic> localData, Map<String, dynamic> remoteData) async {
    final conflict = DataConflict(
      entityId: localData['id'],
      entityType: entityType,
      localData: localData,
      remoteData: remoteData,
      resolutionStrategy: ConflictResolutionStrategy.merge,
    );
    
    final resolution = await _conflictResolver.resolveConflict(conflict);
    await _saveLocalEntity(entityType, resolution.resolvedData);
    
    // If resolution favored local data, upload to remote
    if (resolution.resolution == ConflictResolutionType.useLocal ||
        resolution.resolution == ConflictResolutionType.merged) {
      await _uploadEntityToRemote(entityType, resolution.resolvedData);
    }
  }

  /// Upload entity to remote
  Future<void> _uploadEntityToRemote(String entityType, Map<String, dynamic> data) async {
    if (currentUserId == null) return;
    
    final collection = _firestore
        .collection('users')
        .doc(currentUserId)
        .collection(entityType);
    
    await collection.doc(data['id']).set({
      ...data,
      'lastModified': FieldValue.serverTimestamp(),
      'syncVersion': FieldValue.increment(1),
    }, SetOptions(merge: true));
  }

  /// Backup all user data to Firebase
  Future<void> backupUserData() async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }
    
    _updateSyncStatus(SyncStatus.syncing('Creating backup...'));
    
    try {
      final backupData = {
        'createdAt': FieldValue.serverTimestamp(),
        'version': '1.0',
        'entities': <String, dynamic>{},
      };
      
      // Collect all entity types
      final entityTypes = ['tasks', 'avatars', 'achievements', 'progress'];
      
      for (final entityType in entityTypes) {
        final entities = await _getAllLocalEntities(entityType);
        backupData['entities'][entityType] = entities;
      }
      
      // Save backup
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('backups')
          .add(backupData);
      
      _updateSyncStatus(SyncStatus.completed(SyncResult()..backupCreated = true));
    } catch (e) {
      _updateSyncStatus(SyncStatus.error('Backup failed: $e'));
      rethrow;
    }
  }

  /// Restore user data from Firebase backup
  Future<void> restoreUserData({String? backupId}) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }
    
    _updateSyncStatus(SyncStatus.syncing('Restoring from backup...'));
    
    try {
      final Query backupsQuery = _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('backups');
      
      if (backupId != null) {
        // Restore specific backup
        final doc = await backupsQuery.doc(backupId).get();
        if (!doc.exists) {
          throw Exception('Backup not found');
        }
        await _restoreFromBackupData(doc.data() as Map<String, dynamic>);
      } else {
        // Restore latest backup
        final snapshot = await backupsQuery
            .orderBy('createdAt', descending: true)
            .limit(1)
            .get();
        
        if (snapshot.docs.isEmpty) {
          throw Exception('No backups found');
        }
        
        await _restoreFromBackupData(snapshot.docs.first.data());
      }
      
      _updateSyncStatus(SyncStatus.completed(SyncResult()..dataRestored = true));
    } catch (e) {
      _updateSyncStatus(SyncStatus.error('Restore failed: $e'));
      rethrow;
    }
  }

  /// Restore from backup data
  Future<void> _restoreFromBackupData(Map<String, dynamic> backupData) async {
    final entities = backupData['entities'] as Map<String, dynamic>;
    
    for (final entry in entities.entries) {
      final entityType = entry.key;
      final entityList = entry.value as List<dynamic>;
      
      for (final entityData in entityList) {
        await _saveLocalEntity(entityType, entityData as Map<String, dynamic>);
      }
    }
  }

  /// Get list of available backups
  Future<List<BackupInfo>> getAvailableBackups() async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }
    
    final snapshot = await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('backups')
        .orderBy('createdAt', descending: true)
        .get();
    
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return BackupInfo(
        id: doc.id,
        createdAt: (data['createdAt'] as Timestamp).toDate(),
        version: data['version'] as String? ?? '1.0',
        entityCounts: _extractEntityCounts(data['entities'] as Map<String, dynamic>),
      );
    }).toList();
  }

  /// Extract entity counts from backup data
  Map<String, int> _extractEntityCounts(Map<String, dynamic> entities) {
    final counts = <String, int>{};
    for (final entry in entities.entries) {
      final entityList = entry.value as List<dynamic>;
      counts[entry.key] = entityList.length;
    }
    return counts;
  }

  /// Sync with exponential backoff retry
  Future<SyncResult> syncWithRetry({int maxRetries = 3}) async {
    var attempt = 0;
    var delay = const Duration(seconds: 1);
    
    while (attempt < maxRetries) {
      try {
        return await syncAllData();
      } catch (e) {
        attempt++;
        if (attempt >= maxRetries) {
          rethrow;
        }
        
        print('FirebaseSyncService: Sync attempt $attempt failed, retrying in ${delay.inSeconds}s: $e');
        await Future.delayed(delay);
        delay = Duration(seconds: min(delay.inSeconds * 2, 30)); // Max 30 seconds
      }
    }
    
    throw Exception('Sync failed after $maxRetries attempts');
  }

  /// Update sync status
  void _updateSyncStatus(SyncStatus status) {
    if (!_syncStatusController.isClosed) {
      _syncStatusController.add(status);
    }
  }

  // Placeholder methods for local data operations
  // These would be implemented to work with your local database
  
  Future<bool> _hasLocalEntity(String entityType, String entityId) async {
    // Implementation depends on your local database structure
    return false;
  }
  
  Future<Map<String, dynamic>?> _getLocalEntity(String entityType, String entityId) async {
    // Implementation depends on your local database structure
    return null;
  }
  
  Future<void> _saveLocalEntity(String entityType, Map<String, dynamic> data) async {
    // Implementation depends on your local database structure
  }
  
  Future<List<Map<String, dynamic>>> _getAllLocalEntities(String entityType) async {
    // Implementation depends on your local database structure
    return [];
  }

  /// Dispose resources
  void dispose() {
    _backgroundSyncTimer?.cancel();
    _syncStatusController.close();
  }
}

/// Sync status information
class SyncStatus {

  const SyncStatus._({
    required this.state,
    required this.message,
    this.result,
    this.error,
    this.progress,
  });

  factory SyncStatus.idle() => const SyncStatus._(
    state: SyncState.idle,
    message: 'Ready to sync',
  );

  factory SyncStatus.syncing(String message, {double? progress}) => SyncStatus._(
    state: SyncState.syncing,
    message: message,
    progress: progress,
  );

  factory SyncStatus.completed(SyncResult result) => SyncStatus._(
    state: SyncState.completed,
    message: 'Sync completed successfully',
    result: result,
  );

  factory SyncStatus.error(String error) => SyncStatus._(
    state: SyncState.error,
    message: 'Sync failed',
    error: error,
  );
  final SyncState state;
  final String message;
  final SyncResult? result;
  final String? error;
  final double? progress;

  bool get isIdle => state == SyncState.idle;
  bool get isSyncing => state == SyncState.syncing;
  bool get isCompleted => state == SyncState.completed;
  bool get isError => state == SyncState.error;

  @override
  String toString() => 'SyncStatus(state: $state, message: $message)';
}

/// Sync state enum
enum SyncState {
  idle,
  syncing,
  completed,
  error,
}

/// Overall sync result
class SyncResult {
  int totalUploaded = 0;
  int totalDownloaded = 0;
  int totalConflicts = 0;
  final List<String> errors = [];
  bool backupCreated = false;
  bool dataRestored = false;

  void merge(EntitySyncResult entityResult) {
    totalUploaded += entityResult.uploaded;
    totalDownloaded += entityResult.downloaded;
    totalConflicts += entityResult.conflicts;
    errors.addAll(entityResult.errors);
  }

  bool get hasErrors => errors.isNotEmpty;
  bool get isSuccessful => errors.isEmpty;

  @override
  String toString() => 'SyncResult(uploaded: $totalUploaded, downloaded: $totalDownloaded, conflicts: $totalConflicts, errors: ${errors.length})';
}

/// Entity-specific sync result
class EntitySyncResult {

  EntitySyncResult({
    required this.entityType,
    this.uploaded = 0,
    this.downloaded = 0,
    this.conflicts = 0,
    List<String>? errors,
  }) : errors = errors ?? [];
  final String entityType;
  int uploaded;
  int downloaded;
  int conflicts;
  final List<String> errors;

  bool get hasErrors => errors.isNotEmpty;
  bool get isSuccessful => errors.isEmpty;

  @override
  String toString() => 'EntitySyncResult($entityType: uploaded: $uploaded, downloaded: $downloaded, conflicts: $conflicts, errors: ${errors.length})';
}

/// Backup information
class BackupInfo {

  const BackupInfo({
    required this.id,
    required this.createdAt,
    required this.version,
    required this.entityCounts,
  });
  final String id;
  final DateTime createdAt;
  final String version;
  final Map<String, int> entityCounts;

  int get totalEntities => entityCounts.values.fold(0, (sum, count) => sum + count);

  @override
  String toString() => 'BackupInfo(id: $id, createdAt: $createdAt, entities: $totalEntities)';
}