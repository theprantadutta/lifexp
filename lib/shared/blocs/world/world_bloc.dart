import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/world_tile.dart';
import '../../../data/repositories/world_repository.dart';
import 'world_event.dart';
import 'world_state.dart';

/// BLoC for managing world progression, tile unlocking, and customization
class WorldBloc extends Bloc<WorldEvent, WorldState> {
  WorldBloc({required WorldRepository worldRepository})
    : _worldRepository = worldRepository,
      super(const WorldInitial()) {
    on<LoadWorldTiles>(_onLoadWorldTiles);
    on<LoadUnlockedTiles>(_onLoadUnlockedTiles);
    on<LoadLockedTiles>(_onLoadLockedTiles);
    on<LoadTilesByType>(_onLoadTilesByType);
    on<LoadTilesInArea>(_onLoadTilesInArea);
    on<LoadUnlockableTiles>(_onLoadUnlockableTiles);
    on<CreateWorldTile>(_onCreateWorldTile);
    on<UnlockTile>(_onUnlockTile);
    on<BatchUnlockTiles>(_onBatchUnlockTiles);
    on<CheckAndUnlockTiles>(_onCheckAndUnlockTiles);
    on<UpdateTilePosition>(_onUpdateTilePosition);
    on<UpdateTileProperties>(_onUpdateTileProperties);
    on<LoadAdjacentTiles>(_onLoadAdjacentTiles);
    on<LoadWorldStats>(_onLoadWorldStats);
    on<LoadWorldProgression>(_onLoadWorldProgression);
    on<LoadWorldMapData>(_onLoadWorldMapData);
    on<GetWorldCompletionPercentage>(_onGetWorldCompletionPercentage);
    on<LoadWorldAnalytics>(_onLoadWorldAnalytics);
    on<GetUnlockEligibilityReport>(_onGetUnlockEligibilityReport);
    on<CreateDefaultWorld>(_onCreateDefaultWorld);
    on<CalculateOptimalPlacements>(_onCalculateOptimalPlacements);
    on<RefreshWorldData>(_onRefreshWorldData);
    on<FilterWorldTiles>(_onFilterWorldTiles);
    on<SortWorldTiles>(_onSortWorldTiles);
    on<ClearWorldFilters>(_onClearWorldFilters);
    on<TileUnlockNotificationCompleted>(_onTileUnlockNotificationCompleted);
    on<WorldProgressionCelebrationCompleted>(
      _onWorldProgressionCelebrationCompleted,
    );
    on<ZoomWorldView>(_onZoomWorldView);
    on<PanWorldView>(_onPanWorldView);

    // Tile unlock notifications are handled through events
  }

  final WorldRepository _worldRepository;
  StreamSubscription<WorldTile>? _tileUnlockSubscription;

  /// Handles loading world tiles for a user
  Future<void> _onLoadWorldTiles(
    LoadWorldTiles event,
    Emitter<WorldState> emit,
  ) async {
    emit(const WorldLoading());

    try {
      final worldTiles = await _worldRepository.getWorldTilesByUserId(
        event.userId,
      );
      emit(WorldLoaded(worldTiles: worldTiles));
    } on Exception catch (e) {
      emit(
        WorldError(
          message: 'Failed to load world tiles: ${e.toString()}',
        ),
      );
    }
  }

  /// Handles loading unlocked tiles
  Future<void> _onLoadUnlockedTiles(
    LoadUnlockedTiles event,
    Emitter<WorldState> emit,
  ) async {
    final currentState = state;
    if (currentState is! WorldLoaded) return;

    try {
      final unlockedTiles = await _worldRepository.getUnlockedTiles(
        event.userId,
      );

      const filter = WorldFilter(isUnlocked: true);

      emit(
        currentState.copyWith(
          filteredTiles: unlockedTiles,
          activeFilter: filter,
        ),
      );
    } on Exception catch (e) {
      emit(
        WorldError(
          message: 'Failed to load unlocked tiles: ${e.toString()}',
          worldTiles: currentState.worldTiles,
        ),
      );
    }
  }

