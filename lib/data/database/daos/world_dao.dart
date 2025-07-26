part of '../database.dart';

/// Data Access Object for World operations
@DriftAccessor(tables: [WorldTiles, Users])
class WorldDao extends DatabaseAccessor<LifeXPDatabase> with _$WorldDaoMixin {
  WorldDao(super.db);

  /// Gets all world tiles for a user
  Future<List<WorldTileData>> getWorldTilesByUserId(String userId) async =>
      (select(worldTiles)
            ..where((w) => w.userId.equals(userId))
            ..orderBy([
              (w) => OrderingTerm.asc(w.positionX),
              (w) => OrderingTerm.asc(w.positionY),
            ]))
          .get();

  /// Gets world tile by ID
  Future<WorldTileData?> getWorldTileById(String id) async =>
      (select(worldTiles)..where((w) => w.id.equals(id))).getSingleOrNull();

  /// Gets unlocked world tiles
  Future<List<WorldTileData>> getUnlockedTiles(String userId) async =>
      (select(worldTiles)
            ..where((w) => w.userId.equals(userId) & w.isUnlocked.equals(true))
            ..orderBy([(w) => OrderingTerm.desc(w.unlockedAt)]))
          .get();

  /// Gets locked world tiles
  Future<List<WorldTileData>> getLockedTiles(String userId) async =>
      (select(worldTiles)
            ..where((w) => w.userId.equals(userId) & w.isUnlocked.equals(false))
            ..orderBy([(w) => OrderingTerm.asc(w.unlockRequirement)]))
          .get();

  /// Gets tiles by type
  Future<List<WorldTileData>> getTilesByType(
    String userId,
    String tileType,
  ) async =>
      (select(worldTiles)
            ..where(
              (w) => w.userId.equals(userId) & w.tileType.equals(tileType),
            )
            ..orderBy([
              (w) => OrderingTerm.asc(w.positionX),
              (w) => OrderingTerm.asc(w.positionY),
            ]))
          .get();

  /// Gets tiles in a specific area
  Future<List<WorldTileData>> getTilesInArea(
    String userId,
    int minX,
    int maxX,
    int minY,
    int maxY,
  ) async =>
      (select(worldTiles)
            ..where(
              (w) =>
                  w.userId.equals(userId) &
                  w.positionX.isBetweenValues(minX, maxX) &
                  w.positionY.isBetweenValues(minY, maxY),
            )
            ..orderBy([
              (w) => OrderingTerm.asc(w.positionX),
              (w) => OrderingTerm.asc(w.positionY),
            ]))
          .get();

  /// Gets tiles that can be unlocked
  Future<List<WorldTileData>> getUnlockableTiles(
    String userId,
    int currentXP,
    Map<String, int> categoryProgress,
  ) async {
    final lockedTiles = await getLockedTiles(userId);
    final unlockableTiles = <WorldTileData>[];

    for (final tile in lockedTiles) {
      if (_canUnlockTile(tile, currentXP, categoryProgress)) {
        unlockableTiles.add(tile);
      }
    }

    return unlockableTiles;
  }

  /// Creates a new world tile
  Future<void> createWorldTile(WorldTilesCompanion tile) async {
    await into(worldTiles).insert(tile);
  }

  /// Updates world tile data
  Future<bool> updateWorldTile(WorldTilesCompanion tile) async =>
      update(worldTiles).replace(tile);

  /// Unlocks a world tile
  Future<WorldTileData?> unlockTile(String tileId) async =>
      transaction(() async {
        final tile = await getWorldTileById(tileId);
        if (tile == null || tile.isUnlocked) {
          return null;
        }

        final updatedTile = WorldTilesCompanion(
          id: Value(tileId),
          isUnlocked: const Value(true),
          unlockedAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
        );

        await update(worldTiles).replace(updatedTile);
        return getWorldTileById(tileId);
      });

  /// Locks a tile (for testing/admin purposes)
  Future<bool> lockTile(String tileId) async {
    final result = await (update(worldTiles)..where((w) => w.id.equals(tileId)))
        .write(const WorldTilesCompanion(isUnlocked: Value(false)));
    return result > 0;
  }

  /// Updates tile position
  Future<bool> updateTilePosition(String tileId, int newX, int newY) async {
    if (newX < 0 || newX > 1000 || newY < 0 || newY > 1000) {
      return false;
    }

    final result = await (update(worldTiles)..where((w) => w.id.equals(tileId)))
        .write(
          WorldTilesCompanion(
            positionX: Value(newX),
            positionY: Value(newY),
            updatedAt: Value(DateTime.now()),
          ),
        );
    return result > 0;
  }

