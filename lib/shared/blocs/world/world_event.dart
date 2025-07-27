import 'package:equatable/equatable.dart';

import '../../../data/models/world.dart';

/// Base class for all world events
abstract class WorldEvent extends Equatable {
  const WorldEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load world tiles for a user
class LoadWorldTiles extends WorldEvent {
  const LoadWorldTiles({required this.userId});

  final String userId;

  @override
  List<Object?> get props => [userId];
}

/// Event to load unlocked world tiles
class LoadUnlockedTiles extends WorldEvent {
  const LoadUnlockedTiles({required this.userId});

  final String userId;

  @override
  List<Object?> get props => [userId];
}

/// Event to load locked world tiles
class LoadLockedTiles extends WorldEvent {
  const LoadLockedTiles({required this.userId});

  final String userId;

  @override
  List<Object?> get props => [userId];
}

/// Event to load tiles by type
class LoadTilesByType extends WorldEvent {
  const LoadTilesByType({required this.userId, required this.type});

  final String userId;
  final TileType type;

  @override
  List<Object?> get props => [userId, type];
}

/// Event to load tiles in a specific area
class LoadTilesInArea extends WorldEvent {
  const LoadTilesInArea({
    required this.userId,
    required this.minX,
    required this.maxX,
    required this.minY,
    required this.maxY,
  });

  final String userId;
  final int minX;
  final int maxX;
  final int minY;
  final int maxY;

  @override
  List<Object?> get props => [userId, minX, maxX, minY, maxY];
}

/// Event to load unlockable tiles
class LoadUnlockableTiles extends WorldEvent {
  const LoadUnlockableTiles({
    required this.userId,
    required this.currentXP,
    required this.categoryProgress,
  });

  final String userId;
  final int currentXP;
  final Map<String, int> categoryProgress;

  @override
  List<Object?> get props => [userId, currentXP, categoryProgress];
}

/// Event to create a new world tile
class CreateWorldTile extends WorldEvent {
  const CreateWorldTile({
    required this.userId,
    required this.name,
    required this.imagePath,
    required this.type,
    required this.unlockRequirement,
    required this.positionX,
    required this.positionY,
    this.description = '',
    this.unlockCategory,
    this.customProperties = const {},
  });

  final String userId;
  final String name;
  final String imagePath;
  final TileType type;
  final int unlockRequirement;
  final int positionX;
  final int positionY;
  final String description;
  final String? unlockCategory;
  final Map<String, dynamic> customProperties;

  @override
  List<Object?> get props => [
    userId,
    name,
    imagePath,
    type,
    unlockRequirement,
    positionX,
    positionY,
    description,
    unlockCategory,
    customProperties,
  ];
}

/// Event to unlock a world tile
class UnlockTile extends WorldEvent {
  const UnlockTile({
    required this.tileId,
    required this.currentXP,
    required this.categoryProgress,
  });

  final String tileId;
  final int currentXP;
  final Map<String, int> categoryProgress;

  @override
  List<Object?> get props => [tileId, currentXP, categoryProgress];
}

/// Event to batch unlock multiple tiles
class BatchUnlockTiles extends WorldEvent {
  const BatchUnlockTiles({
    required this.tileIds,
    required this.currentXP,
    required this.categoryProgress,
  });

  final List<String> tileIds;
  final int currentXP;
  final Map<String, int> categoryProgress;

  @override
  List<Object?> get props => [tileIds, currentXP, categoryProgress];
}

/// Event to check and unlock eligible tiles automatically
class CheckAndUnlockTiles extends WorldEvent {
  const CheckAndUnlockTiles({
    required this.userId,
    required this.currentXP,
    required this.categoryProgress,
  });

  final String userId;
  final int currentXP;
  final Map<String, int> categoryProgress;

  @override
  List<Object?> get props => [userId, currentXP, categoryProgress];
}

/// Event to update tile position
class UpdateTilePosition extends WorldEvent {
  const UpdateTilePosition({
    required this.tileId,
    required this.newX,
    required this.newY,
  });

  final String tileId;
  final int newX;
  final int newY;

  @override
  List<Object?> get props => [tileId, newX, newY];
}

/// Event to update tile custom properties
class UpdateTileProperties extends WorldEvent {
  const UpdateTileProperties({required this.tileId, required this.properties});

  final String tileId;
  final Map<String, dynamic> properties;

  @override
  List<Object?> get props => [tileId, properties];
}

/// Event to load tiles adjacent to a position
class LoadAdjacentTiles extends WorldEvent {
  const LoadAdjacentTiles({
    required this.userId,
    required this.x,
    required this.y,
  });

  final String userId;
  final int x;
  final int y;

  @override
  List<Object?> get props => [userId, x, y];
}

/// Event to load world statistics
class LoadWorldStats extends WorldEvent {
  const LoadWorldStats({required this.userId});

  final String userId;

  @override
  List<Object?> get props => [userId];
}

/// Event to load world progression data
class LoadWorldProgression extends WorldEvent {
  const LoadWorldProgression({required this.userId});

  final String userId;

  @override
  List<Object?> get props => [userId];
}

/// Event to load world map data
class LoadWorldMapData extends WorldEvent {
  const LoadWorldMapData({required this.userId});

  final String userId;

  @override
  List<Object?> get props => [userId];
}

/// Event to get world completion percentage
class GetWorldCompletionPercentage extends WorldEvent {
  const GetWorldCompletionPercentage({required this.userId});

  final String userId;

  @override
  List<Object?> get props => [userId];
}

/// Event to load world analytics
class LoadWorldAnalytics extends WorldEvent {
  const LoadWorldAnalytics({required this.userId});

