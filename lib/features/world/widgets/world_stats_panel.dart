import 'package:flutter/material.dart';

import '../../../data/models/world_tile.dart';

/// Panel showing world statistics and progress
class WorldStatsPanel extends StatelessWidget {
  const WorldStatsPanel({
    required this.tiles, required this.currentXP, required this.categoryProgress, super.key,
  });

  final List<WorldTile> tiles;
  final int currentXP;
  final Map<String, int> categoryProgress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final unlockedTiles = tiles.where((tile) => tile.isUnlocked).length;
    final totalTiles = tiles.length;
    final progressPercentage = totalTiles > 0 ? (unlockedTiles / totalTiles) : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'World Progress',
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Overall progress
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Tiles Unlocked',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          '$unlockedTiles / $totalTiles',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: progressPercentage,
                      backgroundColor: colorScheme.outline.withValues(alpha: 0.3),
                      valueColor: AlwaysStoppedAnimation(colorScheme.primary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Stats grid
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  context,
                  'Current XP',
                  currentXP.toString(),
                  Icons.stars,
                  colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  context,
                  'Progress',
                  '${(progressPercentage * 100).toInt()}%',
                  Icons.trending_up,
                  colorScheme.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Tile type breakdown
          if (tiles.isNotEmpty) ...[
            Text(
              'Tile Types',
              style: theme.textTheme.titleSmall?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: TileType.values.map((type) {
                final count = tiles.where((tile) => tile.type == type).length;
                final unlockedCount = tiles
                    .where((tile) => tile.type == type && tile.isUnlocked)
                    .length;
                
                if (count == 0) return const SizedBox.shrink();
                
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getTileTypeColor(type).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${type.name.toUpperCase()}: $unlockedCount/$count',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: _getTileTypeColor(type),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _getTileTypeColor(TileType type) {
    switch (type) {
      case TileType.forest:
        return Colors.green;
      case TileType.mountain:
        return Colors.brown;
      case TileType.water:
        return Colors.blue;
      case TileType.desert:
        return Colors.orange;
      case TileType.city:
        return Colors.grey;
      case TileType.special:
        return Colors.purple;
    }
  }
}