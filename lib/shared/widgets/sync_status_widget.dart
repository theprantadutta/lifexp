import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../services/firebase_sync_service.dart';

/// Widget that displays Firebase sync status
class SyncStatusWidget extends StatelessWidget {

  const SyncStatusWidget({
    super.key,
    this.showDetails = false,
    this.padding = const EdgeInsets.all(8),
  });
  final bool showDetails;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => StreamBuilder<SyncStatus>(
      stream: context.read<FirebaseSyncService>().syncStatusStream,
      builder: (context, snapshot) {
        final status = snapshot.data;
        
        if (status == null || status.isIdle) {
          return const SizedBox.shrink();
        }
        
        return Container(
          width: double.infinity,
          padding: padding,
          decoration: BoxDecoration(
            color: _getStatusColor(context, status).withValues(alpha: 0.1),
            border: Border(
              bottom: BorderSide(
                color: _getStatusColor(context, status).withValues(alpha: 0.2),
              ),
            ),
          ),
          child: Row(
            children: [
              _buildStatusIcon(context, status),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      status.message,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: _getStatusColor(context, status),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (showDetails && status.progress != null)
                      LinearProgressIndicator(
                        value: status.progress,
                        backgroundColor: _getStatusColor(context, status).withValues(alpha: 0.2),
                        valueColor: AlwaysStoppedAnimation(_getStatusColor(context, status)),
                      ),
                    if (showDetails && status.result != null)
                      Text(
                        _getResultSummary(status.result!),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: _getStatusColor(context, status).withValues(alpha: 0.7),
                        ),
                      ),
                  ],
                ),
              ),
              if (status.isError)
                TextButton(
                  onPressed: () => _showErrorDetails(context, status),
                  style: TextButton.styleFrom(
                    foregroundColor: _getStatusColor(context, status),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(0, 32),
                  ),
                  child: const Text('Details'),
                ),
            ],
          ),
        );
      },
    );

  Widget _buildStatusIcon(BuildContext context, SyncStatus status) {
    IconData icon;
    
    switch (status.state) {
      case SyncState.syncing:
        return SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation(_getStatusColor(context, status)),
          ),
        );
      case SyncState.completed:
        icon = Icons.check_circle;
        break;
      case SyncState.error:
        icon = Icons.error;
        break;
      case SyncState.idle:
        icon = Icons.cloud_done;
        break;
    }
    
    return Icon(
      icon,
      size: 16,
      color: _getStatusColor(context, status),
    );
  }

  Color _getStatusColor(BuildContext context, SyncStatus status) {
    final colorScheme = Theme.of(context).colorScheme;
    
    switch (status.state) {
      case SyncState.syncing:
        return colorScheme.primary;
      case SyncState.completed:
        return Colors.green;
      case SyncState.error:
        return colorScheme.error;
      case SyncState.idle:
        return colorScheme.onSurface.withValues(alpha: 0.6);
    }
  }

  String _getResultSummary(SyncResult result) {
    final parts = <String>[];
    
    if (result.totalUploaded > 0) {
      parts.add('↑${result.totalUploaded}');
    }
    if (result.totalDownloaded > 0) {
      parts.add('↓${result.totalDownloaded}');
    }
    if (result.totalConflicts > 0) {
      parts.add('⚠${result.totalConflicts}');
    }
    
    return parts.join(' ');
  }

  void _showErrorDetails(BuildContext context, SyncStatus status) {
    showDialog(
      context: context,
      builder: (context) => SyncErrorDialog(status: status),
    );
  }
}

/// Dialog showing sync error details
class SyncErrorDialog extends StatelessWidget {

  const SyncErrorDialog({
    required this.status, super.key,
  });
  final SyncStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.error,
            color: theme.colorScheme.error,
          ),
          const SizedBox(width: 8),
          const Text('Sync Error'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            status.message,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          if (status.error != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colorScheme.error.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                status.error!,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                ),
              ),
            ),
          const SizedBox(height: 16),
          Text(
            'The app will continue to work offline. Sync will be retried automatically when the connection improves.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            _retrySync(context);
          },
          child: const Text('Retry'),
        ),
      ],
    );
  }

  void _retrySync(BuildContext context) {
    final syncService = context.read<FirebaseSyncService>();
    syncService.syncWithRetry().catchError((error) {
      // Error will be shown through the sync status stream
      return SyncResult(); // Return empty result on error
    });
  }
}

/// Simple sync status indicator for app bars
class SimpleSyncStatusIndicator extends StatelessWidget {
  const SimpleSyncStatusIndicator({super.key});

  @override
  Widget build(BuildContext context) => StreamBuilder<SyncStatus>(
      stream: context.read<FirebaseSyncService>().syncStatusStream,
      builder: (context, snapshot) {
        final status = snapshot.data;
        
        if (status == null || status.isIdle) {
          return const SizedBox.shrink();
        }
        
        Color color;
        IconData icon;
        
        switch (status.state) {
          case SyncState.syncing:
            color = Theme.of(context).colorScheme.primary;
            icon = Icons.sync;
            break;
          case SyncState.completed:
            color = Colors.green;
            icon = Icons.cloud_done;
            break;
          case SyncState.error:
            color = Theme.of(context).colorScheme.error;
            icon = Icons.cloud_off;
            break;
          case SyncState.idle:
            return const SizedBox.shrink();
        }
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (status.isSyncing)
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                )
              else
                Icon(
                  icon,
                  size: 14,
                  color: color,
                ),
              const SizedBox(width: 4),
              Text(
                _getStatusText(status),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );

  String _getStatusText(SyncStatus status) {
    switch (status.state) {
      case SyncState.syncing:
        return 'Syncing';
      case SyncState.completed:
        return 'Synced';
      case SyncState.error:
        return 'Sync Error';
      case SyncState.idle:
        return 'Ready';
    }
  }
}

/// Floating action button with sync functionality
class SyncFloatingActionButton extends StatelessWidget {

  const SyncFloatingActionButton({
    super.key,
    this.onPressed,
    this.tooltip,
  });
  final VoidCallback? onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) => StreamBuilder<SyncStatus>(
      stream: context.read<FirebaseSyncService>().syncStatusStream,
      builder: (context, snapshot) {
        final status = snapshot.data;
        final isSyncing = status?.isSyncing ?? false;
        
        return FloatingActionButton(
          onPressed: isSyncing ? null : (onPressed ?? () => _triggerSync(context)),
          tooltip: tooltip ?? 'Sync with cloud',
          child: isSyncing
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                )
              : const Icon(Icons.cloud_sync),
        );
      },
    );

  void _triggerSync(BuildContext context) {
    final syncService = context.read<FirebaseSyncService>();
    syncService.syncWithRetry().catchError((error) {
      // Error will be shown through the sync status stream
      return SyncResult(); // Return empty result on error
    });
  }
}