  /// Handles loading locked tiles
  Future<void> _onLoadLockedTiles(
    LoadLockedTiles event,
    Emitter<WorldState> emit,
  ) async {
    final currentState = state;
    if (currentState is! WorldLoaded) return;

    try {
      final lockedTiles = await _worldRepository.getLockedTiles(event.userId);

      const filter = WorldFilter(isUnlocked: false);

      emit(
        currentState.copyWith(filteredTiles: lockedTiles, activeFilter: filter),
      );
    } on Exception catch (e) {
      emit(
        WorldError(
          message: 'Failed to load locked tiles: ${e.toString()}',
          worldTiles: currentState.worldTiles,
        ),
      );
    }
  }

  /// Handles loading tiles by type
  Future<void> _onLoadTilesByType(
    LoadTilesByType event,
    Emitter<WorldState> emit,
  ) async {
    final currentState = state;
    if (currentState is! WorldLoaded) return;

    try {
      final tilesByType = await _worldRepository.getTilesByType(
        event.userId,
        event.type,
      );

      final filter = WorldFilter(type: event.type);

      emit(
        currentState.copyWith(filteredTiles: tilesByType, activeFilter: filter),
      );
    } on Exception catch (e) {
      emit(
        WorldError(
          message: 'Failed to load tiles by type: ${e.toString()}',
          worldTiles: currentState.worldTiles,
        ),
      );
    }
  }

  /// Handles loading tiles in a specific area
  Future<void> _onLoadTilesInArea(
    LoadTilesInArea event,
    Emitter<WorldState> emit,
  ) async {
    final currentState = state;
    if (currentState is! WorldLoaded) return;

    try {
      final tilesInArea = await _worldRepository.getTilesInArea(
        event.userId,
        event.minX,
        event.maxX,
        event.minY,
        event.maxY,
      );

      final filter = WorldFilter(
        area: WorldArea(
          minX: event.minX,
          maxX: event.maxX,
          minY: event.minY,
          maxY: event.maxY,
        ),
      );

      emit(
        currentState.copyWith(filteredTiles: tilesInArea, activeFilter: filter),
      );
    } on Exception catch (e) {
      emit(
        WorldError(
          message: 'Failed to load tiles in area: ${e.toString()}',
          worldTiles: currentState.worldTiles,
        ),
      );
    }
  }

  /// Handles loading unlockable tiles
  Future<void> _onLoadUnlockableTiles(
    LoadUnlockableTiles event,
    Emitter<WorldState> emit,
  ) async {
    final currentState = state;
    if (currentState is! WorldLoaded) return;

    try {
      final unlockableTiles = await _worldRepository.getUnlockableTiles(
        event.userId,
        event.currentXP,
        event.categoryProgress,
      );

      emit(currentState.copyWith(filteredTiles: unlockableTiles));
    } on Exception catch (e) {
      emit(
        WorldError(
          message: 'Failed to load unlockable tiles: ${e.toString()}',
          worldTiles: currentState.worldTiles,
        ),
      );
    }
  }

  /// Handles creating a new world tile
  Future<void> _onCreateWorldTile(
    CreateWorldTile event,
    Emitter<WorldState> emit,
  ) async {
    final currentState = state;
    var currentTiles = <WorldTile>[];

    if (currentState is WorldLoaded) {
      currentTiles = currentState.worldTiles;
      emit(WorldTileCreating(worldTiles: currentTiles));
    } else {
      emit(const WorldLoading());
    }

    try {
      final newTile = await _worldRepository.createWorldTile(
        userId: event.userId,
        name: event.name,
        imagePath: event.imagePath,
        type: event.type,
        unlockRequirement: event.unlockRequirement,
        positionX: event.positionX,
        positionY: event.positionY,
        description: event.description,
        unlockCategory: event.unlockCategory,
        customProperties: event.customProperties,
      );

      final updatedTiles = [...currentTiles, newTile];
      emit(WorldLoaded(worldTiles: updatedTiles));
    } on Exception catch (e) {
      emit(
        WorldError(
          message: 'Failed to create world tile: ${e.toString()}',
          worldTiles: currentTiles,
        ),
      );
    }
  }

