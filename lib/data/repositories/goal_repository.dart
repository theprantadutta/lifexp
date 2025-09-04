import 'dart:async';
import 'dart:developer' as developer;

import 'package:drift/drift.dart';

import '../../shared/services/lru_cache_service.dart';
import '../../shared/services/offline_manager.dart';
import '../database/database.dart';
import '../models/goal.dart';
import '../models/sync_operation.dart';

/// Repository for managing goal data with progress tracking and analytics
///
/// The GoalRepository handles all data operations related to goals including
/// creation, updating, progress tracking, and analytics. It provides both
/// local database operations and synchronization capabilities for offline support.
class GoalRepository {
  GoalRepository({
    required LifeXPDatabase database,
    OfflineManager? offlineManager,
  })  : _database = database,
        _offlineManager = offlineManager ?? OfflineManager();

  final LifeXPDatabase _database;
  final OfflineManager _offlineManager;

  // LRU Cache for goal data
  final _goalCache = LRUCache<String, List<Goal>>(100); // Max 100 user entries
  final _singleGoalCache = LRUCache<String, Goal>(200); // Max 200 individual goals
  final _statsCache = LRUCache<String, Map<String, dynamic>>(50); // Max 50 stats entries

  // Cache expiration time (10 minutes for goals as they change less frequently)
  static const Duration _cacheExpiration = Duration(minutes: 10);

  // Cache timestamps for expiration tracking
  final Map<String, DateTime> _cacheTimestamps = {};

  // Stream controllers for real-time updates
  final Map<String, StreamController<List<Goal>>> _goalStreamControllers = {};
  final Map<String, StreamController<Goal>> _singleGoalStreamControllers = {};

  /// Gets all goals for a user with caching
  ///
  /// Retrieves all goals associated with the specified user ID. Results are
  /// cached for performance optimization.
  Future<List<Goal>> getGoalsByUserId(String userId) async {
    // Check cache first
    final cachedGoals = _getCachedGoals(userId);
    if (cachedGoals != null) {
      return cachedGoals;
    }

    // Fetch from database
    final goalDataList = await _database.goalDao.getGoalsByUserId(userId);
    final goals = goalDataList.map(_convertFromData).toList();

    _cacheGoals(userId, goals);
    return goals;
  }

  /// Gets goal by ID
  ///
  /// Retrieves a specific goal by its unique identifier.
  Future<Goal?> getGoalById(String goalId) async {
    // Check if goal exists in any cached list
    final cachedGoal = _getCachedGoalById(goalId);
    if (cachedGoal != null) {
      return cachedGoal;
    }

    // Fetch from database
    final goalData = await _database.goalDao.getGoalById(goalId);
    if (goalData == null) return null;

    return _convertFromData(goalData);
  }

  /// Creates a new goal
  ///
  /// Creates a new goal with the specified parameters and saves it to the local
  /// database. The operation is queued for synchronization with the cloud.
  Future<Goal> createGoal({
    required String userId,
    required String title,
    required GoalCategory category,
    required DateTime deadline,
    String description = '',
    GoalPriority priority = GoalPriority.medium,
    DateTime? startDate,
  }) async {
    final goalId = _generateId();
    final goal = Goal.create(
      id: goalId,
      userId: userId,
      title: title,
      category: category,
      deadline: deadline,
      description: description,
      priority: priority,
      startDate: startDate,
    );

    final companion = _convertToCompanion(goal);
    await _database.goalDao.createGoal(companion);

    // Queue for sync
    await _queueSyncOperation(
      SyncOperation.create(
        entityType: 'goal',
        entityId: goalId,
        data: goal.toMap(),
      ),
    );

    // Invalidate cache and notify listeners
    _invalidateUserCache(userId);
    await _notifyGoalListUpdate(userId);

    return goal;
  }

