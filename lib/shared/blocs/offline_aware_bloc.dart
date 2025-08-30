import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter_bloc/flutter_bloc.dart';
import '../services/offline_data_manager.dart';
import '../services/offline_state_detector.dart';

/// Base BLoC class that provides offline-awareness functionality
abstract class OfflineAwareBloc<Event, State> extends Bloc<Event, State> {

  OfflineAwareBloc(
    super.initialState, {
    OfflineDataManager? offlineManager,
    OfflineStateDetector? stateDetector,
  }) : _offlineManager = offlineManager,
       _stateDetector = stateDetector {
    _initializeOfflineSupport();
  }
  final OfflineDataManager? _offlineManager;
  final OfflineStateDetector? _stateDetector;
  
  StreamSubscription? _connectionSubscription;
  StreamSubscription<List<SyncOperation>>? _syncQueueSubscription;
  
  bool _isOnline = true;
  int _pendingSyncCount = 0;

  /// Whether the device is currently online
  bool get isOnline => _isOnline;
  
  /// Whether the device is currently offline
  bool get isOffline => !_isOnline;
  
  /// Number of pending sync operations
  int get pendingSyncCount => _pendingSyncCount;
  
  /// Whether there are pending sync operations
  bool get hasPendingSync => _pendingSyncCount > 0;

  /// Initialize offline support monitoring
  void _initializeOfflineSupport() {
    // Monitor connection status
    if (_offlineManager != null) {
      _isOnline = _offlineManager.isOnline;
      _connectionSubscription = _offlineManager.connectionStream.listen(
        _onConnectionChanged,
        onError: (error) {
          developer.log('Connection stream error: $error', name: 'OfflineAwareBloc');
        },
      );
      
      // Monitor sync queue
      _pendingSyncCount = _offlineManager.pendingSyncCount;
      _syncQueueSubscription = _offlineManager.syncQueueStream.listen(
        _onSyncQueueChanged,
        onError: (error) {
          developer.log('Sync queue stream error: $error', name: 'OfflineAwareBloc');
        },
      );
    } else if (_stateDetector != null) {
      _connectionSubscription = _stateDetector.stateStream.listen(
        (state) => _onConnectionChanged(state == ConnectionState.online),
        onError: (error) {
          developer.log('State detector stream error: $error', name: 'OfflineAwareBloc');
        },
      );
    }
  }

  /// Called when connection status changes
  void _onConnectionChanged(bool isOnline) {
    final wasOnline = _isOnline;
    _isOnline = isOnline;
    
    if (wasOnline != isOnline) {
      onConnectionStatusChanged(isOnline);
      
      // Trigger sync when coming back online
      if (isOnline && _pendingSyncCount > 0) {
        onBackOnline();
      }
    }
  }

  /// Called when sync queue changes
  void _onSyncQueueChanged(List<SyncOperation> syncQueue) {
    final previousCount = _pendingSyncCount;
    _pendingSyncCount = syncQueue.length;
    
    if (previousCount != _pendingSyncCount) {
      onSyncQueueChanged(_pendingSyncCount);
    }
  }

  /// Override this method to handle connection status changes
  void onConnectionStatusChanged(bool isOnline) {
    // Default implementation - subclasses can override
    developer.log('Connection status changed to ${isOnline ? 'online' : 'offline'}', name: 'OfflineAwareBloc');
  }

  /// Override this method to handle coming back online
  void onBackOnline() {
    // Default implementation - subclasses can override
    developer.log('Back online with $pendingSyncCount pending operations', name: 'OfflineAwareBloc');
  }

  /// Override this method to handle sync queue changes
  void onSyncQueueChanged(int pendingCount) {
    // Default implementation - subclasses can override
    developer.log('Sync queue changed to $pendingCount operations', name: 'OfflineAwareBloc');
  }

  /// Queue a sync operation
  Future<void> queueSyncOperation(SyncOperation operation) async {
    if (_offlineManager != null) {
      try {
        await _offlineManager.queueSyncOperation(operation);
      } catch (e) {
        developer.log('Failed to queue sync operation: $e', name: 'OfflineAwareBloc');
      }
    }
  }

  /// Force sync all pending operations
  Future<void> forceSyncAll() async {
    if (_offlineManager != null && isOnline) {
      try {
        await _offlineManager.forceSyncAll();
      } catch (e) {
        developer.log('Failed to force sync: $e', name: 'OfflineAwareBloc');
      }
    }
  }

  /// Clear all pending sync operations
  Future<void> clearSyncQueue() async {
    if (_offlineManager != null) {
      try {
        await _offlineManager.clearSyncQueue();
      } catch (e) {
        developer.log('Failed to clear sync queue: $e', name: 'OfflineAwareBloc');
      }
    }
  }

