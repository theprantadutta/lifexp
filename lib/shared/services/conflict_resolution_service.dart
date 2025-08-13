
/// Service for resolving data conflicts during sync operations
class ConflictResolutionService {
  /// Resolve conflicts between local and remote data
  Future<ConflictResolution> resolveConflict(DataConflict conflict) async {
    switch (conflict.resolutionStrategy) {
      case ConflictResolutionStrategy.lastWriteWins:
        return _resolveLastWriteWins(conflict);
      case ConflictResolutionStrategy.localWins:
        return _resolveLocalWins(conflict);
      case ConflictResolutionStrategy.remoteWins:
        return _resolveRemoteWins(conflict);
      case ConflictResolutionStrategy.merge:
        return _resolveMerge(conflict);
      case ConflictResolutionStrategy.userChoice:
        return _resolveUserChoice(conflict);
    }
  }

  /// Resolve using last write wins strategy
  ConflictResolution _resolveLastWriteWins(DataConflict conflict) {
    final localTimestamp = _extractTimestamp(conflict.localData);
    final remoteTimestamp = _extractTimestamp(conflict.remoteData);
    
    if (localTimestamp.isAfter(remoteTimestamp)) {
      return ConflictResolution(
        resolvedData: conflict.localData,
        resolution: ConflictResolutionType.useLocal,
        reason: 'Local data is more recent',
      );
    } else {
      return ConflictResolution(
        resolvedData: conflict.remoteData,
        resolution: ConflictResolutionType.useRemote,
        reason: 'Remote data is more recent',
      );
    }
  }

  /// Resolve by keeping local data
  ConflictResolution _resolveLocalWins(DataConflict conflict) => ConflictResolution(
      resolvedData: conflict.localData,
      resolution: ConflictResolutionType.useLocal,
      reason: 'Local data takes precedence',
    );

  /// Resolve by keeping remote data
  ConflictResolution _resolveRemoteWins(DataConflict conflict) => ConflictResolution(
      resolvedData: conflict.remoteData,
      resolution: ConflictResolutionType.useRemote,
      reason: 'Remote data takes precedence',
    );

  /// Resolve by merging data intelligently
  ConflictResolution _resolveMerge(DataConflict conflict) {
    try {
      final mergedData = _mergeData(conflict.localData, conflict.remoteData);
      return ConflictResolution(
        resolvedData: mergedData,
        resolution: ConflictResolutionType.merged,
        reason: 'Data merged successfully',
      );
    } catch (e) {
      // If merge fails, fall back to last write wins
      return _resolveLastWriteWins(conflict);
    }
  }

  /// Resolve by asking user to choose
  ConflictResolution _resolveUserChoice(DataConflict conflict) {
    // This would typically show a UI dialog for user to choose
    // For now, we'll fall back to last write wins
    return _resolveLastWriteWins(conflict);
  }

  /// Merge two data objects intelligently
  Map<String, dynamic> _mergeData(
    Map<String, dynamic> localData,
    Map<String, dynamic> remoteData,
  ) {
    final merged = Map<String, dynamic>.from(remoteData);
    
    // Merge based on entity type
    final entityType = localData['entityType'] ?? remoteData['entityType'];
    
    switch (entityType) {
      case 'task':
        return _mergeTaskData(localData, remoteData);
      case 'avatar':
        return _mergeAvatarData(localData, remoteData);
      case 'achievement':
        return _mergeAchievementData(localData, remoteData);
      case 'progress':
        return _mergeProgressData(localData, remoteData);
      default:
        // Generic merge - take newer fields
        return _genericMerge(localData, remoteData);
    }
  }

  /// Merge task data specifically
  Map<String, dynamic> _mergeTaskData(
    Map<String, dynamic> localData,
    Map<String, dynamic> remoteData,
  ) {
    final merged = Map<String, dynamic>.from(remoteData);
    
    // For tasks, prioritize completion status and streak count from most recent
    final localTimestamp = _extractTimestamp(localData);
    final remoteTimestamp = _extractTimestamp(remoteData);
    
    if (localTimestamp.isAfter(remoteTimestamp)) {
      // Local is newer, keep completion status and streak
      merged['isCompleted'] = localData['isCompleted'];
      merged['completedAt'] = localData['completedAt'];
      merged['streakCount'] = localData['streakCount'];
      merged['lastCompletedDate'] = localData['lastCompletedDate'];
    }
    
    // Always keep the higher streak count
    final localStreak = localData['streakCount'] ?? 0;
    final remoteStreak = remoteData['streakCount'] ?? 0;
    merged['streakCount'] = localStreak > remoteStreak ? localStreak : remoteStreak;
    
    return merged;
  }