  /// Updates an existing goal
  ///
  /// Updates the specified goal with new values. Performs validation before
  /// saving and queues the operation for synchronization.
  Future<Goal?> updateGoal(Goal goal) async {
    if (!goal.isValid) return null;

    try {
      // Update local database first
      final companion = _convertToCompanion(goal);
      final success = await _database.goalDao.updateGoal(companion);

      if (success) {
        // Queue for sync
        await _queueSyncOperation(
          SyncOperation.update(
            entityType: 'goal',
            entityId: goal.id,
            data: goal.toMap(),
          ),
        );

        // Invalidate cache and notify listeners
        _invalidateAllCaches();
        await _notifyGoalListUpdate(goal.userId);
        _notifySingleGoalUpdate(goal);
        return goal;
      }

      return null;
    } catch (e) {
      developer.log('Error updating goal: $e', name: 'GoalRepository');
      return null;
    }
  }

  /// Updates goal progress
  ///
  /// Updates the progress of a goal and recalculates status. The operation is
  /// queued for synchronization with the cloud.
  Future<Goal?> updateGoalProgress(String goalId, double progress) async {
    try {
      final success = await _database.goalDao.updateGoalProgress(goalId, progress);
      if (!success) return null;

      // Get updated goal
      final goalData = await _database.goalDao.getGoalById(goalId);
      if (goalData == null) return null;

      final updatedGoal = _convertFromData(goalData);

      // Queue for sync
      await _queueSyncOperation(
        SyncOperation.update(
          entityType: 'goal',
          entityId: goalId,
          data: updatedGoal.toMap(),
        ),
      );

      // Invalidate cache and notify listeners
      _invalidateAllCaches();
      await _notifyGoalListUpdate(goalData.userId);
      _notifySingleGoalUpdate(updatedGoal);

      return updatedGoal;
    } catch (e) {
      developer.log('Error updating goal progress: $e', name: 'GoalRepository');
      return null;
    }
  }

  /// Updates goal status
  ///
  /// Updates the status of a goal. The operation is queued for synchronization
  /// with the cloud.
  Future<Goal?> updateGoalStatus(String goalId, GoalStatus status) async {
    try {
      final success = await _database.goalDao.updateGoalStatus(goalId, status.name);
      if (!success) return null;

      // Get updated goal
      final goalData = await _database.goalDao.getGoalById(goalId);
      if (goalData == null) return null;

      final updatedGoal = _convertFromData(goalData);

      // Queue for sync
      await _queueSyncOperation(
        SyncOperation.update(
          entityType: 'goal',
          entityId: goalId,
          data: updatedGoal.toMap(),
        ),
      );

      // Invalidate cache and notify listeners
      _invalidateAllCaches();
      await _notifyGoalListUpdate(goalData.userId);
      _notifySingleGoalUpdate(updatedGoal);

      return updatedGoal;
    } catch (e) {
      developer.log('Error updating goal status: $e', name: 'GoalRepository');
      return null;
    }
  }

  /// Gets goals by category
  ///
  /// Retrieves all goals belonging to the specified category for a user.
  Future<List<Goal>> getGoalsByCategory(
    String userId,
    GoalCategory category,
  ) async {
    final goalDataList = await _database.goalDao.getGoalsByCategory(
      userId,
      category.name,
    );
    return goalDataList.map(_convertFromData).toList();
  }

  /// Gets goals by priority
  ///
  /// Retrieves all goals with the specified priority level.
  Future<List<Goal>> getGoalsByPriority(
    String userId,
    GoalPriority priority,
  ) async {
    final goalDataList = await _database.goalDao.getGoalsByPriority(
      userId,
      priority.name,
    );
    return goalDataList.map(_convertFromData).toList();
  }

  /// Gets goals by status
  ///
  /// Retrieves all goals with the specified status.
  Future<List<Goal>> getGoalsByStatus(
    String userId,
    GoalStatus status,
  ) async {
    final goalDataList = await _database.goalDao.getGoalsByStatus(
      userId,
      status.name,
    );
    return goalDataList.map(_convertFromData).toList();
  }

  /// Gets active goals
  ///
  /// Retrieves all goals that are not completed or cancelled.
  Future<List<Goal>> getActiveGoals(String userId) async {
    final goalDataList = await _database.goalDao.getActiveGoals(userId);
    return goalDataList.map(_convertFromData).toList();
  }

