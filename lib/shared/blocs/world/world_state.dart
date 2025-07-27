import 'package:equatable/equatable.dart';

import '../../../data/models/world.dart';
import 'world_event.dart';

/// Base class for all world states
abstract class WorldState extends Equatable {
  const WorldState();

  @override
  List<Object?> get props => [];
}

/// Initial state when no world data is loaded
class WorldInitial extends WorldState {
  const WorldInitial();
}

/// State when world data is being loaded
class WorldLoading extends WorldState {
  const WorldLoading();
}

/// State when world data is successfully loaded
class WorldLoaded extends WorldState {
  const WorldLoaded({
    required this.worldTiles,
    this.filteredTiles,
    this.activeFilter,
    this.sortType = WorldSortType.position,
    this.worldStats = const {},
    this.worldProgression = const [],
    this.worldMapData = const [],
    this.completionPercentage = 0.0,
    this.worldAnalytics = const [],
    this.unlockEligibilityReport = const [],
    this.optimalPlacements = const [],
    this.showTileUnlockNotification = false,
    this.unlockedTile,
    this.showProgressionCelebration = false,
    this.recentUnlocks = const [],
    this.zoomLevel = 1.0,
    this.viewCenterX = 0.0,
    this.viewCenterY = 0.0,
    this.viewOffsetX = 0.0,
    this.viewOffsetY = 0.0,
  });

  final List<WorldTile> worldTiles;
  final List<WorldTile>? filteredTiles;
  final WorldFilter? activeFilter;
  final WorldSortType sortType;
  final Map<String, dynamic> worldStats;
  final List<Map<String, dynamic>> worldProgression;
  final List<Map<String, dynamic>> worldMapData;
  final double completionPercentage;
  final List<Map<String, dynamic>> worldAnalytics;
  final List<Map<String, dynamic>> unlockEligibilityReport;
  final List<Map<String, int>> optimalPlacements;
  final bool showTileUnlockNotification;
  final WorldTile? unlockedTile;
  final bool showProgressionCelebration;
  final List<WorldTile> recentUnlocks;
  final double zoomLevel;
  final double viewCenterX;
  final double viewCenterY;
  final double viewOffsetX;
  final double viewOffsetY;

  /// Gets the world tiles to display (filtered or all)
  List<WorldTile> get displayTiles => filteredTiles ?? worldTiles;

  /// Gets unlocked world tiles
  List<WorldTile> get unlockedTiles =>
      displayTiles.where((tile) => tile.isUnlocked).toList();

  /// Gets locked world tiles
  List<WorldTile> get lockedTiles =>
      displayTiles.where((tile) => !tile.isUnlocked).toList();

  /// Gets tiles by type
  Map<TileType, List<WorldTile>> get tilesByType {
    final Map<TileType, List<WorldTile>> typedTiles = {};
    for (final type in TileType.values) {
      typedTiles[type] = displayTiles
          .where((tile) => tile.type == type)
          .toList();
    }
    return typedTiles;
  }

  /// Gets tiles by unlock category
  Map<String, List<WorldTile>> get tilesByCategory {
    final Map<String, List<WorldTile>> categorizedTiles = {};
    for (final tile in displayTiles) {
      if (tile.unlockCategory != null) {
        final category = tile.unlockCategory!;
        categorizedTiles[category] = (categorizedTiles[category] ?? [])
          ..add(tile);
      }
    }
    return categorizedTiles;
  }

  /// Gets world statistics summary
  WorldStatsSummary get statsSummary {
    final total = worldTiles.length;
    final unlocked = unlockedTiles.length;
    final locked = lockedTiles.length;

    return WorldStatsSummary(
      totalTiles: total,
      unlockedTiles: unlocked,
      lockedTiles: locked,
      completionRate: total > 0 ? unlocked / total : 0.0,
      averageUnlockRequirement: worldTiles.isNotEmpty
          ? worldTiles.fold(0, (sum, tile) => sum + tile.unlockRequirement) /
                worldTiles.length
          : 0.0,
    );
  }

