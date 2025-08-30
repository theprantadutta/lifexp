import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:drift/drift.dart';

import '../../shared/services/offline_manager.dart';
import '../database/database.dart';
import '../models/achievement.dart';
import '../models/sync_operation.dart';

/// Repository for managing achievement data with flexible unlock logic
class AchievementRepository {
  AchievementRepository({
    required LifeXPDatabase database,
    OfflineManager? offlineManager,
  }) : _database = database,
       _offlineManager = offlineManager ?? OfflineManager();

  final LifeXPDatabase _database;
  final OfflineManager _offlineManager;

  // Cache for achievement data
  final Map<String, List<Achievement>> _achievementCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};

  // Cache expiration time (10 minutes for achievements as they change less frequently)
  static const Duration _cacheExpiration = Duration(minutes: 10);

  // Stream controllers for real-time updates
  final Map<String, StreamController<List<Achievement>>>
  _achievementStreamControllers = {};
  final Map<String, StreamController<Achievement>>
  _singleAchievementStreamControllers = {};
  final StreamController<Achievement> _unlockNotificationController =
      StreamController<Achievement>.broadcast();

  /// Gets all achievements for a user with caching
  Future<List<Achievement>> getAchievementsByUserId(String userId) async {
    // Check cache first
    final cachedAchievements = _getCachedAchievements(userId);
    if (cachedAchievements != null) {
      return cachedAchievements;
    }

    // Fetch from database
    final achievementDataList = await _database.achievementDao
        .getAchievementsByUserId(userId);
    final achievements = achievementDataList.map(_convertFromData).toList();

    _cacheAchievements(userId, achievements);
    return achievements;
  }

  /// Gets achievement by ID
  Future<Achievement?> getAchievementById(String achievementId) async {
    // Check if achievement exists in any cached list
    final cachedAchievement = _getCachedAchievementById(achievementId);
    if (cachedAchievement != null) {
      return cachedAchievement;
    }

    // Fetch from database
    final achievementData = await _database.achievementDao.getAchievementById(
      achievementId,
    );
    if (achievementData == null) return null;

    return _convertFromData(achievementData);
  }

  /// Gets unlocked achievements
  Future<List<Achievement>> getUnlockedAchievements(String userId) async {
    final achievementDataList = await _database.achievementDao
        .getUnlockedAchievements(userId);
    return achievementDataList.map(_convertFromData).toList();
  }

  /// Gets locked achievements with progress
  Future<List<Achievement>> getLockedAchievements(String userId) async {
    final achievementDataList = await _database.achievementDao
        .getLockedAchievements(userId);
    return achievementDataList.map(_convertFromData).toList();
  }

  /// Gets achievements by type
  Future<List<Achievement>> getAchievementsByType(
    String userId,
    AchievementType type,
  ) async {
    final achievementDataList = await _database.achievementDao
        .getAchievementsByType(userId, type.name);
    return achievementDataList.map(_convertFromData).toList();
  }

  /// Gets achievements that can be unlocked right now
  Future<List<Achievement>> getUnlockableAchievements(String userId) async {
    final achievementDataList = await _database.achievementDao
        .getUnlockableAchievements(userId);
    return achievementDataList.map(_convertFromData).toList();
  }

  /// Creates a new achievement
  Future<Achievement> createAchievement({
    required String userId,
    required String title,
    required String description,
    required String iconPath,
    required AchievementType type,
    required AchievementCriteria criteria,
  }) async {
    final achievementId = _generateId();
    final achievement = Achievement.create(
      id: achievementId,
      title: title,
      description: description,
      iconPath: iconPath,
      type: type,
      criteria: criteria,
    );

    final companion = _convertToCompanion(achievement, userId);
    await _database.achievementDao.createAchievement(companion);

    // Queue for sync
    await _queueSyncOperation(
      SyncOperation.create(
        entityType: 'achievement',
        entityId: achievementId,
        data: achievement.toMap()..['userId'] = userId,
      ),
    );

    // Invalidate cache and notify listeners
    _invalidateUserCache(userId);
    await _notifyAchievementListUpdate(userId);

    return achievement;
  }

  /// Updates achievement progress with intelligent criteria evaluation
  Future<Achievement?> updateProgress(
    String achievementId,
    int newProgress,
  ) async {
    final achievementData = await _database.achievementDao.updateProgress(
      achievementId,
      newProgress,
    );

    if (achievementData == null) return null;

    final updatedAchievement = _convertFromData(achievementData);

    // Check if achievement was just unlocked
    if (updatedAchievement.isUnlocked &&
        updatedAchievement.unlockedAt != null) {
      final timeSinceUnlock = DateTime.now().difference(
        updatedAchievement.unlockedAt!,
      );
      if (timeSinceUnlock.inSeconds < 5) {
        // Recently unlocked
        _notifyAchievementUnlock(updatedAchievement);
      }
    }

    // Invalidate cache and notify listeners
    _invalidateAllCaches();
    await _notifyAchievementListUpdate(achievementData.userId);
    _notifySingleAchievementUpdate(updatedAchievement);

    return updatedAchievement;
  }

  /// Increments achievement progress
  Future<Achievement?> incrementProgress(
    String achievementId,
    int amount,
  ) async {
    if (amount <= 0) return null;

    final achievementData = await _database.achievementDao.incrementProgress(
      achievementId,
      amount,
    );

    if (achievementData == null) return null;

    final updatedAchievement = _convertFromData(achievementData);

    // Check if achievement was just unlocked
    if (updatedAchievement.isUnlocked &&
        updatedAchievement.unlockedAt != null) {
      final timeSinceUnlock = DateTime.now().difference(
        updatedAchievement.unlockedAt!,
      );
      if (timeSinceUnlock.inSeconds < 5) {
        // Recently unlocked
        _notifyAchievementUnlock(updatedAchievement);
      }
    }

    // Invalidate cache and notify listeners
    _invalidateAllCaches();
    await _notifyAchievementListUpdate(achievementData.userId);
    _notifySingleAchievementUpdate(updatedAchievement);

    return updatedAchievement;
  }

  /// Unlocks achievement manually
  Future<bool> unlockAchievement(String achievementId) async {
    final success = await _database.achievementDao.unlockAchievement(
      achievementId,
    );

    if (success) {
      final unlockedAchievement = await getAchievementById(achievementId);
      if (unlockedAchievement != null) {
        _notifyAchievementUnlock(unlockedAchievement);
        _invalidateAllCaches();
        _notifySingleAchievementUpdate(unlockedAchievement);
      }
    }

    return success;
  }

  /// Comprehensive achievement checking based on user statistics
  Future<List<Achievement>> checkAndUpdateAchievements(
    String userId,
    Map<String, dynamic> userStats,
  ) async {
    final newlyUnlockedAchievements = await _database.achievementDao
        .checkAndUpdateAchievements(userId, userStats);

    final achievements = newlyUnlockedAchievements
        .map(_convertFromData)
        .toList();

    // Notify about newly unlocked achievements
    for (final achievement in achievements) {
      _notifyAchievementUnlock(achievement);
    }

    // Invalidate cache and notify listeners
    if (achievements.isNotEmpty) {
      _invalidateUserCache(userId);
      await _notifyAchievementListUpdate(userId);
    }

    return achievements;
  }

  /// Batch check criteria for multiple achievements with optimization
  Future<List<Achievement>> batchCheckCriteria(
    String userId,
    Map<String, dynamic> userStats,
  ) async {
    final newlyUnlockedAchievements = await _database.achievementDao
        .batchCheckCriteria(userId, userStats);

    final achievements = newlyUnlockedAchievements
        .map(_convertFromData)
        .toList();

    // Notify about newly unlocked achievements
    for (final achievement in achievements) {
      _notifyAchievementUnlock(achievement);
    }

    // Invalidate cache and notify listeners
    if (achievements.isNotEmpty) {
      _invalidateUserCache(userId);
      await _notifyAchievementListUpdate(userId);
    }

    return achievements;
  }

  /// Evaluates specific achievement criteria
  bool evaluateAchievementCriteria(
    Achievement achievement,
    Map<String, dynamic> userStats,
  ) {
    if (achievement.isUnlocked) return true;

    switch (achievement.type) {
      case AchievementType.streak:
        return _evaluateStreakCriteria(achievement.criteria, userStats);

      case AchievementType.total:
        return _evaluateTotalCriteria(achievement.criteria, userStats);

      case AchievementType.milestone:
        return _evaluateMilestoneCriteria(achievement.criteria, userStats);

      case AchievementType.category:
        return _evaluateCategoryCriteria(achievement.criteria, userStats);

      case AchievementType.level:
        return _evaluateLevelCriteria(achievement.criteria, userStats);

      case AchievementType.special:
        return _evaluateSpecialCriteria(achievement.criteria, userStats);
    }
  }

  /// Calculates progress for achievement based on user stats
  int calculateAchievementProgress(
    Achievement achievement,
    Map<String, dynamic> userStats,
  ) {
    switch (achievement.type) {
      case AchievementType.streak:
        return _calculateStreakProgress(achievement.criteria, userStats);

      case AchievementType.total:
        return _calculateTotalProgress(achievement.criteria, userStats);

      case AchievementType.milestone:
        return _calculateMilestoneProgress(achievement.criteria, userStats);

      case AchievementType.category:
        return _calculateCategoryProgress(achievement.criteria, userStats);

      case AchievementType.level:
        return _calculateLevelProgress(achievement.criteria, userStats);

      case AchievementType.special:
        return _calculateSpecialProgress(achievement.criteria, userStats);
    }
  }

  /// Gets achievement statistics
  Future<Map<String, dynamic>> getAchievementStats(String userId) async => _database.achievementDao.getAchievementStats(userId);

  /// Gets recent achievement unlocks
  Future<List<Achievement>> getRecentUnlocks(
    String userId, {
    int days = 7,
  }) async {
    final achievementDataList = await _database.achievementDao.getRecentUnlocks(
      userId,
      days: days,
    );
    return achievementDataList.map(_convertFromData).toList();
  }

  /// Gets progress monitoring data
  Future<List<Map<String, dynamic>>> getProgressMonitoring(
    String userId,
  ) async => _database.achievementDao.getProgressMonitoring(userId);

  /// Creates default achievements for a new user
  Future<void> createDefaultAchievements(String userId) async {
    final defaultAchievements = _getDefaultAchievements();

    for (final achievementData in defaultAchievements) {
      final achievement = Achievement.create(
        id: _generateId(),
        title: achievementData['title'] as String,
        description: achievementData['description'] as String,
        iconPath: achievementData['iconPath'] as String,
        type: achievementData['type'] as AchievementType,
        criteria: achievementData['criteria'] as AchievementCriteria,
      );

      final companion = _convertToCompanion(achievement, userId);
      await _database.achievementDao.createAchievement(companion);
    }

    // Invalidate cache
    _invalidateUserCache(userId);
  }

  /// Gets achievement unlock notification stream
  Stream<Achievement> get achievementUnlockStream =>
      _unlockNotificationController.stream;

  /// Gets achievement list stream for real-time updates
  Stream<List<Achievement>> getAchievementsStream(String userId) {
    if (!_achievementStreamControllers.containsKey(userId)) {
      _achievementStreamControllers[userId] =
          StreamController<List<Achievement>>.broadcast();
    }
    return _achievementStreamControllers[userId]!.stream;
  }

  /// Gets single achievement stream for real-time updates
  Stream<Achievement> getAchievementStream(String achievementId) {
    if (!_singleAchievementStreamControllers.containsKey(achievementId)) {
      _singleAchievementStreamControllers[achievementId] =
          StreamController<Achievement>.broadcast();
    }
    return _singleAchievementStreamControllers[achievementId]!.stream;
  }

  /// Batch operations for sync
  Future<void> batchUpdateAchievements(
    List<Achievement> achievements,
    String userId,
  ) async {
    final companions = achievements
        .map((achievement) => _convertToCompanion(achievement, userId))
        .toList();
    await _database.achievementDao.batchUpdateAchievements(companions);

    // Clear cache and notify
    _invalidateUserCache(userId);
    await _notifyAchievementListUpdate(userId);
  }

  /// Sync achievement data with cloud (placeholder for future implementation)
  Future<void> syncAchievementData(String userId) async {
    // This would implement cloud sync logic
    // For now, just refresh cache
    _invalidateUserCache(userId);
  }

  /// Disposes resources
  void dispose() {
    for (final controller in _achievementStreamControllers.values) {
      controller.close();
    }
    for (final controller in _singleAchievementStreamControllers.values) {
      controller.close();
    }
    _unlockNotificationController.close();
    _achievementStreamControllers.clear();
    _singleAchievementStreamControllers.clear();
    _clearCache();
  }

  // Private helper methods

  /// Gets cached achievements for user
  List<Achievement>? _getCachedAchievements(String userId) {
    if (_achievementCache.containsKey(userId) && _isCacheValid(userId)) {
      return _achievementCache[userId];
    }
    return null;
  }

  /// Gets cached achievement by ID from any user's cache
  Achievement? _getCachedAchievementById(String achievementId) {
    for (final achievements in _achievementCache.values) {
      final achievement = achievements
          .where((a) => a.id == achievementId)
          .firstOrNull;
      if (achievement != null) return achievement;
    }
    return null;
  }

  /// Caches achievements for user
  void _cacheAchievements(String userId, List<Achievement> achievements) {
    _achievementCache[userId] = achievements;
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
    _achievementCache.remove(userId);
    _cacheTimestamps.remove(userId);
  }

  /// Invalidates all caches
  void _invalidateAllCaches() {
    _achievementCache.clear();
    _cacheTimestamps.clear();
  }

  /// Clears all cache
  void _clearCache() {
    _achievementCache.clear();
    _cacheTimestamps.clear();
  }

  /// Notifies achievement unlock
  void _notifyAchievementUnlock(Achievement achievement) {
    if (!_unlockNotificationController.isClosed) {
      _unlockNotificationController.add(achievement);
    }
  }

  /// Notifies achievement list update
  Future<void> _notifyAchievementListUpdate(String userId) async {
    final controller = _achievementStreamControllers[userId];
    if (controller != null && !controller.isClosed) {
      final achievements = await getAchievementsByUserId(userId);
      controller.add(achievements);
    }
  }

  /// Notifies single achievement update
  void _notifySingleAchievementUpdate(Achievement achievement) {
    final controller = _singleAchievementStreamControllers[achievement.id];
    if (controller != null && !controller.isClosed) {
      controller.add(achievement);
    }
  }

  // Criteria evaluation methods

  /// Evaluates streak criteria
  bool _evaluateStreakCriteria(
    AchievementCriteria criteria,
    Map<String, dynamic> userStats,
  ) {
    final currentStreak = userStats['currentStreak'] as int? ?? 0;
    final maxStreak = userStats['maxStreak'] as int? ?? 0;
    return maxStreak >= criteria.targetValue ||
        currentStreak >= criteria.targetValue;
  }

  /// Evaluates total criteria
  bool _evaluateTotalCriteria(
    AchievementCriteria criteria,
    Map<String, dynamic> userStats,
  ) {
    if (criteria.category != null) {
      final categoryTotals =
          userStats['categoryTotals'] as Map<String, dynamic>? ?? {};
      final categoryTotal = categoryTotals[criteria.category] as int? ?? 0;
      return categoryTotal >= criteria.targetValue;
    }
    final totalTasks = userStats['totalTasksCompleted'] as int? ?? 0;
    return totalTasks >= criteria.targetValue;
  }

  /// Evaluates milestone criteria
  bool _evaluateMilestoneCriteria(
    AchievementCriteria criteria,
    Map<String, dynamic> userStats,
  ) {
    final totalXP = userStats['totalXP'] as int? ?? 0;
    return totalXP >= criteria.targetValue;
  }

  /// Evaluates category criteria
  bool _evaluateCategoryCriteria(
    AchievementCriteria criteria,
    Map<String, dynamic> userStats,
  ) {
    if (criteria.category == null) return false;
    final categoryTotals =
        userStats['categoryTotals'] as Map<String, dynamic>? ?? {};
    final categoryTotal = categoryTotals[criteria.category] as int? ?? 0;
    return categoryTotal >= criteria.targetValue;
  }

  /// Evaluates level criteria
  bool _evaluateLevelCriteria(
    AchievementCriteria criteria,
    Map<String, dynamic> userStats,
  ) {
    final level = userStats['level'] as int? ?? 1;
    return level >= criteria.targetValue;
  }

  /// Evaluates special criteria
  bool _evaluateSpecialCriteria(
    AchievementCriteria criteria,
    Map<String, dynamic> userStats,
  ) {
    // Special achievements have custom logic based on customCriteria
    for (final entry in criteria.customCriteria.entries) {
      final key = entry.key;
      final requiredValue = entry.value;
      final actualValue = userStats[key];

      if (actualValue == null) return false;

      if (actualValue is int && requiredValue is int) {
        if (actualValue < requiredValue) return false;
      } else if (actualValue is bool && requiredValue is bool) {
        if (actualValue != requiredValue) return false;
      } else if (actualValue is String && requiredValue is String) {
        if (actualValue != requiredValue) return false;
      }
    }
    return true;
  }

  // Progress calculation methods

  /// Calculates streak progress
  int _calculateStreakProgress(
    AchievementCriteria criteria,
    Map<String, dynamic> userStats,
  ) {
    final maxStreak = userStats['maxStreak'] as int? ?? 0;
    return maxStreak;
  }

  /// Calculates total progress
  int _calculateTotalProgress(
    AchievementCriteria criteria,
    Map<String, dynamic> userStats,
  ) {
    if (criteria.category != null) {
      final categoryTotals =
          userStats['categoryTotals'] as Map<String, dynamic>? ?? {};
      return categoryTotals[criteria.category] as int? ?? 0;
    }
    return userStats['totalTasksCompleted'] as int? ?? 0;
  }

  /// Calculates milestone progress
  int _calculateMilestoneProgress(
    AchievementCriteria criteria,
    Map<String, dynamic> userStats,
  ) => userStats['totalXP'] as int? ?? 0;

  /// Calculates category progress
  int _calculateCategoryProgress(
    AchievementCriteria criteria,
    Map<String, dynamic> userStats,
  ) {
    if (criteria.category == null) return 0;
    final categoryTotals =
        userStats['categoryTotals'] as Map<String, dynamic>? ?? {};
    return categoryTotals[criteria.category] as int? ?? 0;
  }

  /// Calculates level progress
  int _calculateLevelProgress(
    AchievementCriteria criteria,
    Map<String, dynamic> userStats,
  ) => userStats['level'] as int? ?? 1;

  /// Calculates special progress
  int _calculateSpecialProgress(
    AchievementCriteria criteria,
    Map<String, dynamic> userStats,
  ) {
    // For special achievements, return the minimum progress across all criteria
    var minProgress = criteria.targetValue;

    for (final entry in criteria.customCriteria.entries) {
      final key = entry.key;
      final requiredValue = entry.value;
      final actualValue = userStats[key] as int? ?? 0;

      if (requiredValue is int) {
        final progress = (actualValue / requiredValue * criteria.targetValue)
            .round();
        minProgress = minProgress < progress ? minProgress : progress;
      }
    }

    return minProgress;
  }

  /// Gets default achievements for new users
  List<Map<String, dynamic>> _getDefaultAchievements() => [
      {
        'title': 'First Steps',
        'description': 'Complete your first task',
        'iconPath': 'assets/icons/achievements/first_steps.png',
        'type': AchievementType.total,
        'criteria': AchievementCriteria.total(1),
      },
      {
        'title': 'Rookie Hustler',
        'description': 'Maintain a 7-day streak',
        'iconPath': 'assets/icons/achievements/rookie_hustler.png',
        'type': AchievementType.streak,
        'criteria': AchievementCriteria.streak(7),
      },
      {
        'title': 'XP Hoarder',
        'description': 'Complete 100 tasks',
        'iconPath': 'assets/icons/achievements/xp_hoarder.png',
        'type': AchievementType.total,
        'criteria': AchievementCriteria.total(100),
      },
      {
        'title': 'Level Up!',
        'description': 'Reach level 10',
        'iconPath': 'assets/icons/achievements/level_up.png',
        'type': AchievementType.level,
        'criteria': AchievementCriteria.level(10),
      },
      {
        'title': 'Health Warrior',
        'description': 'Complete 50 health tasks',
        'iconPath': 'assets/icons/achievements/health_warrior.png',
        'type': AchievementType.category,
        'criteria': AchievementCriteria.category('health', 50),
      },
      {
        'title': 'Money Master',
        'description': 'Complete 50 finance tasks',
        'iconPath': 'assets/icons/achievements/money_master.png',
        'type': AchievementType.category,
        'criteria': AchievementCriteria.category('finance', 50),
      },
      {
        'title': 'Work Hero',
        'description': 'Complete 50 work tasks',
        'iconPath': 'assets/icons/achievements/work_hero.png',
        'type': AchievementType.category,
        'criteria': AchievementCriteria.category('work', 50),
      },
      {
        'title': 'Streak Master',
        'description': 'Maintain a 30-day streak',
        'iconPath': 'assets/icons/achievements/streak_master.png',
        'type': AchievementType.streak,
        'criteria': AchievementCriteria.streak(30),
      },
      {
        'title': 'XP Millionaire',
        'description': 'Earn 10,000 XP',
        'iconPath': 'assets/icons/achievements/xp_millionaire.png',
        'type': AchievementType.milestone,
        'criteria': AchievementCriteria.milestone(10000),
      },
      {
        'title': 'Legendary',
        'description': 'Reach level 50',
        'iconPath': 'assets/icons/achievements/legendary.png',
        'type': AchievementType.level,
        'criteria': AchievementCriteria.level(50),
      },
    ];

  /// Converts database data to Achievement model
  Achievement _convertFromData(AchievementData data) {
    final criteriaMap = json.decode(data.criteria) as Map<String, dynamic>;
    final criteria = AchievementCriteria.fromJson(criteriaMap);

    return Achievement(
      id: data.id,
      title: data.title,
      description: data.description,
      iconPath: data.iconPath,
      type: AchievementType.values.byName(data.achievementType),
      criteria: criteria,
      isUnlocked: data.isUnlocked,
      unlockedAt: data.unlockedAt,
      progress: data.progress,
      createdAt: data.createdAt,
      updatedAt: data.updatedAt,
    );
  }

  /// Converts Achievement model to database companion
  AchievementsCompanion _convertToCompanion(
    Achievement achievement,
    String userId,
  ) => AchievementsCompanion.insert(
      id: achievement.id,
      userId: userId,
      achievementType: achievement.type.name,
      title: achievement.title,
      description: achievement.description,
      iconPath: achievement.iconPath,
      criteria: json.encode(achievement.criteria.toJson()),
      isUnlocked: Value(achievement.isUnlocked),
      unlockedAt: Value(achievement.unlockedAt),
      progress: Value(achievement.progress),
      createdAt: achievement.createdAt,
      updatedAt: achievement.updatedAt,
    );

  /// Generates unique ID
  String _generateId() => DateTime.now().millisecondsSinceEpoch.toString();

  /// Queue sync operation for offline support
  Future<void> _queueSyncOperation(SyncOperation operation) async {
    try {
      await _offlineManager.queueSyncOperation(operation);
    } catch (e) {
      developer.log('Failed to queue sync operation: $e', name: 'AchievementRepository');
      // Continue execution - offline support is not critical for core functionality
    }
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