  /// Merge avatar data specifically
  Map<String, dynamic> _mergeAvatarData(
    Map<String, dynamic> localData,
    Map<String, dynamic> remoteData,
  ) {
    final merged = Map<String, dynamic>.from(remoteData);
    
    // For avatars, always keep the higher values
    merged['level'] = _max(localData['level'], remoteData['level']);
    merged['totalXP'] = _max(localData['totalXP'], remoteData['totalXP']);
    merged['currentXP'] = _max(localData['currentXP'], remoteData['currentXP']);
    
    // Merge attributes by taking maximum values
    final localAttributes = localData['attributes'] as Map<String, dynamic>? ?? {};
    final remoteAttributes = remoteData['attributes'] as Map<String, dynamic>? ?? {};
    final mergedAttributes = <String, dynamic>{};
    
    final allAttributeKeys = {...localAttributes.keys, ...remoteAttributes.keys};
    for (final key in allAttributeKeys) {
      mergedAttributes[key] = _max(
        localAttributes[key] ?? 0,
        remoteAttributes[key] ?? 0,
      );
    }
    merged['attributes'] = mergedAttributes;
    
    // Merge unlocked items
    final localItems = List<String>.from(localData['unlockedItems'] ?? []);
    final remoteItems = List<String>.from(remoteData['unlockedItems'] ?? []);
    merged['unlockedItems'] = {...localItems, ...remoteItems}.toList();
    
    return merged;
  }

  /// Merge achievement data specifically
  Map<String, dynamic> _mergeAchievementData(
    Map<String, dynamic> localData,
    Map<String, dynamic> remoteData,
  ) {
    final merged = Map<String, dynamic>.from(remoteData);
    
    // For achievements, keep unlocked status if either is unlocked
    final localUnlocked = localData['isUnlocked'] ?? false;
    final remoteUnlocked = remoteData['isUnlocked'] ?? false;
    merged['isUnlocked'] = localUnlocked || remoteUnlocked;
    
    // Keep the earlier unlock date if both are unlocked
    if (localUnlocked && remoteUnlocked) {
      final localUnlockDate = DateTime.tryParse(localData['unlockedAt'] ?? '');
      final remoteUnlockDate = DateTime.tryParse(remoteData['unlockedAt'] ?? '');
      
      if (localUnlockDate != null && remoteUnlockDate != null) {
        merged['unlockedAt'] = localUnlockDate.isBefore(remoteUnlockDate)
            ? localData['unlockedAt']
            : remoteData['unlockedAt'];
      }
    } else if (localUnlocked) {
      merged['unlockedAt'] = localData['unlockedAt'];
    }
    
    // Keep higher progress
    merged['progress'] = _max(
      localData['progress'] ?? 0.0,
      remoteData['progress'] ?? 0.0,
    );
    
    return merged;
  }

  /// Merge progress data specifically
  Map<String, dynamic> _mergeProgressData(
    Map<String, dynamic> localData,
    Map<String, dynamic> remoteData,
  ) {
    final merged = Map<String, dynamic>.from(remoteData);
    
    // For progress entries, sum up the values
    merged['xpGained'] = (localData['xpGained'] ?? 0) + (remoteData['xpGained'] ?? 0);
    merged['tasksCompleted'] = (localData['tasksCompleted'] ?? 0) + (remoteData['tasksCompleted'] ?? 0);
    
    return merged;
  }

  /// Generic merge strategy
  Map<String, dynamic> _genericMerge(
    Map<String, dynamic> localData,
    Map<String, dynamic> remoteData,
  ) {
    final merged = Map<String, dynamic>.from(remoteData);
    
    final localTimestamp = _extractTimestamp(localData);
    final remoteTimestamp = _extractTimestamp(remoteData);
    
    // If local is newer, override with local values
    if (localTimestamp.isAfter(remoteTimestamp)) {
      localData.forEach((key, value) {
        if (key != 'id' && key != 'createdAt') {
          merged[key] = value;
        }
      });
    }
    
    return merged;
  }