  /// Handles unlocking a world tile
  Future<void> _onUnlockTile(UnlockTile event, Emitter<WorldState> emit) async {
    final currentState = state;
    if (currentState is! WorldLoaded) return;

    // Find the tile being unlocked
    final tileToUnlock = currentState.worldTiles
        .where((tile) => tile.id == event.tileId)
        .firstOrNull;

    if (tileToUnlock == null || tileToUnlock.isUnlocked) return;

    emit(
      WorldUpdating(
        worldTiles: currentState.worldTiles,
        updateType: WorldUpdateType.unlock,
        updatingTileId: event.tileId,
      ),
    );

    try {
      final unlockedTile = await _worldRepository.unlockTile(
        event.tileId,
        event.currentXP,
        event.categoryProgress,
      );

      if (unlockedTile == null) {
        emit(
          WorldError(
            message: 'Failed to unlock tile - requirements not met',
            worldTiles: currentState.worldTiles,
            errorType: WorldErrorType.unlockFailed,
          ),
        );
        return;
      }

      // Update tiles list
      final updatedTiles = currentState.worldTiles
          .map((tile) => tile.id == unlockedTile.id ? unlockedTile : tile)
          .toList();

      emit(
        WorldLoaded(
          worldTiles: updatedTiles,
          filteredTiles: currentState.filteredTiles,
          activeFilter: currentState.activeFilter,
          sortType: currentState.sortType,
          showTileUnlockNotification: true,
          unlockedTile: unlockedTile,
          recentUnlocks: [...currentState.recentUnlocks, unlockedTile],
        ),
      );
    } on Exception catch (e) {
      emit(
        WorldError(
          message: 'Failed to unlock tile: ${e.toString()}',
          worldTiles: currentState.worldTiles,
        ),
      );
    }
  }

  /// Handles batch unlocking multiple tiles
  Future<void> _onBatchUnlockTiles(
    BatchUnlockTiles event,
    Emitter<WorldState> emit,
  ) async {
    final currentState = state;
    if (currentState is! WorldLoaded) return;

    emit(
      WorldUpdating(
        worldTiles: currentState.worldTiles,
        updateType: WorldUpdateType.batchUnlock,
      ),
    );

    try {
      final unlockedTiles = await _worldRepository.batchUnlockTiles(
        event.tileIds,
        event.currentXP,
        event.categoryProgress,
      );

      if (unlockedTiles.isEmpty) {
        emit(
          WorldError(
            message: 'No tiles could be unlocked',
            worldTiles: currentState.worldTiles,
            errorType: WorldErrorType.unlockFailed,
          ),
        );
        return;
      }

      // Update tiles list
      final updatedTiles = currentState.worldTiles.map((tile) {
        final unlockedTile = unlockedTiles
            .where((ut) => ut.id == tile.id)
            .firstOrNull;
        return unlockedTile ?? tile;
      }).toList();

      // Show notification for the first unlocked tile
      final firstUnlocked = unlockedTiles.first;

      emit(
        WorldLoaded(
          worldTiles: updatedTiles,
          filteredTiles: currentState.filteredTiles,
          activeFilter: currentState.activeFilter,
          sortType: currentState.sortType,
          showTileUnlockNotification: true,
          unlockedTile: firstUnlocked,
          recentUnlocks: [...currentState.recentUnlocks, ...unlockedTiles],
        ),
      );
    } on Exception catch (e) {
      emit(
        WorldError(
          message: 'Failed to batch unlock tiles: ${e.toString()}',
          worldTiles: currentState.worldTiles,
        ),
      );
    }
  }

