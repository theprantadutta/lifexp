import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';

import '../database/database.dart';
import '../models/world.dart';

/// Repository for managing world data with tile unlocking logic
class WorldRepository {
  WorldRepository({required LifeXPDatabase database}) : _database = database;

  final LifeXPDatabase _database;

  // Cache for world tile data
  final Map<String, List<WorldTile>> _worldCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};

  // Cache expiration time (15 minutes for world data as it changes less frequently)
  static const Duration _cacheExpiration = Duration(minutes: 15);

  // Stream controllers for real-time updates
  final Map<String, StreamController<List<WorldTile>>> _worldStreamControllers =
      {};
  final StreamController<WorldTile> _tileUnlockController =
      StreamController<WorldTile>.broadcast();

  /// Gets all world tiles for a user with caching
  Future<List<WorldTile>> getWorldTilesByUserId(String userId) async {
    // Check cache first
    final cachedTiles = _getCachedWorldTiles(userId);
    if (cachedTiles != null) {
      return cachedTiles;
    }

    // Fetch from database
    final tileDataList = await _database.worldDao.getWorldTilesByUserId(userId);
    final tiles = tileDataList.map(_convertFromData).toList();

    _cacheWorldTiles(userId, tiles);
    return tiles;
  }

  /// Gets world tile by ID
  Future<WorldTile?> getWorldTileById(String tileId) async {
    // Check if tile exists in any cached list
    final cachedTile = _getCachedTileById(tileId);
    if (cachedTile != null) {
      return cachedTile;
    }

    // Fetch from database
    final tileData = await _database.worldDao.getWorldTileById(tileId);
    if (tileData == null) return null;

    return _convertFromData(tileData);
  }

  /// Gets unlocked world tiles
  Future<List<WorldTile>> getUnlockedTiles(String userId) async {
    final tileDataList = await _database.worldDao.getUnlockedTiles(userId);
    return tileDataList.map(_convertFromData).toList();
  }

  /// Gets locked world tiles
  Future<List<WorldTile>> getLockedTiles(String userId) async {
    final tileDataList = await _database.worldDao.getLockedTiles(userId);
    return tileDataList.map(_convertFromData).toList();
  }

  /// Gets tiles by type
  Future<List<WorldTile>> getTilesByType(String userId, TileType type) async {
    final tileDataList = await _database.worldDao.getTilesByType(
      userId,
      type.name,
    );
    return tileDataList.map(_convertFromData).toList();
  }

  /// Gets tiles in a specific area
  Future<List<WorldTile>> getTilesInArea(
    String userId,
    int minX,
    int maxX,
    int minY,
    int maxY,
  ) async {
    final tileDataList = await _database.worldDao.getTilesInArea(
      userId,
      minX,
      maxX,
      minY,
      maxY,
    );
    return tileDataList.map(_convertFromData).toList();
  }

  /// Gets tiles that can be unlocked based on current progress
  Future<List<WorldTile>> getUnlockableTiles(
    String userId,
    int currentXP,
    Map<String, int> categoryProgress,
  ) async {
    final tileDataList = await _database.worldDao.getUnlockableTiles(
      userId,
      currentXP,
      categoryProgress,
    );
    return tileDataList.map(_convertFromData).toList();
  }

  /// Creates a new world tile
  Future<WorldTile> createWorldTile({
    required String userId,
    required String name,
    required String imagePath,
    required TileType type,
    required int unlockRequirement,
    required int positionX,
    required int positionY,
    String description = '',
    String? unlockCategory,
    Map<String, dynamic> customProperties = const {},
  }) async {
    final tileId = _generateId();
    final tile = WorldTile.create(
      id: tileId,
      name: name,
      imagePath: imagePath,
      type: type,
      unlockRequirement: unlockRequirement,
      positionX: positionX,
      positionY: positionY,
      description: description,
      unlockCategory: unlockCategory,
      customProperties: customProperties,
    );

    final companion = _convertToCompanion(tile, userId);
    await _database.worldDao.createWorldTile(companion);

    // Invalidate cache and notify listeners
    _invalidateUserCache(userId);
    await _notifyWorldUpdate(userId);

    return tile;
  }

  /// Unlocks a world tile with validation
  Future<WorldTile?> unlockTile(
    String tileId,
    int currentXP,
    Map<String, int> categoryProgress,
  ) async {
    // Get current tile to validate unlock conditions
    final currentTile = await getWorldTileById(tileId);
    if (currentTile == null || currentTile.isUnlocked) {
      return null;
    }

    // Validate unlock conditions
    if (!currentTile.canUnlock(
      currentXP: currentXP,
      categoryProgress: categoryProgress,
    )) {
      return null;
    }

    // Unlock in database
    final tileData = await _database.worldDao.unlockTile(tileId);
    if (tileData == null) return null;

    final unlockedTile = _convertFromData(tileData);

    // Invalidate cache and notify listeners
    _invalidateAllCaches();
    await _notifyWorldUpdate(tileData.userId);
    _notifyTileUnlock(unlockedTile);

    return unlockedTile;
  }

  /// Batch unlock multiple tiles
  Future<List<WorldTile>> batchUnlockTiles(
    List<String> tileIds,
    int currentXP,
    Map<String, int> categoryProgress,
  ) async {
    final unlockedTiles = <WorldTile>[];

    for (final tileId in tileIds) {
      final unlockedTile = await unlockTile(
        tileId,
        currentXP,
        categoryProgress,
      );
      if (unlockedTile != null) {
        unlockedTiles.add(unlockedTile);
      }
    }

    return unlockedTiles;
  }

  /// Checks and unlocks eligible tiles automatically
  Future<List<WorldTile>> checkAndUnlockTiles(
    String userId,
    int currentXP,
    Map<String, int> categoryProgress,
  ) async {
    final tileDataList = await _database.worldDao.checkAndUnlockTiles(
      userId,
      currentXP,
      categoryProgress,
    );

    final unlockedTiles = tileDataList.map(_convertFromData).toList();

    // Notify about newly unlocked tiles
    for (final tile in unlockedTiles) {
      _notifyTileUnlock(tile);
    }

    // Invalidate cache and notify listeners
    if (unlockedTiles.isNotEmpty) {
      _invalidateUserCache(userId);
      await _notifyWorldUpdate(userId);
    }

    return unlockedTiles;
  }

  /// Updates tile position with validation
  Future<bool> updateTilePosition(String tileId, int newX, int newY) async {
    if (newX < 0 ||
        newX > WorldTile.maxPosition ||
        newY < 0 ||
        newY > WorldTile.maxPosition) {
      return false;
    }

    final success = await _database.worldDao.updateTilePosition(
      tileId,
      newX,
      newY,
    );

    if (success) {
      _invalidateAllCaches();
      final updatedTile = await getWorldTileById(tileId);
      if (updatedTile != null) {
        // Find user ID from tile data to notify
        final tileData = await _database.worldDao.getWorldTileById(tileId);
        if (tileData != null) {
          await _notifyWorldUpdate(tileData.userId);
        }
      }
    }

    return success;
  }

  /// Updates tile custom properties
  Future<bool> updateTileProperties(
    String tileId,
    Map<String, dynamic> properties,
  ) async {
    final propertiesJson = json.encode(properties);
    final success = await _database.worldDao.updateTileProperties(
      tileId,
      propertiesJson,
    );

    if (success) {
      _invalidateAllCaches();
      final tileData = await _database.worldDao.getWorldTileById(tileId);
      if (tileData != null) {
        await _notifyWorldUpdate(tileData.userId);
      }
    }

    return success;
  }

  /// Gets tiles adjacent to a position
  Future<List<WorldTile>> getAdjacentTiles(String userId, int x, int y) async {
    final tileDataList = await _database.worldDao.getAdjacentTiles(
      userId,
      x,
      y,
    );
    return tileDataList.map(_convertFromData).toList();
  }

  /// Gets world statistics
  Future<Map<String, dynamic>> getWorldStats(String userId) async {
    return _database.worldDao.getWorldStats(userId);
  }

  /// Gets world progression data
  Future<List<Map<String, dynamic>>> getWorldProgression(String userId) async {
    return _database.worldDao.getWorldProgression(userId);
  }

  /// Gets world map data optimized for rendering
  Future<List<Map<String, dynamic>>> getWorldMapData(String userId) async {
    return _database.worldDao.getWorldMapData(userId);
  }

  /// Gets world completion percentage
  Future<double> getWorldCompletionPercentage(String userId) async {
    return _database.worldDao.getWorldCompletionPercentage(userId);
  }

  /// Gets world analytics data
  Future<List<Map<String, dynamic>>> getWorldAnalytics(String userId) async {
    return _database.worldDao.getWorldAnalytics(userId);
  }

  /// Gets unlock eligibility report
  Future<List<Map<String, dynamic>>> getUnlockEligibilityReport(
    String userId,
    int currentXP,
    Map<String, int> categoryProgress,
  ) async {
    return _database.worldDao.getUnlockEligibilityReport(
      userId,
      currentXP,
      categoryProgress,
    );
  }

  /// Creates default world layout for new users
  Future<void> createDefaultWorld(String userId) async {
    final defaultTiles = _generateDefaultWorldLayout();

    final companions = defaultTiles.map((tileData) {
      final tile = WorldTile.create(
        id: _generateId(),
        name: tileData['name'] as String,
        imagePath: tileData['imagePath'] as String,
        type: tileData['type'] as TileType,
        unlockRequirement: tileData['unlockRequirement'] as int,
        positionX: tileData['positionX'] as int,
        positionY: tileData['positionY'] as int,
        description: tileData['description'] as String? ?? '',
        unlockCategory: tileData['unlockCategory'] as String?,
      );
      return _convertToCompanion(tile, userId);
    }).toList();

    await _database.worldDao.batchCreateWorldTiles(companions);

    // Invalidate cache
    _invalidateUserCache(userId);
  }

  /// Calculates optimal tile placement for new tiles
  List<Map<String, int>> calculateOptimalPlacements(
    List<WorldTile> existingTiles,
    int count,
  ) {
    final placements = <Map<String, int>>[];
    final occupiedPositions = existingTiles
        .map((tile) => '${tile.positionX},${tile.positionY}')
        .toSet();

    // Simple spiral placement algorithm
    var x = 0;
    var y = 0;
    var direction = 0; // 0: right, 1: down, 2: left, 3: up
    var steps = 1;
    var stepCount = 0;
    var directionChanges = 0;

    while (placements.length < count) {
      final positionKey = '$x,$y';

      if (!occupiedPositions.contains(positionKey) &&
          x >= 0 &&
          x <= WorldTile.maxPosition &&
          y >= 0 &&
          y <= WorldTile.maxPosition) {
        placements.add({'x': x, 'y': y});
        occupiedPositions.add(positionKey);
      }

      // Move in current direction
      switch (direction) {
        case 0:
          x++;
          break; // right
        case 1:
          y++;
          break; // down
        case 2:
          x--;
          break; // left
        case 3:
          y--;
          break; // up
      }

      stepCount++;

      // Change direction when needed
      if (stepCount == steps) {
        direction = (direction + 1) % 4;
        directionChanges++;
        stepCount = 0;

        // Increase steps after every two direction changes
        if (directionChanges % 2 == 0) {
          steps++;
        }
      }
    }

    return placements;
  }

  /// Gets tile unlock stream for real-time notifications
  Stream<WorldTile> get tileUnlockStream => _tileUnlockController.stream;

  /// Gets world tiles stream for real-time updates
  Stream<List<WorldTile>> getWorldTilesStream(String userId) {
    if (!_worldStreamControllers.containsKey(userId)) {
      _worldStreamControllers[userId] =
          StreamController<List<WorldTile>>.broadcast();
    }
    return _worldStreamControllers[userId]!.stream;
  }

  /// Batch operations for sync
  Future<void> batchUpdateWorldTiles(
    List<WorldTile> tiles,
    String userId,
  ) async {
    final companions = tiles
        .map((tile) => _convertToCompanion(tile, userId))
        .toList();
    await _database.worldDao.batchUpdateWorldTiles(companions);

    // Clear cache and notify
    _invalidateUserCache(userId);
    await _notifyWorldUpdate(userId);
  }

  /// Sync world data with cloud (placeholder for future implementation)
  Future<void> syncWorldData(String userId) async {
    // This would implement cloud sync logic
    // For now, just refresh cache
    _invalidateUserCache(userId);
  }

  /// Disposes resources
  void dispose() {
    for (final controller in _worldStreamControllers.values) {
      controller.close();
    }
    _tileUnlockController.close();
    _worldStreamControllers.clear();
    _clearCache();
  }

  // Private helper methods

  /// Gets cached world tiles for user
  List<WorldTile>? _getCachedWorldTiles(String userId) {
    if (_worldCache.containsKey(userId) && _isCacheValid(userId)) {
      return _worldCache[userId];
    }
    return null;
  }

  /// Gets cached tile by ID from any user's cache
  WorldTile? _getCachedTileById(String tileId) {
    for (final tiles in _worldCache.values) {
      final tile = tiles.where((t) => t.id == tileId).firstOrNull;
      if (tile != null) return tile;
    }
    return null;
  }

  /// Caches world tiles for user
  void _cacheWorldTiles(String userId, List<WorldTile> tiles) {
    _worldCache[userId] = tiles;
    _cacheTimestamps[userId] = DateTime.now();
  }

  /// Checks if cache is valid
  bool _isCacheValid(String userId) {
    final timestamp = _cacheTimestamps[userId];
    if (timestamp == null) return false;
    return DateTime.now().difference(timestamp) < _cacheExpiration;
  }

  /// Invalidates cache for specific user
  void _invalidateUserCache(String userId) {
    _worldCache.remove(userId);
    _cacheTimestamps.remove(userId);
  }

  /// Invalidates all caches
  void _invalidateAllCaches() {
    _worldCache.clear();
    _cacheTimestamps.clear();
  }

  /// Clears all cache
  void _clearCache() {
    _worldCache.clear();
    _cacheTimestamps.clear();
  }

  /// Notifies tile unlock
  void _notifyTileUnlock(WorldTile tile) {
    if (!_tileUnlockController.isClosed) {
      _tileUnlockController.add(tile);
    }
  }

  /// Notifies world update
  Future<void> _notifyWorldUpdate(String userId) async {
    final controller = _worldStreamControllers[userId];
    if (controller != null && !controller.isClosed) {
      final tiles = await getWorldTilesByUserId(userId);
      controller.add(tiles);
    }
  }

  /// Generates default world layout
  List<Map<String, dynamic>> _generateDefaultWorldLayout() {
    return [
      // Starting area - always unlocked
      {
        'name': 'Home Base',
        'imagePath': 'assets/images/world/home_base.png',
        'type': TileType.building,
        'unlockRequirement': 0,
        'positionX': 5,
        'positionY': 5,
        'description': 'Your starting point in the world',
      },

      // Basic grass tiles around home
      {
        'name': 'Green Meadow',
        'imagePath': 'assets/images/world/grass_1.png',
        'type': TileType.grass,
        'unlockRequirement': 50,
        'positionX': 4,
        'positionY': 5,
      },
      {
        'name': 'Peaceful Field',
        'imagePath': 'assets/images/world/grass_2.png',
        'type': TileType.grass,
        'unlockRequirement': 100,
        'positionX': 6,
        'positionY': 5,
      },
      {
        'name': 'Sunny Patch',
        'imagePath': 'assets/images/world/grass_3.png',
        'type': TileType.grass,
        'unlockRequirement': 150,
        'positionX': 5,
        'positionY': 4,
      },
      {
        'name': 'Flower Garden',
        'imagePath': 'assets/images/world/grass_4.png',
        'type': TileType.grass,
        'unlockRequirement': 200,
        'positionX': 5,
        'positionY': 6,
      },

      // Forest area - health category
      {
        'name': 'Whispering Woods',
        'imagePath': 'assets/images/world/forest_1.png',
        'type': TileType.forest,
        'unlockRequirement': 300,
        'positionX': 3,
        'positionY': 5,
        'unlockCategory': 'health',
      },
      {
        'name': 'Ancient Grove',
        'imagePath': 'assets/images/world/forest_2.png',
        'type': TileType.forest,
        'unlockRequirement': 500,
        'positionX': 2,
        'positionY': 5,
        'unlockCategory': 'health',
      },

      // Mountain area - work category
      {
        'name': 'Rocky Hills',
        'imagePath': 'assets/images/world/mountain_1.png',
        'type': TileType.mountain,
        'unlockRequirement': 400,
        'positionX': 7,
        'positionY': 5,
        'unlockCategory': 'work',
      },
      {
        'name': 'Peak Summit',
        'imagePath': 'assets/images/world/mountain_2.png',
        'type': TileType.mountain,
        'unlockRequirement': 800,
        'positionX': 8,
        'positionY': 5,
        'unlockCategory': 'work',
      },

      // Water area - finance category
      {
        'name': 'Crystal Lake',
        'imagePath': 'assets/images/world/water_1.png',
        'type': TileType.water,
        'unlockRequirement': 350,
        'positionX': 5,
        'positionY': 3,
        'unlockCategory': 'finance',
      },
      {
        'name': 'Golden River',
        'imagePath': 'assets/images/world/water_2.png',
        'type': TileType.water,
        'unlockRequirement': 600,
        'positionX': 5,
        'positionY': 2,
        'unlockCategory': 'finance',
      },

      // City area - high level unlocks
      {
        'name': 'Trading Post',
        'imagePath': 'assets/images/world/city_1.png',
        'type': TileType.city,
        'unlockRequirement': 1000,
        'positionX': 6,
        'positionY': 4,
      },
      {
        'name': 'Grand City',
        'imagePath': 'assets/images/world/city_2.png',
        'type': TileType.city,
        'unlockRequirement': 2000,
        'positionX': 7,
        'positionY': 4,
      },

      // Special tiles - very high requirements
      {
        'name': 'Mystic Portal',
        'imagePath': 'assets/images/world/special_1.png',
        'type': TileType.special,
        'unlockRequirement': 5000,
        'positionX': 5,
        'positionY': 7,
        'description': 'A mysterious portal to unknown realms',
      },
      {
        'name': 'Dragon\'s Lair',
        'imagePath': 'assets/images/world/special_2.png',
        'type': TileType.special,
        'unlockRequirement': 10000,
        'positionX': 9,
        'positionY': 6,
        'description': 'The legendary dragon\'s dwelling',
      },
    ];
  }

  /// Converts database data to WorldTile model
  WorldTile _convertFromData(WorldTileData data) {
    final customProperties = data.customProperties.isNotEmpty
        ? json.decode(data.customProperties) as Map<String, dynamic>
        : <String, dynamic>{};

    return WorldTile(
      id: data.id,
      name: data.name,
      description: data.description,
      imagePath: data.imagePath,
      type: TileType.values.byName(data.tileType),
      isUnlocked: data.isUnlocked,
      unlockRequirement: data.unlockRequirement,
      unlockCategory: data.unlockCategory,
      positionX: data.positionX,
      positionY: data.positionY,
      unlockedAt: data.unlockedAt,
      customProperties: customProperties,
      createdAt: data.createdAt,
      updatedAt: data.updatedAt,
    );
  }

  /// Converts WorldTile model to database companion
  WorldTilesCompanion _convertToCompanion(WorldTile tile, String userId) {
    return WorldTilesCompanion.insert(
      id: tile.id,
      userId: userId,
      name: tile.name,
      description: Value(tile.description),
      imagePath: tile.imagePath,
      tileType: tile.type.name,
      isUnlocked: Value(tile.isUnlocked),
      unlockRequirement: tile.unlockRequirement,
      unlockCategory: Value(tile.unlockCategory),
      positionX: tile.positionX,
      positionY: tile.positionY,
      unlockedAt: Value(tile.unlockedAt),
      customProperties: Value(json.encode(tile.customProperties)),
      createdAt: tile.createdAt,
      updatedAt: tile.updatedAt,
    );
  }

  /// Generates unique ID
  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
}

/// Extension to add firstOrNull method
extension FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    if (iterator.moveNext()) {
      return iterator.current;
    }
    return null;
  }
}
