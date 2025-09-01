import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../shared/services/firebase_sync_service.dart';
import '../../../shared/widgets/sync_status_widget.dart';
import '../widgets/backup_list_sheet.dart';

/// Screen for managing cloud synchronization settings and status
class SyncManagementScreen extends StatefulWidget {
  const SyncManagementScreen({super.key});

  @override
  State<SyncManagementScreen> createState() => _SyncManagementScreenState();
}

class _SyncManagementScreenState extends State<SyncManagementScreen> {
  bool _autoSyncEnabled = true;
  bool _syncOnMeteredConnection = false;
  bool _showDetailedStatus = true;
  List<BackupInfo> _backups = [];
  bool _isLoadingBackups = false;

  @override
  void initState() {
    super.initState();
    _loadBackups();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sync Management'),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sync status indicator
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sync Status',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const SyncStatusWidget(showDetails: true),
                    const SizedBox(height: 16),
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: () => _triggerSync(context),
                        icon: const Icon(Icons.sync),
                        label: const Text('Sync Now'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Sync settings
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sync Settings',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Auto Sync'),
                      subtitle: const Text('Automatically sync data when online'),
                      value: _autoSyncEnabled,
                      onChanged: (value) {
                        setState(() {
                          _autoSyncEnabled = value;
                        });
                        // TODO: Implement auto sync setting persistence
                      },
                    ),
                    SwitchListTile(
                      title: const Text('Sync on Metered Connections'),
                      subtitle: const Text('Allow syncing when using mobile data'),
                      value: _syncOnMeteredConnection,
                      onChanged: (value) {
                        setState(() {
                          _syncOnMeteredConnection = value;
                        });
                        // TODO: Implement metered connection setting persistence
                      },
                    ),
                    SwitchListTile(
                      title: const Text('Show Detailed Status'),
                      subtitle: const Text('Display detailed sync progress information'),
                      value: _showDetailedStatus,
                      onChanged: (value) {
                        setState(() {
                          _showDetailedStatus = value;
                        });
                        // TODO: Implement detailed status setting persistence
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Backup and restore
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Backup & Restore',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      leading: Icon(
                        Icons.backup,
                        color: colorScheme.primary,
                      ),
                      title: const Text('Create Backup'),
                      subtitle: const Text('Backup your data to the cloud'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _createBackup(context),
                    ),
                    const Divider(),
                    ListTile(
                      leading: Icon(
                        Icons.restore,
                        color: colorScheme.primary,
                      ),
                      title: const Text('Restore from Latest Backup'),
                      subtitle: const Text('Restore your data from the latest cloud backup'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _restoreFromBackup(context),
                    ),
                    const Divider(),
                    ListTile(
                      leading: Icon(
                        Icons.history,
                        color: colorScheme.primary,
                      ),
                      title: const Text('View All Backups'),
                      subtitle: const Text('Manage your cloud backups'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showBackupList(context),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Sync history
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sync History',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // TODO: Implement sync history display
                    const Center(
                      child: Text(
                        'Sync history will appear here',
                        style: TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Trigger manual sync
  void _triggerSync(BuildContext context) {
    final syncService = context.read<FirebaseSyncService>();
    syncService.syncWithRetry().catchError((error) {
      // Error will be shown through the sync status stream
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync failed: $error'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
      return SyncResult(); // Return empty result on error
    }).then((result) {
      if (result.isSuccessful && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sync completed successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    });
  }

  /// Create backup
  void _createBackup(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Backup'),
        content: const Text('This will create a backup of all your data to the cloud. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              final syncService = context.read<FirebaseSyncService>();
              _performBackup(context, syncService);
            },
            child: const Text('Backup'),
          ),
        ],
      ),
    );
  }

  /// Perform backup operation
  void _performBackup(BuildContext context, FirebaseSyncService syncService) {
    final localContext = context;
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Creating backup...'),
          ],
        ),
      ),
    );

    syncService.backupUserData().then((_) {
      if (localContext.mounted) {
        Navigator.of(localContext).pop(); // Dismiss loading dialog
        ScaffoldMessenger.of(localContext).showSnackBar(
          const SnackBar(
            content: Text('Backup created successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }).catchError((error) {
      if (localContext.mounted) {
        Navigator.of(localContext).pop(); // Dismiss loading dialog
        ScaffoldMessenger.of(localContext).showSnackBar(
          SnackBar(
            content: Text('Backup failed: $error'),
            backgroundColor: Theme.of(localContext).colorScheme.error,
          ),
        );
      }
    });
  }

  /// Restore from backup
  void _restoreFromBackup(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore from Backup'),
        content: const Text('This will restore all your data from the latest cloud backup. '
            'Your current data will be replaced. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              final syncService = context.read<FirebaseSyncService>();
              _performRestore(context, syncService);
            },
            child: const Text('Restore'),
          ),
        ],
      ),
    );
  }

  /// Perform restore operation
  void _performRestore(BuildContext context, FirebaseSyncService syncService) {
    final localContext = context;
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Restoring from backup...'),
          ],
        ),
      ),
    );

    syncService.restoreUserData().then((_) {
      if (localContext.mounted) {
        Navigator.of(localContext).pop(); // Dismiss loading dialog
        ScaffoldMessenger.of(localContext).showSnackBar(
          const SnackBar(
            content: Text('Data restored successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }).catchError((error) {
      if (localContext.mounted) {
        Navigator.of(localContext).pop(); // Dismiss loading dialog
        ScaffoldMessenger.of(localContext).showSnackBar(
          SnackBar(
            content: Text('Restore failed: $error'),
            backgroundColor: Theme.of(localContext).colorScheme.error,
          ),
        );
      }
    });
  }

  /// Show backup list
  void _showBackupList(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => BackupListSheet(
        backups: _backups,
        isLoading: _isLoadingBackups,
        onRefresh: _loadBackups,
        onRestore: (backupId) => _restoreFromSpecificBackup(context, backupId),
      ),
    );
  }

  /// Restore from specific backup
  void _restoreFromSpecificBackup(BuildContext context, String backupId) {
    Navigator.of(context).pop(); // Close the bottom sheet
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore from Backup'),
        content: const Text('This will restore all your data from the selected cloud backup. '
            'Your current data will be replaced. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              final syncService = context.read<FirebaseSyncService>();
              _performSpecificRestore(context, syncService, backupId);
            },
            child: const Text('Restore'),
          ),
        ],
      ),
    );
  }

  /// Perform restore from specific backup
  void _performSpecificRestore(BuildContext context, FirebaseSyncService syncService, String backupId) {
    final localContext = context;
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Restoring from backup...'),
          ],
        ),
      ),
    );

    syncService.restoreUserData(backupId: backupId).then((_) {
      if (localContext.mounted) {
        Navigator.of(localContext).pop(); // Dismiss loading dialog
        ScaffoldMessenger.of(localContext).showSnackBar(
          const SnackBar(
            content: Text('Data restored successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }).catchError((error) {
      if (localContext.mounted) {
        Navigator.of(localContext).pop(); // Dismiss loading dialog
        ScaffoldMessenger.of(localContext).showSnackBar(
          SnackBar(
            content: Text('Restore failed: $error'),
            backgroundColor: Theme.of(localContext).colorScheme.error,
          ),
        );
      }
    });
  }

  /// Load available backups
  void _loadBackups() async {
    setState(() {
      _isLoadingBackups = true;
    });

    try {
      final syncService = context.read<FirebaseSyncService>();
      final backups = await syncService.getAvailableBackups();
      if (mounted) {
        setState(() {
          _backups = backups;
          _isLoadingBackups = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingBackups = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load backups: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}