  /// Extract timestamp from data
  DateTime _extractTimestamp(Map<String, dynamic> data) {
    final updatedAt = data['updatedAt'];
    if (updatedAt is String) {
      return DateTime.tryParse(updatedAt) ?? DateTime.fromMillisecondsSinceEpoch(0);
    } else if (updatedAt is int) {
      return DateTime.fromMillisecondsSinceEpoch(updatedAt);
    }
    
    // Fall back to createdAt
    final createdAt = data['createdAt'];
    if (createdAt is String) {
      return DateTime.tryParse(createdAt) ?? DateTime.fromMillisecondsSinceEpoch(0);
    } else if (createdAt is int) {
      return DateTime.fromMillisecondsSinceEpoch(createdAt);
    }
    
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  /// Get maximum of two numeric values
  num _max(a, b) {
    final numA = (a is num) ? a : 0;
    final numB = (b is num) ? b : 0;
    return numA > numB ? numA : numB;
  }

  /// Detect conflicts between local and remote data
  List<DataConflict> detectConflicts(
    List<Map<String, dynamic>> localData,
    List<Map<String, dynamic>> remoteData,
  ) {
    final conflicts = <DataConflict>[];
    final remoteMap = <String, Map<String, dynamic>>{};
    
    // Create map of remote data by ID
    for (final item in remoteData) {
      final id = item['id'] as String?;
      if (id != null) {
        remoteMap[id] = item;
      }
    }
    
    // Check for conflicts
    for (final localItem in localData) {
      final id = localItem['id'] as String?;
      if (id != null && remoteMap.containsKey(id)) {
        final remoteItem = remoteMap[id]!;
        
        if (_hasConflict(localItem, remoteItem)) {
          conflicts.add(DataConflict(
            entityId: id,
            entityType: localItem['entityType'] ?? 'unknown',
            localData: localItem,
            remoteData: remoteItem,
            resolutionStrategy: _determineResolutionStrategy(localItem, remoteItem),
          ));
        }
      }
    }
    
    return conflicts;
  }

  /// Check if two data items have conflicts
  bool _hasConflict(Map<String, dynamic> local, Map<String, dynamic> remote) {
    final localTimestamp = _extractTimestamp(local);
    final remoteTimestamp = _extractTimestamp(remote);
    
    // If timestamps are the same, check if data is different
    if (localTimestamp == remoteTimestamp) {
      return !_deepEquals(local, remote);
    }
    
    // If timestamps are different, there might be a conflict
    // Check if both have been modified since last sync
    return (localTimestamp != remoteTimestamp) && _deepEquals(local, remote) == false;
  }

  /// Deep equality check for maps
  bool _deepEquals(Map<String, dynamic> a, Map<String, dynamic> b) {
    if (a.length != b.length) return false;
    
    for (final key in a.keys) {
      if (!b.containsKey(key)) return false;
      
      final valueA = a[key];
      final valueB = b[key];
      
      if (valueA is Map && valueB is Map) {
        if (!_deepEquals(Map<String, dynamic>.from(valueA), Map<String, dynamic>.from(valueB))) {
          return false;
        }
      } else if (valueA is List && valueB is List) {
        if (valueA.length != valueB.length) return false;
        for (var i = 0; i < valueA.length; i++) {
          if (valueA[i] != valueB[i]) return false;
        }
      } else if (valueA != valueB) {
        return false;
      }
    }
    
    return true;
  }

  /// Determine the best resolution strategy for a conflict
  ConflictResolutionStrategy _determineResolutionStrategy(
    Map<String, dynamic> local,
    Map<String, dynamic> remote,
  ) {
    final entityType = local['entityType'] ?? remote['entityType'];
    
    switch (entityType) {
      case 'task':
        // For tasks, prefer merging to preserve completion status and streaks
        return ConflictResolutionStrategy.merge;
      case 'avatar':
        // For avatars, prefer merging to keep highest values
        return ConflictResolutionStrategy.merge;
      case 'achievement':
        // For achievements, prefer merging to keep unlock status
        return ConflictResolutionStrategy.merge;
      case 'progress':
        // For progress, prefer merging to sum values
        return ConflictResolutionStrategy.merge;
      default:
        // For other types, use last write wins
        return ConflictResolutionStrategy.lastWriteWins;
    }
  }
}

/// Represents a data conflict between local and remote data
class DataConflict {

  const DataConflict({
    required this.entityId,
    required this.entityType,
    required this.localData,
    required this.remoteData,
    required this.resolutionStrategy,
  });
  final String entityId;
  final String entityType;
  final Map<String, dynamic> localData;
  final Map<String, dynamic> remoteData;
  final ConflictResolutionStrategy resolutionStrategy;

  @override
  String toString() => 'DataConflict(id: $entityId, type: $entityType, strategy: $resolutionStrategy)';
}

/// Result of conflict resolution
class ConflictResolution {

  const ConflictResolution({
    required this.resolvedData,
    required this.resolution,
    required this.reason,
  });
  final Map<String, dynamic> resolvedData;
  final ConflictResolutionType resolution;
  final String reason;

  @override
  String toString() => 'ConflictResolution(resolution: $resolution, reason: $reason)';
}

/// Strategies for resolving conflicts
enum ConflictResolutionStrategy {
  lastWriteWins,
  localWins,
  remoteWins,
  merge,
  userChoice,
}

/// Types of conflict resolution
enum ConflictResolutionType {
  useLocal,
  useRemote,
  merged,
  userSelected,
}