  /// Handles checking and unlocking eligible tiles automatically
  Future<void> _onCheckAndUnlockTiles(
    CheckAndUnlockTiles event,
    Emitter<WorldState> emit,
  ) async {
    final currentState = state;
    if (currentState is! WorldLoaded) return;

    emit(
      WorldCheckingUnlocks(
        worldTiles: currentState.worldTiles,
        currentXP: event.currentXP,
        categoryProgress: event.categoryProgress,
      ),
    );

    try {
      final unlockedTiles = await _worldRepository.checkAndUnlockTiles(
        event.userId,
        event.currentXP,
        event.categoryProgress,
      );

      if (unlockedTiles.isEmpty) {
        emit(currentState);
        return;
      }

      // Refresh all tiles to get updated data
      final allTiles = await _worldRepository.getWorldTilesByUserId(
        event.userId,
      );

      // Show progression celebration if multiple tiles were unlocked
      final showCelebration = unlockedTiles.length > 1;
      final firstUnlocked = unlockedTiles.first;

      emit(
        WorldLoaded(
          worldTiles: allTiles,
          filteredTiles: currentState.filteredTiles,
          activeFilter: currentState.activeFilter,
          sortType: currentState.sortType,
          showTileUnlockNotification: true,
          unlockedTile: firstUnlocked,
          showProgressionCelebration: showCelebration,
          recentUnlocks: [...currentState.recentUnlocks, ...unlockedTiles],
        ),
      );
    } on Exception catch (e) {
      emit(
        WorldError(
          message: 'Failed to check and unlock tiles: ${e.toString()}',
          worldTiles: currentState.worldTiles,
        ),
      );
    }
  }

  /// Handles updating tile position
  Future<void> _onUpdateTilePosition(
    UpdateTilePosition event,
    Emitter<WorldState> emit,
  ) async {
    final currentState = state;
    if (currentState is! WorldLoaded) return;

    emit(
      WorldUpdating(
        worldTiles: currentState.worldTiles,
        updateType: WorldUpdateType.positionUpdate,
        updatingTileId: event.tileId,
      ),
    );

    try {
      final success = await _worldRepository.updateTilePosition(
        event.tileId,
        event.newX,
        event.newY,
      );

      if (!success) {
        emit(
          WorldError(
            message: 'Failed to update tile position',
            worldTiles: currentState.worldTiles,
            errorType: WorldErrorType.validation,
          ),
        );
        return;
      }

      // Get updated tile
      final updatedTile = await _worldRepository.getWorldTileById(event.tileId);
      if (updatedTile == null) {
        emit(
          WorldError(
            message: 'Failed to refresh tile after position update',
            worldTiles: currentState.worldTiles,
          ),
        );
        return;
      }

      final updatedTiles = currentState.worldTiles
          .map((tile) => tile.id == updatedTile.id ? updatedTile : tile)
          .toList();

      emit(currentState.copyWith(worldTiles: updatedTiles));
    } on Exception catch (e) {
      emit(
        WorldError(
          message: 'Failed to update tile position: ${e.toString()}',
          worldTiles: currentState.worldTiles,
        ),
      );
    }
  }

  /// Handles updating tile custom properties
  Future<void> _onUpdateTileProperties(
    UpdateTileProperties event,
    Emitter<WorldState> emit,
  ) async {
    final currentState = state;
    if (currentState is! WorldLoaded) return;

    emit(
      WorldUpdating(
        worldTiles: currentState.worldTiles,
        updateType: WorldUpdateType.propertyUpdate,
        updatingTileId: event.tileId,
      ),
    );

    try {
      final success = await _worldRepository.updateTileProperties(
        event.tileId,
        event.properties,
      );

      if (!success) {
        emit(
          WorldError(
            message: 'Failed to update tile properties',
            worldTiles: currentState.worldTiles,
          ),
        );
        return;
      }

      // Get updated tile
      final updatedTile = await _worldRepository.getWorldTileById(event.tileId);
      if (updatedTile == null) {
        emit(
          WorldError(
            message: 'Failed to refresh tile after property update',
            worldTiles: currentState.worldTiles,
          ),
        );
        return;
      }

      final updatedTiles = currentState.worldTiles
          .map((tile) => tile.id == updatedTile.id ? updatedTile : tile)
          .toList();

      emit(currentState.copyWith(worldTiles: updatedTiles));
    } on Exception catch (e) {
      emit(
        WorldError(
          message: 'Failed to update tile properties: ${e.toString()}',
          worldTiles: currentState.worldTiles,
        ),
      );
    }
  }

