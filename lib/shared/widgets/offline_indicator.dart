import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../services/offline_data_manager.dart';

/// Widget that displays offline status and sync information
class OfflineIndicator extends StatelessWidget {

  const OfflineIndicator({
    required this.child, super.key,
    this.showSyncStatus = true,
    this.padding = const EdgeInsets.all(8),
  });
  final Widget child;
  final bool showSyncStatus;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => StreamBuilder<bool>(
      stream: context.read<OfflineDataManager>().connectionStream,
      builder: (context, connectionSnapshot) {
        final isOnline = connectionSnapshot.data ?? true;
        
        return StreamBuilder<List<SyncOperation>>(
          stream: context.read<OfflineDataManager>().syncQueueStream,
          builder: (context, syncSnapshot) {
            final syncQueue = syncSnapshot.data ?? [];
            final hasPendingSync = syncQueue.isNotEmpty;
            
            return Column(
              children: [
                if (!isOnline || (showSyncStatus && hasPendingSync))
                  _buildStatusBanner(context, isOnline, syncQueue.length),
                Expanded(child: child),
              ],
            );
          },
        );
      },
    );

  Widget _buildStatusBanner(BuildContext context, bool isOnline, int pendingCount) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    Color backgroundColor;
    Color textColor;
    IconData icon;
    String message;
    
    if (!isOnline) {
      backgroundColor = colorScheme.error.withValues(alpha: 0.1);
      textColor = colorScheme.error;
      icon = Icons.cloud_off;
      message = pendingCount > 0 
          ? 'Offline - $pendingCount changes will sync when connected'
          : "You're offline - changes will sync when connected";
    } else if (pendingCount > 0) {
      backgroundColor = colorScheme.primary.withValues(alpha: 0.1);
      textColor = colorScheme.primary;
      icon = Icons.sync;
      message = 'Syncing $pendingCount changes...';
    } else {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(
          bottom: BorderSide(
            color: textColor.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: textColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (!isOnline && pendingCount > 0)
            TextButton(
              onPressed: () => _showSyncDetails(context, pendingCount),
              style: TextButton.styleFrom(
                foregroundColor: textColor,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(0, 32),
              ),
              child: const Text('Details'),
            ),
        ],
      ),
    );
  }

  void _showSyncDetails(BuildContext context, int pendingCount) {
    showDialog(
      context: context,
      builder: (context) => const SyncDetailsDialog(),
    );
  }
}

/// Dialog showing detailed sync information
class SyncDetailsDialog extends StatelessWidget {
  const SyncDetailsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final offlineManager = context.read<OfflineDataManager>();
    
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.sync_problem,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          const Text('Sync Status'),
        ],
      ),
      content: StreamBuilder<List<SyncOperation>>(
        stream: offlineManager.syncQueueStream,
        builder: (context, snapshot) {
          final syncQueue = snapshot.data ?? [];
          
          if (syncQueue.isEmpty) {
            return const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 48),
                SizedBox(height: 16),
                Text('All changes are synced!'),
              ],
            );
          }
          
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pending changes: ${syncQueue.length}',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 200),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: syncQueue.length,
                  itemBuilder: (context, index) {
                    final operation = syncQueue[index];
                    return _buildSyncOperationTile(context, operation);
                  },
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Changes will sync automatically when you're back online.",
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          );
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
        StreamBuilder<bool>(
          stream: offlineManager.connectionStream,
          builder: (context, snapshot) {
            final isOnline = snapshot.data ?? false;
            
            return TextButton(
              onPressed: isOnline
                  ? () async {
                      await offlineManager.forceSyncAll();
                      if (context.mounted) {
                        Navigator.of(context).pop();
                      }
                    }
                  : null,
              child: const Text('Sync Now'),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSyncOperationTile(BuildContext context, SyncOperation operation) {
    final theme = Theme.of(context);
    
    IconData icon;
    Color iconColor;
    
    switch (operation.operationType) {
      case SyncOperationType.create:
        icon = Icons.add_circle_outline;
        iconColor = Colors.green;
        break;
      case SyncOperationType.update:
        icon = Icons.edit_outlined;
        iconColor = Colors.blue;
        break;
      case SyncOperationType.delete:
        icon = Icons.delete_outline;
        iconColor = Colors.red;
        break;
    }
    
    return ListTile(
      dense: true,
      leading: Icon(icon, color: iconColor, size: 20),
      title: Text(
        '${operation.operationType.name.toUpperCase()} ${operation.entityType}',
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ID: ${operation.entityId}',
            style: theme.textTheme.bodySmall,
          ),
          if (operation.retryCount > 0)
            Text(
              'Retries: ${operation.retryCount}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.orange,
              ),
            ),
          if (operation.lastError != null)
            Text(
              'Error: ${operation.lastError}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.red,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
      trailing: Text(
        _formatTimestamp(operation.timestamp),
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}

/// Simple offline status indicator for app bars
class SimpleOfflineIndicator extends StatelessWidget {
  const SimpleOfflineIndicator({super.key});

  @override
  Widget build(BuildContext context) => StreamBuilder<bool>(
      stream: context.read<OfflineDataManager>().connectionStream,
      builder: (context, snapshot) {
        final isOnline = snapshot.data ?? true;
        
        if (isOnline) {
          return const SizedBox.shrink();
        }
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.error.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.error.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cloud_off,
                size: 14,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(width: 4),
              Text(
                'Offline',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
}

/// Mixin for widgets that need offline-aware behavior
mixin OfflineAwareMixin<T extends StatefulWidget> on State<T> {
  late OfflineDataManager _offlineManager;
  bool _isOnline = true;
  
  @override
  void initState() {
    super.initState();
    _offlineManager = context.read<OfflineDataManager>();
    _isOnline = _offlineManager.isOnline;
    
    _offlineManager.connectionStream.listen((isOnline) {
      if (mounted && _isOnline != isOnline) {
        setState(() {
          _isOnline = isOnline;
        });
        onConnectionChanged(isOnline);
      }
    });
  }
  
  /// Called when connection status changes
  void onConnectionChanged(bool isOnline) {}
  
  /// Whether the device is currently online
  bool get isOnline => _isOnline;
  
  /// Queue a sync operation for when online
  Future<void> queueSyncOperation(SyncOperation operation) => _offlineManager.queueSyncOperation(operation);
  
  /// Show offline message to user
  void showOfflineMessage([String? customMessage]) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          customMessage ?? "You're offline. Changes will sync when connected.",
        ),
        backgroundColor: Theme.of(context).colorScheme.error.withValues(alpha: 0.9),
        action: SnackBarAction(
          label: 'Details',
          textColor: Colors.white,
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => const SyncDetailsDialog(),
            );
          },
        ),
      ),
    );
  }
}