  /// Updates tile custom properties
  Future<bool> updateTileProperties(
    String tileId,
    String propertiesJson,
  ) async {
    final result = await (update(worldTiles)..where((w) => w.id.equals(tileId)))
        .write(
          WorldTilesCompanion(
            customProperties: Value(propertiesJson),
            updatedAt: Value(DateTime.now()),
          ),
        );
    return result > 0;
  }

  /// Gets tiles adjacent to a position
  Future<List<WorldTileData>> getAdjacentTiles(
    String userId,
    int x,
    int y,
  ) async =>
      (select(worldTiles)..where(
            (w) =>
                w.userId.equals(userId) &
                w.positionX.isBetweenValues(x - 1, x + 1) &
                w.positionY.isBetweenValues(y - 1, y + 1) &
                (w.positionX.equals(x) & w.positionY.equals(y)).not(),
          ))
          .get();

  /// Gets world statistics
  Future<Map<String, dynamic>> getWorldStats(String userId) async {
    final result = await customSelect(
      '''
      SELECT 
        COUNT(*) as total_tiles,
        COUNT(CASE WHEN is_unlocked = 1 THEN 1 END) as unlocked_tiles,
        COUNT(CASE WHEN is_unlocked = 0 THEN 1 END) as locked_tiles,
        COUNT(CASE WHEN tile_type = 'grass' AND is_unlocked = 1 THEN 1 END) as grass_tiles,
        COUNT(CASE WHEN tile_type = 'forest' AND is_unlocked = 1 THEN 1 END) as forest_tiles,
        COUNT(CASE WHEN tile_type = 'mountain' AND is_unlocked = 1 THEN 1 END) as mountain_tiles,
        COUNT(CASE WHEN tile_type = 'water' AND is_unlocked = 1 THEN 1 END) as water_tiles,
        COUNT(CASE WHEN tile_type = 'city' AND is_unlocked = 1 THEN 1 END) as city_tiles,
        COUNT(CASE WHEN tile_type = 'building' AND is_unlocked = 1 THEN 1 END) as building_tiles,
        COUNT(CASE WHEN tile_type = 'special' AND is_unlocked = 1 THEN 1 END) as special_tiles,
        AVG(unlock_requirement) as avg_unlock_requirement
      FROM world_tiles 
      WHERE user_id = ?
      ''',
      variables: [Variable.withString(userId)],
    ).getSingleOrNull();

    return result?.data ?? {};
  }

  /// Gets world progression data
  Future<List<Map<String, dynamic>>> getWorldProgression(String userId) async {
    final result = await customSelect(
      '''
      SELECT 
        DATE(unlocked_at) as unlock_date,
        COUNT(*) as tiles_unlocked,
        tile_type,
        AVG(unlock_requirement) as avg_requirement
      FROM world_tiles 
      WHERE user_id = ? AND is_unlocked = 1 AND unlocked_at IS NOT NULL
      GROUP BY DATE(unlocked_at), tile_type
      ORDER BY unlock_date ASC
      ''',
      variables: [Variable.withString(userId)],
    ).get();

    return result.map((row) => row.data).toList();
  }

  /// Gets world map data for rendering
  Future<List<Map<String, dynamic>>> getWorldMapData(String userId) async {
    final result = await customSelect(
      '''
      SELECT 
        id,
        name,
        tile_type,
        position_x,
        position_y,
        is_unlocked,
        unlock_requirement,
        unlock_category,
        image_path,
        custom_properties
      FROM world_tiles 
      WHERE user_id = ?
      ORDER BY position_x ASC, position_y ASC
      ''',
      variables: [Variable.withString(userId)],
    ).get();

    return result.map((row) => row.data).toList();
  }

  /// Checks and unlocks eligible tiles
  Future<List<WorldTileData>> checkAndUnlockTiles(
    String userId,
    int currentXP,
    Map<String, int> categoryProgress,
  ) async {
    final unlockedTiles = <WorldTileData>[];
    final unlockableTiles = await getUnlockableTiles(
      userId,
      currentXP,
      categoryProgress,
    );

    for (final tile in unlockableTiles) {
      final unlockedTile = await unlockTile(tile.id);
      if (unlockedTile != null) {
        unlockedTiles.add(unlockedTile);
      }
    }

    return unlockedTiles;
  }

  /// Deletes world tile
  Future<bool> deleteWorldTile(String tileId) async {
    final result = await (delete(
      worldTiles,
    )..where((w) => w.id.equals(tileId))).go();
    return result > 0;
  }