  /// Gets completed goals
  ///
  /// Retrieves all goals that have been completed.
  Future<List<Goal>> getCompletedGoals(String userId) async {
    final goalDataList = await _database.goalDao.getCompletedGoals(userId);
    return goalDataList.map(_convertFromData).toList();
  }

  /// Gets overdue goals
  ///
  /// Retrieves all goals that are past their deadline and not completed.
  Future<List<Goal>> getOverdueGoals(String userId) async {
    final goalDataList = await _database.goalDao.getOverdueGoals(userId);
    return goalDataList.map(_convertFromData).toList();
  }

  /// Gets goals due soon
  ///
  /// Retrieves all goals that are due within the next 7 days.
  Future<List<Goal>> getGoalsDueSoon(String userId) async {
    final goalDataList = await _database.goalDao.getGoalsDueSoon(userId);
    return goalDataList.map(_convertFromData).toList();
  }

  /// Deletes goal
  ///
  /// Permanently removes a goal from the database.
  Future<bool> deleteGoal(String goalId, String userId) async {
    final success = await _database.goalDao.deleteGoal(goalId);

    if (success) {
      _invalidateUserCache(userId);
      await _notifyGoalListUpdate(userId);
    }

    return success;
  }

  /// Gets comprehensive goal statistics
  ///
  /// Retrieves aggregated statistics about goals for analytics and insights.
  Future<Map<String, dynamic>> getGoalStats(String userId) async =>
      _database.goalDao.getGoalStats(userId);

  /// Gets goal statistics by category
  ///
  /// Retrieves category-based breakdown of goal data for visualization.
  Future<List<Map<String, dynamic>>> getGoalStatsByCategory(
    String userId,
  ) async =>
      _database.goalDao.getGoalStatsByCategory(userId);

  /// Gets goal completion trend data
  ///
  /// Retrieves trend data for goal completions over time.
  Future<List<Map<String, dynamic>>> getGoalCompletionTrend(
    String userId, {
    int days = 30,
  }) async =>
      _database.goalDao.getGoalCompletionTrend(userId, days: days);

  /// Gets priority distribution
  ///
  /// Retrieves distribution of goals by priority level.
  Future<List<Map<String, dynamic>>> getPriorityDistribution(String userId) async =>
      _database.goalDao.getPriorityDistribution(userId);

  /// Gets status distribution
  ///
  /// Retrieves distribution of goals by status.
  Future<List<Map<String, dynamic>>> getStatusDistribution(String userId) async =>
      _database.goalDao.getStatusDistribution(userId);

  /// Gets goal stream for real-time updates
  ///
  /// Provides a stream of all goals for a user that emits updates when goals change.
  Stream<List<Goal>> getGoalsStream(String userId) {
    if (!_goalStreamControllers.containsKey(userId)) {
      _goalStreamControllers[userId] = StreamController<List<Goal>>.broadcast();
    }
    return _goalStreamControllers[userId]!.stream;
  }

  /// Gets single goal stream for real-time updates
  ///
  /// Provides a stream for a specific goal that emits updates when that goal changes.
  Stream<Goal> getGoalStream(String goalId) {
    if (!_singleGoalStreamControllers.containsKey(goalId)) {
      _singleGoalStreamControllers[goalId] = StreamController<Goal>.broadcast();
    }
    return _singleGoalStreamControllers[goalId]!.stream;
  }

  /// Batch operations for sync
  ///
  /// Performs batch updates of goals, typically used during synchronization.
  Future<void> batchUpdateGoals(List<Goal> goals) async {
    final companions = goals.map(_convertToCompanion).toList();
    await _database.goalDao.batchUpdateGoals(companions);

    // Clear cache and notify
    _invalidateAllCaches();
  }

  /// Sync goal data with cloud
  ///
  /// Placeholder for future cloud synchronization implementation.
  Future<void> syncGoalData(String userId) async {
    // This would implement cloud sync logic
    // For now, just refresh cache
    _invalidateUserCache(userId);
  }

  /// Disposes resources
  ///
  /// Cleans up streams and other resources when the repository is no longer needed.
  void dispose() {
    for (final controller in _goalStreamControllers.values) {
      controller.close();
    }
    for (final controller in _singleGoalStreamControllers.values) {
      controller.close();
    }
    _goalStreamControllers.clear();
    _singleGoalStreamControllers.clear();
    _clearCache();
  }