  /// Gets tiles that can be unlocked with current progress
  List<WorldTile> getUnlockableTiles(
    int currentXP,
    Map<String, int> categoryProgress,
  ) {
    return lockedTiles
        .where(
          (tile) => tile.canUnlock(
            currentXP: currentXP,
            categoryProgress: categoryProgress,
          ),
        )
        .toList();
  }

  /// Gets tiles in a specific area
  List<WorldTile> getTilesInArea(int minX, int maxX, int minY, int maxY) {
    return displayTiles
        .where(
          (tile) =>
              tile.positionX >= minX &&
              tile.positionX <= maxX &&
              tile.positionY >= minY &&
              tile.positionY <= maxY,
        )
        .toList();
  }

  /// Gets tiles adjacent to a position
  List<WorldTile> getAdjacentTiles(int x, int y) {
    return displayTiles.where((tile) {
      final dx = (tile.positionX - x).abs();
      final dy = (tile.positionY - y).abs();
      return (dx <= 1 && dy <= 1) && !(dx == 0 && dy == 0);
    }).toList();
  }

  /// Gets world bounds
  WorldBounds get worldBounds {
    if (displayTiles.isEmpty) {
      return const WorldBounds(minX: 0, maxX: 0, minY: 0, maxY: 0);
    }

    var minX = displayTiles.first.positionX;
    var maxX = displayTiles.first.positionX;
    var minY = displayTiles.first.positionY;
    var maxY = displayTiles.first.positionY;

    for (final tile in displayTiles) {
      if (tile.positionX < minX) minX = tile.positionX;
      if (tile.positionX > maxX) maxX = tile.positionX;
      if (tile.positionY < minY) minY = tile.positionY;
      if (tile.positionY > maxY) maxY = tile.positionY;
    }

    return WorldBounds(minX: minX, maxX: maxX, minY: minY, maxY: maxY);
  }

  @override
  List<Object?> get props => [
    worldTiles,
    filteredTiles,
    activeFilter,
    sortType,
    worldStats,
    worldProgression,
    worldMapData,
    completionPercentage,
    worldAnalytics,
    unlockEligibilityReport,
    optimalPlacements,
    showTileUnlockNotification,
    unlockedTile,
    showProgressionCelebration,
    recentUnlocks,
    zoomLevel,
    viewCenterX,
    viewCenterY,
    viewOffsetX,
    viewOffsetY,
  ];

  /// Creates a copy with updated fields
  WorldLoaded copyWith({
    List<WorldTile>? worldTiles,
    List<WorldTile>? filteredTiles,
    WorldFilter? activeFilter,
    WorldSortType? sortType,
    Map<String, dynamic>? worldStats,
    List<Map<String, dynamic>>? worldProgression,
    List<Map<String, dynamic>>? worldMapData,
    double? completionPercentage,
    List<Map<String, dynamic>>? worldAnalytics,
    List<Map<String, dynamic>>? unlockEligibilityReport,
    List<Map<String, int>>? optimalPlacements,
    bool? showTileUnlockNotification,
    WorldTile? unlockedTile,
    bool? showProgressionCelebration,
    List<WorldTile>? recentUnlocks,
    double? zoomLevel,
    double? viewCenterX,
    double? viewCenterY,
    double? viewOffsetX,
    double? viewOffsetY,
  }) => WorldLoaded(
    worldTiles: worldTiles ?? this.worldTiles,
    filteredTiles: filteredTiles ?? this.filteredTiles,
    activeFilter: activeFilter ?? this.activeFilter,
    sortType: sortType ?? this.sortType,
    worldStats: worldStats ?? this.worldStats,
    worldProgression: worldProgression ?? this.worldProgression,
    worldMapData: worldMapData ?? this.worldMapData,
    completionPercentage: completionPercentage ?? this.completionPercentage,
    worldAnalytics: worldAnalytics ?? this.worldAnalytics,
    unlockEligibilityReport:
        unlockEligibilityReport ?? this.unlockEligibilityReport,
    optimalPlacements: optimalPlacements ?? this.optimalPlacements,
    showTileUnlockNotification:
        showTileUnlockNotification ?? this.showTileUnlockNotification,
    unlockedTile: unlockedTile ?? this.unlockedTile,
    showProgressionCelebration:
        showProgressionCelebration ?? this.showProgressionCelebration,
    recentUnlocks: recentUnlocks ?? this.recentUnlocks,
    zoomLevel: zoomLevel ?? this.zoomLevel,
    viewCenterX: viewCenterX ?? this.viewCenterX,
    viewCenterY: viewCenterY ?? this.viewCenterY,
    viewOffsetX: viewOffsetX ?? this.viewOffsetX,
    viewOffsetY: viewOffsetY ?? this.viewOffsetY,
  );