  /// Handles loading adjacent tiles
  Future<void> _onLoadAdjacentTiles(
    LoadAdjacentTiles event,
    Emitter<WorldState> emit,
  ) async {
    final currentState = state;
    if (currentState is! WorldLoaded) return;

    try {
      final adjacentTiles = await _worldRepository.getAdjacentTiles(
        event.userId,
        event.x,
        event.y,
      );

      emit(currentState.copyWith(filteredTiles: adjacentTiles));
    } on Exception catch (e) {
      emit(
        WorldError(
          message: 'Failed to load adjacent tiles: ${e.toString()}',
          worldTiles: currentState.worldTiles,
        ),
      );
    }
  }

  /// Handles loading world statistics
  Future<void> _onLoadWorldStats(
    LoadWorldStats event,
    Emitter<WorldState> emit,
  ) async {
    final currentState = state;
    if (currentState is! WorldLoaded) return;

    try {
      final worldStats = await _worldRepository.getWorldStats(event.userId);

      emit(currentState.copyWith(worldStats: worldStats));
    } on Exception catch (e) {
      emit(
        WorldError(
          message: 'Failed to load world stats: ${e.toString()}',
          worldTiles: currentState.worldTiles,
        ),
      );
    }
  }

  /// Handles loading world progression data
  Future<void> _onLoadWorldProgression(
    LoadWorldProgression event,
    Emitter<WorldState> emit,
  ) async {
    final currentState = state;
    if (currentState is! WorldLoaded) return;

    try {
      final worldProgression = await _worldRepository.getWorldProgression(
        event.userId,
      );

      emit(currentState.copyWith(worldProgression: worldProgression));
    } on Exception catch (e) {
      emit(
        WorldError(
          message: 'Failed to load world progression: ${e.toString()}',
          worldTiles: currentState.worldTiles,
        ),
      );
    }
  }

  /// Handles loading world map data
  Future<void> _onLoadWorldMapData(
    LoadWorldMapData event,
    Emitter<WorldState> emit,
  ) async {
    final currentState = state;
    if (currentState is! WorldLoaded) return;

    try {
      final worldMapData = await _worldRepository.getWorldMapData(event.userId);

      emit(currentState.copyWith(worldMapData: worldMapData));
    } on Exception catch (e) {
      emit(
        WorldError(
          message: 'Failed to load world map data: ${e.toString()}',
          worldTiles: currentState.worldTiles,
        ),
      );
    }
  }

  /// Handles getting world completion percentage
  Future<void> _onGetWorldCompletionPercentage(
    GetWorldCompletionPercentage event,
    Emitter<WorldState> emit,
  ) async {
    final currentState = state;
    if (currentState is! WorldLoaded) return;

    try {
      final completionPercentage = await _worldRepository
          .getWorldCompletionPercentage(event.userId);

      emit(currentState.copyWith(completionPercentage: completionPercentage));
    } on Exception catch (e) {
      emit(
        WorldError(
          message: 'Failed to get world completion percentage: ${e.toString()}',
          worldTiles: currentState.worldTiles,
        ),
      );
    }
  }