  // Private helper methods

  /// Gets cached goals for user
  List<Goal>? _getCachedGoals(String userId) {
    // Check if cache has expired
    final timestamp = _cacheTimestamps[userId];
    if (timestamp != null && 
        DateTime.now().difference(timestamp) > _cacheExpiration) {
      // Cache expired, remove it
      _goalCache.remove(userId);
      _cacheTimestamps.remove(userId);
      return null;
    }
    
    // Try to get from LRU cache
    return _goalCache.get(userId);
  }

  /// Gets cached goal by ID from any user's cache
  Goal? _getCachedGoalById(String goalId) {
    // Try to get from single goal cache first
    final cachedGoal = _singleGoalCache.get(goalId);
    if (cachedGoal != null) {
      return cachedGoal;
    }
    
    // Check all user caches
    for (final userId in _goalCache.keys) {
      final goals = _goalCache.get(userId);
      if (goals != null) {
        final goal = goals.where((g) => g.id == goalId).firstOrNull;
        if (goal != null) {
          // Cache this individual goal for faster access next time
          _singleGoalCache.put(goalId, goal);
          return goal;
        }
      }
    }
    return null;
  }

  /// Caches goals for user
  void _cacheGoals(String userId, List<Goal> goals) {
    _goalCache.put(userId, goals);
    _cacheTimestamps[userId] = DateTime.now();
    
    // Also cache individual goals for faster access
    for (final goal in goals) {
      _singleGoalCache.put(goal.id, goal);
    }
  }

  /// Invalidates cache for specific user
  void _invalidateUserCache(String userId) {
    _goalCache.remove(userId);
    _cacheTimestamps.remove(userId);
  }

  /// Invalidates all caches
  void _invalidateAllCaches() {
    _goalCache.clear();
    _singleGoalCache.clear();
    _statsCache.clear();
    _cacheTimestamps.clear();
  }

  /// Clears all cache
  void _clearCache() {
    _invalidateAllCaches();
  }

  /// Notifies goal list update
  Future<void> _notifyGoalListUpdate(String userId) async {
    final controller = _goalStreamControllers[userId];
    if (controller != null && !controller.isClosed) {
      final goals = await getGoalsByUserId(userId);
      controller.add(goals);
    }
  }

  /// Notifies single goal update
  void _notifySingleGoalUpdate(Goal goal) {
    final controller = _singleGoalStreamControllers[goal.id];
    if (controller != null && !controller.isClosed) {
      controller.add(goal);
    }
  }

  /// Converts database data to Goal model
  Goal _convertFromData(GoalData data) => Goal(
        id: data.id,
        userId: data.userId,
        title: data.title,
        description: data.description,
        category: GoalCategory.values.byName(data.category),
        priority: GoalPriority.values.byName(data.priority),
        status: GoalStatus.values.byName(data.status),
        progress: data.progress,
        startDate: data.startDate,
        deadline: data.deadline,
        completedAt: data.completedAt,
        createdAt: data.createdAt,
        updatedAt: data.updatedAt,
      );

  /// Converts Goal model to database companion
  GoalsCompanion _convertToCompanion(Goal goal) => GoalsCompanion.insert(
        id: goal.id,
        userId: goal.userId,
        title: goal.title,
        description: Value(goal.description),
        category: goal.category.name,
        priority: goal.priority.name,
        status: goal.status.name,
        progress: Value(goal.progress),
        startDate: Value(goal.startDate),
        deadline: goal.deadline,
        completedAt: Value(goal.completedAt),
        createdAt: goal.createdAt,
        updatedAt: goal.updatedAt,
      );

  /// Generates unique ID
  String _generateId() => DateTime.now().millisecondsSinceEpoch.toString();

  /// Queue sync operation for offline support
  Future<void> _queueSyncOperation(SyncOperation operation) async {
    try {
      await _offlineManager.queueSyncOperation(operation);
    } catch (e) {
      developer.log('Failed to queue sync operation: $e', name: 'GoalRepository');
      // Continue execution - offline support is not critical for core functionality
    }
  }
}