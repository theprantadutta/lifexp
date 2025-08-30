import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:drift/drift.dart';

import '../../shared/services/offline_manager.dart';
import '../database/database.dart';
import '../models/avatar.dart';
import '../models/sync_operation.dart';

/// Repository for managing avatar data with intelligent caching
class AvatarRepository {
  AvatarRepository({
    required LifeXPDatabase database,
    OfflineManager? offlineManager,
  }) : _database = database,
       _offlineManager = offlineManager ?? OfflineManager();

  final LifeXPDatabase _database;
  final OfflineManager _offlineManager;

  // Cache for frequently accessed avatar data
  final Map<String, Avatar> _avatarCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};

  // Cache expiration time (5 minutes)
  static const Duration _cacheExpiration = Duration(minutes: 5);

  // Stream controllers for real-time updates
  final Map<String, StreamController<Avatar>> _avatarStreamControllers = {};

  /// Gets avatar by user ID with caching
  Future<Avatar?> getAvatarByUserId(String userId) async {
    // Check cache first
    final cachedAvatar = _getCachedAvatar(userId);
    if (cachedAvatar != null) {
      return cachedAvatar;
    }

    // Fetch from database
    final avatarData = await _database.avatarDao.getAvatarByUserId(userId);
    if (avatarData == null) {
      return null;
    }

    final avatar = _convertFromData(avatarData);
    _cacheAvatar(userId, avatar);
    return avatar;
  }

  /// Gets avatar by ID with caching
  Future<Avatar?> getAvatarById(String avatarId) async {
    // Check cache first
    final cachedAvatar = _getCachedAvatarById(avatarId);
    if (cachedAvatar != null) {
      return cachedAvatar;
    }

    // Fetch from database
    final avatarData = await _database.avatarDao.getAvatarById(avatarId);
    if (avatarData == null) {
      return null;
    }

    final avatar = _convertFromData(avatarData);
    _cacheAvatarById(avatarId, avatar);
    return avatar;
  }

  /// Creates a new avatar
  Future<Avatar> createAvatar({
    required String userId,
    required String name,
    AvatarAppearance? appearance,
  }) async {
    final avatarId = _generateId();
    final avatar = Avatar.create(
      id: avatarId,
      name: name,
      appearance: appearance,
    );

    final companion = _convertToCompanion(avatar, userId);
    await _database.avatarDao.createAvatar(companion);

    // Queue for sync
    await _queueSyncOperation(
      SyncOperation.create(
        entityType: 'avatar',
        entityId: avatarId,
        data: avatar.toMap()..['userId'] = userId,
      ),
    );

    // Cache the new avatar
    _cacheAvatar(userId, avatar);
    _cacheAvatarById(avatarId, avatar);

    // Notify listeners
    _notifyAvatarUpdate(avatar);

    return avatar;
  }

  /// Gains XP and handles level progression with optimized caching
  Future<Avatar?> gainXP(String avatarId, int xpAmount) async {
    if (xpAmount <= 0) return null;

    // Get current avatar (from cache if available)
    final currentAvatar = await getAvatarById(avatarId);
    if (currentAvatar == null) return null;

    // Update database
    final avatarData = await _database.avatarDao.updateAvatarXP(
      avatarId,
      xpAmount,
    );
    if (avatarData == null) return null;

    final finalAvatar = _convertFromData(avatarData);

    // Queue for sync
    await _queueSyncOperation(
      SyncOperation.update(
        entityType: 'avatar',
        entityId: avatarId,
        data: finalAvatar.toMap()..['userId'] = avatarData.userId,
      ),
    );

    // Update cache
    _updateCacheForAvatar(finalAvatar);

    // Notify listeners
    _notifyAvatarUpdate(finalAvatar);

    return finalAvatar;
  }

  /// Increases specific attribute with caching
  Future<Avatar?> increaseAttribute(
    String avatarId,
    AttributeType attributeType,
    int amount,
  ) async {
    if (amount <= 0) return null;

    final success = await _database.avatarDao.updateAttribute(
      avatarId,
      attributeType.name,
      amount,
    );

    if (!success) return null;

    // Invalidate cache and fetch updated data
    _invalidateAvatarCache(avatarId);
    final updatedAvatar = await getAvatarById(avatarId);

    if (updatedAvatar != null) {
      _notifyAvatarUpdate(updatedAvatar);
    }

    return updatedAvatar;
  }

  /// Updates avatar appearance with caching
  Future<Avatar?> updateAppearance(
    String avatarId,
    AvatarAppearance appearance,
  ) async {
    final appearanceJson = json.encode(appearance.toJson());
    final success = await _database.avatarDao.updateAppearance(
      avatarId,
      appearanceJson,
    );

    if (!success) return null;

    // Invalidate cache and fetch updated data
    _invalidateAvatarCache(avatarId);
    final updatedAvatar = await getAvatarById(avatarId);

    if (updatedAvatar != null) {
      _notifyAvatarUpdate(updatedAvatar);
    }

    return updatedAvatar;
  }

  /// Unlocks item for avatar with caching
  Future<bool> unlockItem(String avatarId, String itemId) async {
    final success = await _database.avatarDao.unlockItem(avatarId, itemId);

    if (success) {
      // Invalidate cache and notify update
      _invalidateAvatarCache(avatarId);
      final updatedAvatar = await getAvatarById(avatarId);
      if (updatedAvatar != null) {
        _notifyAvatarUpdate(updatedAvatar);
      }
    }

    return success;
  }

  /// Gets avatar progression stats with caching
  Future<Map<String, dynamic>> getProgressionStats(String userId) async {
    final stats = await _database.avatarDao.getAvatarProgressionStats(userId);
    return stats.isNotEmpty ? stats.first : {};
  }

  /// Gets level progression data with caching
  Future<Map<String, dynamic>> getLevelProgressionData(String userId) async {
    final data = await _database.avatarDao.getLevelProgressionData(userId);
    return data.isNotEmpty ? data.first : {};
  }

  /// Gets avatar statistics
  Future<Map<String, dynamic>> getAvatarStats(String avatarId) async => _database.avatarDao.getAvatarStats(avatarId);

  /// Calculates XP bonus based on consistency and difficulty
  int calculateXPBonus({
    required int baseXP,
    required int streakCount,
    required int difficulty,
    bool isConsistencyBonus = false,
  }) {
    var bonus = 0;

    // Streak bonus (up to 50% bonus for 30+ day streaks)
    if (streakCount > 0) {
      final streakMultiplier = (streakCount / 30).clamp(0.0, 0.5);
      bonus += (baseXP * streakMultiplier).round();
    }

    // Difficulty bonus (higher difficulty = more bonus)
    final difficultyMultiplier = (difficulty - 1) * 0.1;
    bonus += (baseXP * difficultyMultiplier).round();

    // Consistency bonus for completing tasks regularly
    if (isConsistencyBonus) {
      bonus += (baseXP * 0.2).round();
    }

    return bonus;
  }

  /// Determines unlockable items based on level and achievements
  List<String> getUnlockableItems(
    int level,
    List<String> unlockedAchievements,
  ) {
    final unlockableItems = <String>[];

    // Level-based unlocks
    if (level >= 5) unlockableItems.add('basic_sword');
    if (level >= 10) unlockableItems.add('leather_armor');
    if (level >= 15) unlockableItems.add('magic_staff');
    if (level >= 20) unlockableItems.add('steel_armor');
    if (level >= 25) unlockableItems.add('enchanted_cloak');
    if (level >= 30) unlockableItems.add('dragon_sword');
    if (level >= 40) unlockableItems.add('mythril_armor');
    if (level >= 50) unlockableItems.add('legendary_weapon');

    // Achievement-based unlocks
    if (unlockedAchievements.contains('first_week_streak')) {
      unlockableItems.add('dedication_badge');
    }
    if (unlockedAchievements.contains('hundred_tasks')) {
      unlockableItems.add('productivity_crown');
    }
    if (unlockedAchievements.contains('strength_master')) {
      unlockableItems.add('warrior_helmet');
    }
    if (unlockedAchievements.contains('wisdom_master')) {
      unlockableItems.add('sage_robes');
    }
    if (unlockedAchievements.contains('intelligence_master')) {
      unlockableItems.add('scholar_glasses');
    }

    return unlockableItems;
  }

  /// Gets real-time avatar updates stream
  Stream<Avatar> getAvatarStream(String avatarId) {
    if (!_avatarStreamControllers.containsKey(avatarId)) {
      _avatarStreamControllers[avatarId] = StreamController<Avatar>.broadcast();
    }
    return _avatarStreamControllers[avatarId]!.stream;
  }

  /// Batch update for sync operations
  Future<void> batchUpdateAvatars(List<Avatar> avatars) async {
    final companions = avatars
        .map((avatar) => _convertToCompanion(avatar, ''))
        .toList();
    await _database.avatarDao.batchUpdateAvatars(companions);

    // Clear cache to ensure fresh data
    _clearCache();
  }

  /// Sync avatar data with cloud (placeholder for future implementation)
  Future<void> syncAvatarData(String userId) async {
    // This would implement cloud sync logic
    // For now, just refresh cache
    _invalidateUserCache(userId);
  }

  /// Disposes resources
  void dispose() {
    for (final controller in _avatarStreamControllers.values) {
      controller.close();
    }
    _avatarStreamControllers.clear();
    _clearCache();
  }

  // Private helper methods

  /// Gets cached avatar by user ID
  Avatar? _getCachedAvatar(String userId) {
    final cacheKey = 'user_$userId';
    if (_avatarCache.containsKey(cacheKey) && _isCacheValid(cacheKey)) {
      return _avatarCache[cacheKey];
    }
    return null;
  }

  /// Gets cached avatar by avatar ID
  Avatar? _getCachedAvatarById(String avatarId) {
    final cacheKey = 'avatar_$avatarId';
    if (_avatarCache.containsKey(cacheKey) && _isCacheValid(cacheKey)) {
      return _avatarCache[cacheKey];
    }
    return null;
  }

  /// Caches avatar by user ID
  void _cacheAvatar(String userId, Avatar avatar) {
    final cacheKey = 'user_$userId';
    _avatarCache[cacheKey] = avatar;
    _cacheTimestamps[cacheKey] = DateTime.now();
  }

  /// Caches avatar by avatar ID
  void _cacheAvatarById(String avatarId, Avatar avatar) {
    final cacheKey = 'avatar_$avatarId';
    _avatarCache[cacheKey] = avatar;
    _cacheTimestamps[cacheKey] = DateTime.now();
  }

  /// Updates cache for avatar (both user and avatar ID keys)
  void _updateCacheForAvatar(Avatar avatar) {
    // We need to find the user ID from existing cache or database
    // For now, just cache by avatar ID
    _cacheAvatarById(avatar.id, avatar);
  }

  /// Checks if cache entry is still valid
  bool _isCacheValid(String cacheKey) {
    final timestamp = _cacheTimestamps[cacheKey];
    if (timestamp == null) return false;
    return DateTime.now().difference(timestamp) < _cacheExpiration;
  }

  /// Invalidates cache for specific avatar
  void _invalidateAvatarCache(String avatarId) {
    final avatarKey = 'avatar_$avatarId';
    _avatarCache.remove(avatarKey);
    _cacheTimestamps.remove(avatarKey);
  }

  /// Invalidates cache for specific user
  void _invalidateUserCache(String userId) {
    final userKey = 'user_$userId';
    _avatarCache.remove(userKey);
    _cacheTimestamps.remove(userKey);
  }

  /// Clears all cache
  void _clearCache() {
    _avatarCache.clear();
    _cacheTimestamps.clear();
  }

  /// Notifies avatar update to stream listeners
  void _notifyAvatarUpdate(Avatar avatar) {
    final controller = _avatarStreamControllers[avatar.id];
    if (controller != null && !controller.isClosed) {
      controller.add(avatar);
    }
  }

  /// Converts database data to Avatar model
  Avatar _convertFromData(AvatarData data) {
    final appearanceMap =
        json.decode(data.appearanceData) as Map<String, dynamic>;
    final appearance = AvatarAppearance.fromJson(appearanceMap);
    final unlockedItems = List<String>.from(
      json.decode(data.unlockedItems) as List,
    );

    return Avatar(
      id: data.id,
      name: data.name,
      level: data.level,
      currentXP: data.currentXp,
      strength: data.strength,
      wisdom: data.wisdom,
      intelligence: data.intelligence,
      appearance: appearance,
      unlockedItems: unlockedItems,
      createdAt: data.createdAt,
      updatedAt: data.updatedAt,
    );
  }

  /// Converts Avatar model to database companion
  AvatarsCompanion _convertToCompanion(Avatar avatar, String userId) => AvatarsCompanion.insert(
      id: avatar.id,
      userId: userId,
      name: avatar.name,
      level: Value(avatar.level),
      currentXp: Value(avatar.currentXP),
      strength: Value(avatar.strength),
      wisdom: Value(avatar.wisdom),
      intelligence: Value(avatar.intelligence),
      appearanceData: Value(json.encode(avatar.appearance.toJson())),
      unlockedItems: Value(json.encode(avatar.unlockedItems)),
      createdAt: avatar.createdAt,
      updatedAt: avatar.updatedAt,
    );

  /// Generates unique ID
  String _generateId() => DateTime.now().millisecondsSinceEpoch.toString();

  /// Queue sync operation for offline support
  Future<void> _queueSyncOperation(SyncOperation operation) async {
    try {
      await _offlineManager.queueSyncOperation(operation);
    } catch (e) {
      developer.log('Failed to queue sync operation: $e', name: 'AvatarRepository');
      // Continue execution - offline support is not critical for core functionality
    }
  }
}