  /// Handles loading world analytics
  Future<void> _onLoadWorldAnalytics(
    LoadWorldAnalytics event,
    Emitter<WorldState> emit,
  ) async {
    final currentState = state;
    if (currentState is! WorldLoaded) return;

    try {
      final worldAnalytics = await _worldRepository.getWorldAnalytics(
        event.userId,
      );

      emit(currentState.copyWith(worldAnalytics: worldAnalytics));
    } on Exception catch (e) {
      emit(
        WorldError(
          message: 'Failed to load world analytics: ${e.toString()}',
          worldTiles: currentState.worldTiles,
        ),
      );
    }
  }

  /// Handles getting unlock eligibility report
  Future<void> _onGetUnlockEligibilityReport(
    GetUnlockEligibilityReport event,
    Emitter<WorldState> emit,
  ) async {
    final currentState = state;
    if (currentState is! WorldLoaded) return;

    try {
      final unlockEligibilityReport = await _worldRepository
          .getUnlockEligibilityReport(
            event.userId,
            event.currentXP,
            event.categoryProgress,
          );

      emit(
        currentState.copyWith(unlockEligibilityReport: unlockEligibilityReport),
      );
    } on Exception catch (e) {
      emit(
        WorldError(
          message: 'Failed to get unlock eligibility report: ${e.toString()}',
          worldTiles: currentState.worldTiles,
        ),
      );
    }
  }

  /// Handles creating default world layout
  Future<void> _onCreateDefaultWorld(
    CreateDefaultWorld event,
    Emitter<WorldState> emit,
  ) async {
    emit(const WorldLoading());

    try {
      await _worldRepository.createDefaultWorld(event.userId);

      // Load the newly created world
      final worldTiles = await _worldRepository.getWorldTilesByUserId(
        event.userId,
      );

      emit(WorldLoaded(worldTiles: worldTiles));
    } on Exception catch (e) {
      emit(
        WorldError(
          message: 'Failed to create default world: ${e.toString()}',
        ),
      );
    }
  }

  /// Handles calculating optimal tile placements
  Future<void> _onCalculateOptimalPlacements(
    CalculateOptimalPlacements event,
    Emitter<WorldState> emit,
  ) async {
    final currentState = state;
    if (currentState is! WorldLoaded) return;

    try {
      final optimalPlacements = _worldRepository.calculateOptimalPlacements(
        event.existingTiles,
        event.count,
      );

      emit(currentState.copyWith(optimalPlacements: optimalPlacements));
    } on Exception catch (e) {
      emit(
        WorldError(
          message: 'Failed to calculate optimal placements: ${e.toString()}',
          worldTiles: currentState.worldTiles,
        ),
      );
    }
  }

  /// Handles refreshing world data
  Future<void> _onRefreshWorldData(
    RefreshWorldData event,
    Emitter<WorldState> emit,
  ) async {
    try {
      final worldTiles = await _worldRepository.getWorldTilesByUserId(
        event.userId,
      );

      final currentState = state;
      if (currentState is WorldLoaded) {
        emit(currentState.copyWith(worldTiles: worldTiles));
      } else {
        emit(WorldLoaded(worldTiles: worldTiles));
      }
    } on Exception catch (e) {
      emit(
        WorldError(
          message: 'Failed to refresh world data: ${e.toString()}',
        ),
      );
    }
  }

  /// Handles filtering world tiles
  Future<void> _onFilterWorldTiles(
    FilterWorldTiles event,
    Emitter<WorldState> emit,
  ) async {
    final currentState = state;
    if (currentState is! WorldLoaded) return;

    final filteredTiles = currentState.worldTiles
        .where((tile) => event.filter.matches(tile))
        .toList();

    emit(
      currentState.copyWith(
        filteredTiles: filteredTiles,
        activeFilter: event.filter,
      ),
    );
  }