  /// Clears tile unlock notification
  WorldLoaded clearTileUnlockNotification() =>
      copyWith(showTileUnlockNotification: false, unlockedTile: null);

  /// Clears progression celebration
  WorldLoaded clearProgressionCelebration() =>
      copyWith(showProgressionCelebration: false);

  /// Clears filters
  WorldLoaded clearFilters() =>
      copyWith(filteredTiles: null, activeFilter: null);
}

/// State when world operation fails
class WorldError extends WorldState {
  const WorldError({
    required this.message,
    this.worldTiles,
    this.errorType = WorldErrorType.general,
  });

  final String message;
  final List<WorldTile>? worldTiles; // Keep current tiles if available
  final WorldErrorType errorType;

  @override
  List<Object?> get props => [message, worldTiles, errorType];
}

/// State when world is being updated
class WorldUpdating extends WorldState {
  const WorldUpdating({
    required this.worldTiles,
    required this.updateType,
    this.updatingTileId,
  });

  final List<WorldTile> worldTiles;
  final WorldUpdateType updateType;
  final String? updatingTileId;

  @override
  List<Object?> get props => [worldTiles, updateType, updatingTileId];
}

/// State when world tile is being created
class WorldTileCreating extends WorldState {
  const WorldTileCreating({required this.worldTiles});

  final List<WorldTile> worldTiles;

  @override
  List<Object?> get props => [worldTiles];
}

/// State when checking tile unlock eligibility
class WorldCheckingUnlocks extends WorldState {
  const WorldCheckingUnlocks({
    required this.worldTiles,
    required this.currentXP,
    required this.categoryProgress,
  });

  final List<WorldTile> worldTiles;
  final int currentXP;
  final Map<String, int> categoryProgress;

  @override
  List<Object?> get props => [worldTiles, currentXP, categoryProgress];
}

/// Data class for world statistics summary
class WorldStatsSummary extends Equatable {
  const WorldStatsSummary({
    required this.totalTiles,
    required this.unlockedTiles,
    required this.lockedTiles,
    required this.completionRate,
    required this.averageUnlockRequirement,
  });

  final int totalTiles;
  final int unlockedTiles;
  final int lockedTiles;
  final double completionRate;
  final double averageUnlockRequirement;

  @override
  List<Object?> get props => [
    totalTiles,
    unlockedTiles,
    lockedTiles,
    completionRate,
    averageUnlockRequirement,
  ];
}

/// Data class for world bounds
class WorldBounds extends Equatable {
  const WorldBounds({
    required this.minX,
    required this.maxX,
    required this.minY,
    required this.maxY,
  });

  final int minX;
  final int maxX;
  final int minY;
  final int maxY;

  /// Gets the width of the world
  int get width => maxX - minX + 1;

  /// Gets the height of the world
  int get height => maxY - minY + 1;

  /// Gets the center X coordinate
  double get centerX => (minX + maxX) / 2.0;

  /// Gets the center Y coordinate
  double get centerY => (minY + maxY) / 2.0;

  @override
  List<Object?> get props => [minX, maxX, minY, maxY];
}

/// Data class for tile unlock notification
class TileUnlockNotification extends Equatable {
  const TileUnlockNotification({
    required this.tile,
    required this.timestamp,
    this.celebrationDuration = const Duration(seconds: 3),
  });

  final WorldTile tile;
  final DateTime timestamp;
  final Duration celebrationDuration;

  @override
  List<Object?> get props => [tile, timestamp, celebrationDuration];
}

/// Enum for different types of world errors
enum WorldErrorType {
  general,
  network,
  validation,
  notFound,
  unauthorized,
  unlockFailed,
}

/// Enum for different types of world updates
enum WorldUpdateType {
  creation,
  unlock,
  positionUpdate,
  propertyUpdate,
  batchUnlock,
}