  final String userId;

  @override
  List<Object?> get props => [userId];
}

/// Event to get unlock eligibility report
class GetUnlockEligibilityReport extends WorldEvent {
  const GetUnlockEligibilityReport({
    required this.userId,
    required this.currentXP,
    required this.categoryProgress,
  });

  final String userId;
  final int currentXP;
  final Map<String, int> categoryProgress;

  @override
  List<Object?> get props => [userId, currentXP, categoryProgress];
}

/// Event to create default world layout
class CreateDefaultWorld extends WorldEvent {
  const CreateDefaultWorld({required this.userId});

  final String userId;

  @override
  List<Object?> get props => [userId];
}

/// Event to calculate optimal tile placements
class CalculateOptimalPlacements extends WorldEvent {
  const CalculateOptimalPlacements({
    required this.existingTiles,
    required this.count,
  });

  final List<WorldTile> existingTiles;
  final int count;

  @override
  List<Object?> get props => [existingTiles, count];
}

/// Event to refresh world data
class RefreshWorldData extends WorldEvent {
  const RefreshWorldData({required this.userId});

  final String userId;

  @override
  List<Object?> get props => [userId];
}

/// Event to filter world tiles
class FilterWorldTiles extends WorldEvent {
  const FilterWorldTiles({required this.filter});

  final WorldFilter filter;

  @override
  List<Object?> get props => [filter];
}

/// Event to sort world tiles
class SortWorldTiles extends WorldEvent {
  const SortWorldTiles({required this.sortType});

  final WorldSortType sortType;

  @override
  List<Object?> get props => [sortType];
}

/// Event to clear world filters
class ClearWorldFilters extends WorldEvent {
  const ClearWorldFilters({required this.userId});

  final String userId;

  @override
  List<Object?> get props => [userId];
}

/// Event to handle tile unlock notification completion
class TileUnlockNotificationCompleted extends WorldEvent {
  const TileUnlockNotificationCompleted({required this.tileId});

  final String tileId;

  @override
  List<Object?> get props => [tileId];
}

/// Event to handle world progression celebration completion
class WorldProgressionCelebrationCompleted extends WorldEvent {
  const WorldProgressionCelebrationCompleted({required this.userId});

  final String userId;

  @override
  List<Object?> get props => [userId];
}

/// Event to zoom world view
class ZoomWorldView extends WorldEvent {
  const ZoomWorldView({
    required this.zoomLevel,
    required this.centerX,
    required this.centerY,
  });

  final double zoomLevel;
  final double centerX;
  final double centerY;

  @override
  List<Object?> get props => [zoomLevel, centerX, centerY];
}

/// Event to pan world view
class PanWorldView extends WorldEvent {
  const PanWorldView({required this.offsetX, required this.offsetY});

  final double offsetX;
  final double offsetY;

  @override
  List<Object?> get props => [offsetX, offsetY];
}

/// Data class for world filters
class WorldFilter extends Equatable {
  const WorldFilter({
    this.type,
    this.isUnlocked,
    this.unlockCategory,
    this.minUnlockRequirement,
    this.maxUnlockRequirement,
    this.area,
  });

  final TileType? type;
  final bool? isUnlocked;
  final String? unlockCategory;
  final int? minUnlockRequirement;
  final int? maxUnlockRequirement;
  final WorldArea? area;

  @override
  List<Object?> get props => [
    type,
    isUnlocked,
    unlockCategory,
    minUnlockRequirement,
    maxUnlockRequirement,
    area,
  ];

  /// Creates a copy with updated fields
  WorldFilter copyWith({
    TileType? type,
    bool? isUnlocked,
    String? unlockCategory,
    int? minUnlockRequirement,
    int? maxUnlockRequirement,
    WorldArea? area,
  }) => WorldFilter(
    type: type ?? this.type,
    isUnlocked: isUnlocked ?? this.isUnlocked,
    unlockCategory: unlockCategory ?? this.unlockCategory,
    minUnlockRequirement: minUnlockRequirement ?? this.minUnlockRequirement,
    maxUnlockRequirement: maxUnlockRequirement ?? this.maxUnlockRequirement,
    area: area ?? this.area,
  );

  /// Checks if a world tile matches this filter
  bool matches(WorldTile tile) {
    if (type != null && tile.type != type) return false;
    if (isUnlocked != null && tile.isUnlocked != isUnlocked) return false;
    if (unlockCategory != null && tile.unlockCategory != unlockCategory) {
      return false;
    }
    if (minUnlockRequirement != null &&
        tile.unlockRequirement < minUnlockRequirement!) {
      return false;
    }
    if (maxUnlockRequirement != null &&
        tile.unlockRequirement > maxUnlockRequirement!) {
      return false;
    }
    if (area != null && !area!.contains(tile.positionX, tile.positionY)) {
      return false;
    }

    return true;
  }
}

/// Data class for world areas
class WorldArea extends Equatable {
  const WorldArea({
    required this.minX,
    required this.maxX,
    required this.minY,
    required this.maxY,
  });

  final int minX;
  final int maxX;
  final int minY;
  final int maxY;

  /// Checks if a position is within this area
  bool contains(int x, int y) =>
      x >= minX && x <= maxX && y >= minY && y <= maxY;

  @override
  List<Object?> get props => [minX, maxX, minY, maxY];
}

/// Enum for world sorting options
enum WorldSortType {
  name,
  type,
  unlockRequirement,
  position,
  unlockedDate,
  createdDate,
}