  /// Batch operations for sync
  Future<void> batchUpdateWorldTiles(
    List<WorldTilesCompanion> tileUpdates,
  ) async {
    await batch((batch) {
      for (final tile in tileUpdates) {
        batch.replace(worldTiles, tile);
      }
    });
  }

  /// Batch create world tiles
  Future<void> batchCreateWorldTiles(List<WorldTilesCompanion> newTiles) async {
    await batch((batch) {
      for (final tile in newTiles) {
        batch.insert(worldTiles, tile);
      }
    });
  }

  /// Checks if a tile can be unlocked
  bool _canUnlockTile(
    WorldTileData tile,
    int currentXP,
    Map<String, int> categoryProgress,
  ) {
    if (tile.isUnlocked) {
      return false;
    }

    // Check XP requirement
    if (currentXP < tile.unlockRequirement) {
      return false;
    }

    // Check category requirement if specified
    if (tile.unlockCategory != null) {
      final categoryXP = categoryProgress[tile.unlockCategory] ?? 0;
      return categoryXP >= tile.unlockRequirement;
    }

    return true;
  }

  /// Gets world completion percentage
  Future<double> getWorldCompletionPercentage(String userId) async {
    final stats = await getWorldStats(userId);
    final totalTiles = stats['total_tiles'] as int? ?? 0;
    final unlockedTiles = stats['unlocked_tiles'] as int? ?? 0;

    if (totalTiles == 0) {
      return 0;
    }
    return (unlockedTiles / totalTiles) * 100;
  }

  /// Optimized tile management with batch operations
  Future<List<WorldTileData>> batchUnlockTiles(List<String> tileIds) async =>
      transaction(() async {
        final unlockedTiles = <WorldTileData>[];

        for (final tileId in tileIds) {
          final unlockedTile = await unlockTile(tileId);
          if (unlockedTile != null) {
            unlockedTiles.add(unlockedTile);
          }
        }

        return unlockedTiles;
      });

  /// Analytics query methods for world progression
  Future<List<Map<String, dynamic>>> getWorldAnalytics(String userId) async {
    final result = await customSelect(
      '''
      SELECT 
        tile_type,
        COUNT(*) as total_tiles,
        COUNT(CASE WHEN is_unlocked = 1 THEN 1 END) as unlocked_tiles,
        AVG(unlock_requirement) as avg_unlock_requirement,
        MIN(unlock_requirement) as min_unlock_requirement,
        MAX(unlock_requirement) as max_unlock_requirement,
        ROUND(
          (COUNT(CASE WHEN is_unlocked = 1 THEN 1 END) * 100.0) / COUNT(*), 2
        ) as unlock_percentage,
        COUNT(CASE WHEN unlock_category IS NOT NULL THEN 1 END) as category_locked_tiles
      FROM world_tiles 
      WHERE user_id = ?
      GROUP BY tile_type
      ORDER BY unlock_percentage DESC, unlocked_tiles DESC
      ''',
      variables: [Variable.withString(userId)],
    ).get();

    return result.map((row) => row.data).toList();
  }

  /// Optimized unlock eligibility check
  Future<List<Map<String, dynamic>>> getUnlockEligibilityReport(
    String userId,
    int currentXP,
    Map<String, int> categoryProgress,
  ) async {
    final result = await customSelect(
      '''
      SELECT 
        id,
        name,
        tile_type,
        unlock_requirement,
        unlock_category,
        position_x,
        position_y,
        CASE 
          WHEN unlock_category IS NULL THEN 
            CASE WHEN ? >= unlock_requirement THEN 1 ELSE 0 END
          ELSE 0
        END as xp_eligible
      FROM world_tiles 
      WHERE user_id = ? AND is_unlocked = 0
      ORDER BY unlock_requirement ASC, tile_type
      ''',
      variables: [Variable.withInt(currentXP), Variable.withString(userId)],
    ).get();

    final eligibilityReport = <Map<String, dynamic>>[];

    for (final row in result) {
      final data = Map<String, dynamic>.from(row.data);
      final unlockCategory = data['unlock_category'] as String?;

      if (unlockCategory != null) {
        final categoryXP = categoryProgress[unlockCategory] ?? 0;
        final unlockReq = data['unlock_requirement'] as int;
        data['category_eligible'] = categoryXP >= unlockReq ? 1 : 0;
        data['category_xp'] = categoryXP;
      }

      eligibilityReport.add(data);
    }

    return eligibilityReport;
  }
}