  /// Handles sorting world tiles
  Future<void> _onSortWorldTiles(
    SortWorldTiles event,
    Emitter<WorldState> emit,
  ) async {
    final currentState = state;
    if (currentState is! WorldLoaded) return;

    final sortedTiles = _sortWorldTiles(
      currentState.displayTiles,
      event.sortType,
    );

    if (currentState.filteredTiles != null) {
      emit(
        currentState.copyWith(
          filteredTiles: sortedTiles,
          sortType: event.sortType,
        ),
      );
    } else {
      emit(
        currentState.copyWith(
          worldTiles: sortedTiles,
          sortType: event.sortType,
        ),
      );
    }
  }

  /// Handles clearing world filters
  Future<void> _onClearWorldFilters(
    ClearWorldFilters event,
    Emitter<WorldState> emit,
  ) async {
    final currentState = state;
    if (currentState is! WorldLoaded) return;

    emit(currentState.clearFilters());
  }

  /// Handles tile unlock notification completion
  Future<void> _onTileUnlockNotificationCompleted(
    TileUnlockNotificationCompleted event,
    Emitter<WorldState> emit,
  ) async {
    final currentState = state;
    if (currentState is! WorldLoaded) return;

    emit(currentState.clearTileUnlockNotification());
  }

  /// Handles world progression celebration completion
  Future<void> _onWorldProgressionCelebrationCompleted(
    WorldProgressionCelebrationCompleted event,
    Emitter<WorldState> emit,
  ) async {
    final currentState = state;
    if (currentState is! WorldLoaded) return;

    emit(currentState.clearProgressionCelebration());
  }

  /// Handles zooming world view
  Future<void> _onZoomWorldView(
    ZoomWorldView event,
    Emitter<WorldState> emit,
  ) async {
    final currentState = state;
    if (currentState is! WorldLoaded) return;

    emit(
      currentState.copyWith(
        zoomLevel: event.zoomLevel.clamp(0.1, 5.0),
        viewCenterX: event.centerX,
        viewCenterY: event.centerY,
      ),
    );
  }

  /// Handles panning world view
  Future<void> _onPanWorldView(
    PanWorldView event,
    Emitter<WorldState> emit,
  ) async {
    final currentState = state;
    if (currentState is! WorldLoaded) return;

    emit(
      currentState.copyWith(
        viewOffsetX: event.offsetX,
        viewOffsetY: event.offsetY,
      ),
    );
  }

  // Tile unlock handling is done through events, not direct stream listening

  // Private helper methods

  /// Sorts world tiles based on the specified sort type
  List<WorldTile> _sortWorldTiles(
    List<WorldTile> tiles,
    WorldSortType sortType,
  ) {
    final sortedTiles = List<WorldTile>.from(tiles);

    switch (sortType) {
      case WorldSortType.name:
        sortedTiles.sort((a, b) => a.name.compareTo(b.name));
        break;

      case WorldSortType.type:
        sortedTiles.sort((a, b) => a.type.name.compareTo(b.type.name));
        break;

      case WorldSortType.unlockRequirement:
        sortedTiles.sort(
          (a, b) => a.unlockRequirement.compareTo(b.unlockRequirement),
        );
        break;

      case WorldSortType.position:
        sortedTiles.sort((a, b) {
          final yComparison = a.positionY.compareTo(b.positionY);
          if (yComparison != 0) return yComparison;
          return a.positionX.compareTo(b.positionX);
        });
        break;

      case WorldSortType.unlockedDate:
        sortedTiles.sort((a, b) {
          if (a.unlockedAt == null && b.unlockedAt == null) return 0;
          if (a.unlockedAt == null) return 1;
          if (b.unlockedAt == null) return -1;
          return b.unlockedAt!.compareTo(a.unlockedAt!);
        });
        break;

      case WorldSortType.createdDate:
        sortedTiles.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
    }

    return sortedTiles;
  }

  @override
  Future<void> close() {
    _tileUnlockSubscription?.cancel();
    _worldRepository.dispose();
    return super.close();
  }
}

// FirstOrNull extension removed to avoid conflicts with repository extensions