  /// Get last sync time
  DateTime? getLastSyncTime() => _offlineManager?.getLastSyncTime();

  /// Check if data is stale
  bool isDataStale({Duration threshold = const Duration(hours: 1)}) => _offlineManager?.isDataStale(threshold: threshold) ?? false;

  /// Handle offline operation with optimistic updates
  Future<T> handleOfflineOperation<T>(
    Future<T> Function() operation, {
    required String operationName,
    SyncOperation? syncOperation,
    T? optimisticResult,
  }) async {
    try {
      // Always try the operation first (works offline with local storage)
      final result = await operation();
      
      // Queue for sync if we have a sync operation
      if (syncOperation != null) {
        await queueSyncOperation(syncOperation);
      }
      
      return result;
    } catch (e) {
      developer.log('$operationName failed: $e', name: 'OfflineAwareBloc');
      
      // If we have an optimistic result and we're offline, return it
      if (optimisticResult != null && isOffline) {
        // Still queue the operation for later sync
        if (syncOperation != null) {
          await queueSyncOperation(syncOperation);
        }
        return optimisticResult;
      }
      
      rethrow;
    }
  }

  /// Show offline message (to be implemented by UI layer)
  void showOfflineMessage(String message) {
    // This would typically be handled by the UI layer
    developer.log('Offline message: $message', name: 'OfflineAwareBloc');
  }

  /// Show sync status message
  void showSyncStatusMessage(String message) {
    // This would typically be handled by the UI layer
    developer.log('Sync status: $message', name: 'OfflineAwareBloc');
  }

  @override
  Future<void> close() {
    _connectionSubscription?.cancel();
    _syncQueueSubscription?.cancel();
    return super.close();
  }
}

/// Mixin for states that need offline information
mixin OfflineStateMixin {
  bool get isOnline;
  int get pendingSyncCount;
  
  bool get isOffline => !isOnline;
  bool get hasPendingSync => pendingSyncCount > 0;
  
  /// Get offline status description
  String get offlineStatusDescription {
    if (isOffline && hasPendingSync) {
      return 'Offline - $pendingSyncCount changes will sync when connected';
    } else if (isOffline) {
      return 'Offline - changes will sync when connected';
    } else if (hasPendingSync) {
      return 'Syncing $pendingSyncCount changes...';
    } else {
      return 'Online and synced';
    }
  }
}

/// Base state class with offline support
abstract class OfflineAwareState with OfflineStateMixin {
  
  const OfflineAwareState({
    this.isOnline = true,
    this.pendingSyncCount = 0,
  });
  @override
  final bool isOnline;
  
  @override
  final int pendingSyncCount;
  
  /// Copy with offline status
  OfflineAwareState copyWithOfflineStatus({
    bool? isOnline,
    int? pendingSyncCount,
  });
}

/// Loading state with offline support
class OfflineLoadingState extends OfflineAwareState {
  
  const OfflineLoadingState({
    this.message,
    super.isOnline,
    super.pendingSyncCount,
  });
  final String? message;
  
  @override
  OfflineLoadingState copyWithOfflineStatus({
    bool? isOnline,
    int? pendingSyncCount,
  }) => OfflineLoadingState(
      message: message,
      isOnline: isOnline ?? this.isOnline,
      pendingSyncCount: pendingSyncCount ?? this.pendingSyncCount,
    );
}

/// Error state with offline support
class OfflineErrorState extends OfflineAwareState {
  
  const OfflineErrorState({
    required this.message,
    this.error,
    this.isRetryable = true,
    super.isOnline,
    super.pendingSyncCount,
  });
  final String message;
  final dynamic error;
  final bool isRetryable;
  
  @override
  OfflineErrorState copyWithOfflineStatus({
    bool? isOnline,
    int? pendingSyncCount,
  }) => OfflineErrorState(
      message: message,
      error: error,
      isRetryable: isRetryable,
      isOnline: isOnline ?? this.isOnline,
      pendingSyncCount: pendingSyncCount ?? this.pendingSyncCount,
    );
}

/// Success state with offline support
class OfflineSuccessState<T> extends OfflineAwareState {
  
  const OfflineSuccessState({
    required this.data,
    this.message,
    super.isOnline,
    super.pendingSyncCount,
  });
  final T data;
  final String? message;
  
  @override
  OfflineSuccessState<T> copyWithOfflineStatus({
    bool? isOnline,
    int? pendingSyncCount,
  }) => OfflineSuccessState<T>(
      data: data,
      message: message,
      isOnline: isOnline ?? this.isOnline,
      pendingSyncCount: pendingSyncCount ?? this.pendingSyncCount,
    );
}