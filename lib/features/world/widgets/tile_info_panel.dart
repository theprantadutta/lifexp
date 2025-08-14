import 'package:flutter/material.dart';

import '../../../data/models/world.dart';

/// Panel showing information about a selected world tile
class TileInfoPanel extends StatelessWidget {
  const TileInfoPanel({
    required this.tile, super.key,
    this.onClose,
    this.onUnlock,
  });

  final WorldTile tile;
  final VoidCallback? onClose;
  final VoidCallback? onUnlock;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with close button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                tile.name,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: onClose,
                icon: Icon(
                  Icons.close,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Tile type and status
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _getTileTypeColor(context).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  tile.type.name.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: _getTileTypeColor(context),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: tile.isUnlocked
                      ? colorScheme.primary.withValues(alpha: 0.2)
                      : colorScheme.outline.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  tile.isUnlocked ? 'UNLOCKED' : 'LOCKED',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: tile.isUnlocked
                        ? colorScheme.primary
                        : colorScheme.outline,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Description
          if (tile.description.isNotEmpty) ...[
            Text(
              tile.description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Unlock requirements
          if (!tile.isUnlocked) ...[
            Text(
              'Unlock Requirements',
              style: theme.textTheme.titleSmall?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.stars,
                    color: colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${tile.unlockRequirement} XP required',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Custom Properties
          if (tile.customProperties.isNotEmpty) ...[
            Text(
              'Properties',
              style: theme.textTheme.titleSmall?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...tile.customProperties.entries.map((entry) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: colorScheme.secondary,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${entry.key}: ${entry.value}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            )),
            const SizedBox(height: 16),
          ],

          // Action button
          if (!tile.isUnlocked && onUnlock != null)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onUnlock,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Unlock Tile'),
              ),
            ),
        ],
      ),
    );
  }

  Color _getTileTypeColor(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    switch (tile.type) {
      case TileType.forest:
        return Colors.green;
      case TileType.mountain:
        return Colors.brown;
      case TileType.water:
        return Colors.blue;
      case TileType.desert:
        return Colors.orange;
      case TileType.city:
        return colorScheme.secondary;
      case TileType.special:
        return colorScheme.tertiary;
      case TileType.building:
        return Colors.grey;
      case TileType.grass:
        return Colors.lightGreen;
    }
  }
}
 