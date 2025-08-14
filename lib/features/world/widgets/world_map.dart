import 'package:flutter/material.dart';

import '../../../data/models/world.dart';

/// Interactive world map widget with zoom and pan functionality
class WorldMap extends StatefulWidget {
  const WorldMap({
    required this.tiles,
    required this.onTileSelected,
    this.selectedTile,
    super.key,
  });

  final List<WorldTile> tiles;
  final Function(WorldTile) onTileSelected;
  final WorldTile? selectedTile;

  @override
  State<WorldMap> createState() => _WorldMapState();
}

class _WorldMapState extends State<WorldMap> {
  final TransformationController _transformationController =
      TransformationController();
  
  static const int gridSize = 20; // 20x20 grid
  static const double tileSize = 40;
  static const double spacing = 2;

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              Theme.of(context).colorScheme.surface,
            ],
          ),
        ),
        child: InteractiveViewer(
          transformationController: _transformationController,
          minScale: 0.5,
          maxScale: 3,
          constrained: false,
          child: Container(
            width: gridSize * (tileSize + spacing),
            height: gridSize * (tileSize + spacing),
            padding: const EdgeInsets.all(20),
            child: _buildGrid(),
          ),
        ),
      );

  Widget _buildGrid() => GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: gridSize,
          mainAxisSpacing: spacing,
          crossAxisSpacing: spacing,
        ),
        itemCount: gridSize * gridSize,
        itemBuilder: (context, index) {
          final x = index % gridSize;
          final y = index ~/ gridSize;
          final tile = _getTileAt(x, y);
          
          return _buildTile(tile, x, y);
        },
      );

  Widget _buildTile(WorldTile? tile, int x, int y) {
    final isSelected = tile != null && tile == widget.selectedTile;
    final isEmpty = tile == null;
    
    if (isEmpty) {
      return _buildEmptyTile(x, y);
    }

    return GestureDetector(
      onTap: () => widget.onTileSelected(tile),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: _getTileColor(tile),
          borderRadius: BorderRadius.circular(4),
          border: isSelected
              ? Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                )
              : null,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.3),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ]
              : tile.isUnlocked
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 2,
                        offset: const Offset(1, 1),
                      ),
                    ]
                  : null,
        ),
        child: Stack(
          children: [
            // Base tile content
            Center(
              child: _buildTileContent(tile),
            ),
            
            // Unlock overlay for locked tiles
            if (!tile.isUnlocked)
              DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Center(
                  child: Icon(
                    Icons.lock,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            
            // Selection indicator
            if (isSelected)
              Positioned(
                top: 2,
                right: 2,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyTile(int x, int y) => DecoratedBox(
        decoration: BoxDecoration(
          color: _getTerrainColor(x, y),
          borderRadius: BorderRadius.circular(2),
        ),
        child: Center(
          child: Icon(
            _getTerrainIcon(x, y),
            size: 12,
            color: Colors.white.withValues(alpha: 0.3),
          ),
        ),
      );

  Widget _buildTileContent(WorldTile tile) {
    if (!tile.isUnlocked) {
      return Icon(
        _getTileTypeIcon(tile.type),
        size: 16,
        color: Colors.white.withValues(alpha: 0.5),
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          _getTileTypeIcon(tile.type),
          size: 16,
          color: Colors.white,
        ),
        if (tile.isUnlocked)
          Container(
            margin: const EdgeInsets.only(top: 2),
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
            child: const Text(
              '✓',
              style: TextStyle(
                color: Colors.white,
                fontSize: 8,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  WorldTile? _getTileAt(int x, int y) => widget.tiles
      .where((tile) => tile.positionX == x && tile.positionY == y)
      .firstOrNull;

  Color _getTileColor(WorldTile tile) {
    if (!tile.isUnlocked) {
      return _getTileTypeColor(tile.type).withValues(alpha: 0.3);
    }

    final baseColor = _getTileTypeColor(tile.type);
    
    // Brighten color based on unlock status
    final levelMultiplier = tile.isUnlocked ? 1.2 : 0.6;
    return Color.lerp(
      baseColor,
      Colors.white,
      (levelMultiplier - 1.0).clamp(0.0, 0.3),
    )!;
  }

  Color _getTileTypeColor(TileType type) {
    switch (type) {
      case TileType.grass:
        return Colors.lightGreen.shade400;
      case TileType.forest:
        return Colors.green.shade600;
      case TileType.mountain:
        return Colors.grey.shade600;
      case TileType.water:
        return Colors.blue.shade600;
      case TileType.desert:
        return Colors.orange.shade600;
      case TileType.city:
        return Colors.purple.shade600;
      case TileType.building:
        return Colors.brown.shade600;
      case TileType.special:
        return Colors.red.shade600;
    }
  }

  IconData _getTileTypeIcon(TileType type) {
    switch (type) {
      case TileType.grass:
        return Icons.grass;
      case TileType.forest:
        return Icons.park;
      case TileType.mountain:
        return Icons.terrain;
      case TileType.water:
        return Icons.water;
      case TileType.desert:
        return Icons.wb_sunny;
      case TileType.city:
        return Icons.location_city;
      case TileType.building:
        return Icons.business;
      case TileType.special:
        return Icons.star;
    }
  }

  Color _getTerrainColor(int x, int y) {
    // Create varied terrain based on position
    final hash = (x * 31 + y * 17) % 100;
    
    if (hash < 30) {
      return Colors.green.shade300; // Grass
    } else if (hash < 50) {
      return Colors.brown.shade300; // Dirt
    } else if (hash < 70) {
      return Colors.grey.shade400; // Stone
    } else {
      return Colors.blue.shade200; // Water
    }
  }

  IconData _getTerrainIcon(int x, int y) {
    final hash = (x * 31 + y * 17) % 100;
    
    if (hash < 30) {
      return Icons.grass;
    } else if (hash < 50) {
      return Icons.circle;
    } else if (hash < 70) {
      return Icons.square;
    } else {
      return Icons.water_drop;
    }
  }
}