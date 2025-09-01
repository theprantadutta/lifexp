import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../shared/services/firebase_sync_service.dart';

/// Widget that displays a list of backups in a bottom sheet
class BackupListSheet extends StatelessWidget {
  const BackupListSheet({
    super.key,
    required this.backups,
    required this.isLoading,
    required this.onRefresh,
    required this.onRestore,
  });

  final List<BackupInfo> backups;
  final bool isLoading;
  final VoidCallback onRefresh;
  final Function(String) onRestore;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Backups',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: onRefresh,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : backups.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.backup_outlined,
                              size: 48,
                              color: colorScheme.outline,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No backups found',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: colorScheme.outline,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Create a backup to get started',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.outline.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: backups.length,
                        itemBuilder: (context, index) {
                          final backup = backups[index];
                          return _BackupItem(
                            backup: backup,
                            onTap: () => onRestore(backup.id),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

/// Widget that displays a single backup item
class _BackupItem extends StatelessWidget {
  const _BackupItem({
    required this.backup,
    required this.onTap,
  });

  final BackupInfo backup;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          DateFormat('MMM d, yyyy \'at\' h:mm a').format(backup.createdAt),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${backup.totalEntities} entities',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Version: ${backup.version}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
        trailing: Icon(
          Icons.restore,
          color: colorScheme.primary,
        ),
        onTap: onTap,
      ),
    );
  }
}