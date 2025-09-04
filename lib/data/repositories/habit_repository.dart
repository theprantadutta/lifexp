import 'dart:async';
import 'dart:developer' as developer;

import 'package:drift/drift.dart';

import '../../shared/services/lru_cache_service.dart';
import '../../shared/services/offline_manager.dart';
import '../database/database.dart';
import '../models/habit.dart';
import '../models/sync_operation.dart';

/// Repository for managing habit data with streak tracking and analytics
///
/// The HabitRepository handles all data operations related to habits including
/// creation, updating, completion tracking, and analytics. It provides both
/// local database operations and synchronization capabilities for offline support.
class HabitRepository {
  HabitRepository({
    required LifeXPDatabase database,
    OfflineManager? offlineManager,
  })  : _database = database,
        _offlineManager = offlineManager ?? OfflineManager();

  final LifeXPDatabase _database;
  final OfflineManager _offlineManager;

  // LRU Cache for habit data
  final _habitCache = LRUCache<String, List<Habit>>(100); // Max 100 user entries
  final _singleHabitCache = LRUCache<String, Habit>(200); // Max 200 individual habits
  final _statsCache = LRUCache<String, Map<String, dynamic>>(50); // Max 50 stats entries

  // Cache expiration time (5 minutes for habits as they change frequently)
  static const Duration _cacheExpiration = Duration(minutes: 5);

  // Cache timestamps for expiration tracking
  final Map<String, DateTime> _cacheTimestamps = {};

  // Stream controllers for real-time updates
  final Map<String, StreamController<List<Habit>>> _habitStreamControllers = {};
  final Map<String, StreamController<Habit>> _singleHabitStreamControllers = {};

  /// Gets all habits for a user with caching
  ///
  /// Retrieves all habits associated with the specified user ID. Results are
  /// cached for performance optimization.
  Future<List<Habit>> getHabitsByUserId(String userId) async {
    // Check cache first
    final cachedHabits = _getCachedHabits(userId);
    if (cachedHabits != null) {
      return cachedHabits;
    }

    // Fetch from database
    final habitDataList = await _database.habitDao.getHabitsByUserId(userId);
    final habits = habitDataList.map(_convertFromData).toList();

    _cacheHabits(userId, habits);
    return habits;
  }

  /// Gets habit by ID
  ///
  /// Retrieves a specific habit by its unique identifier.
  Future<Habit?> getHabitById(String habitId) async {
    // Check if habit exists in any cached list
    final cachedHabit = _getCachedHabitById(habitId);
    if (cachedHabit != null) {
      return cachedHabit;
    }

    // Fetch from database
    final habitData = await _database.habitDao.getHabitById(habitId);
    if (habitData == null) return null;

    return _convertFromData(habitData);
  }

  /// Creates a new habit
  ///
  /// Creates a new habit with the specified parameters and saves it to the local
  /// database. The operation is queued for synchronization with the cloud.
  Future<Habit> createHabit({
    required String userId,
    required String title,
    required HabitCategory category,
    required HabitFrequency frequency,
    String description = '',
    int? difficulty,
    DateTime? reminderTime,
  }) async {
    final habitId = _generateId();
    final habit = Habit.create(
      id: habitId,
      userId: userId,
      title: title,
      category: category,
      frequency: frequency,
      description: description,
      difficulty: difficulty,
      reminderTime: reminderTime,
    );

    final companion = _convertToCompanion(habit);
    await _database.habitDao.createHabit(companion);

    // Queue for sync
    await _queueSyncOperation(
      SyncOperation.create(
        entityType: 'habit',
        entityId: habitId,
        data: habit.toMap(),
      ),
    );

    // Invalidate cache and notify listeners
    _invalidateUserCache(userId);
    await _notifyHabitListUpdate(userId);

    return habit;
  }

  /// Updates an existing habit
  ///
  /// Updates the specified habit with new values. Performs validation before
  /// saving and queues the operation for synchronization.
  Future<Habit?> updateHabit(Habit habit) async {
    if (!habit.isValid) return null;

    try {
      // Update local database first
      final companion = _convertToCompanion(habit);
      final success = await _database.habitDao.updateHabit(companion);

      if (success) {
        // Queue for sync
        await _queueSyncOperation(
          SyncOperation.update(
            entityType: 'habit',
            entityId: habit.id,
            data: habit.toMap(),
          ),
        );

        // Invalidate cache and notify listeners
        _invalidateAllCaches();
        await _notifyHabitListUpdate(habit.userId);
        _notifySingleHabitUpdate(habit);
        return habit;
      }

      return null;
    } catch (e) {
      developer.log('Error updating habit: $e', name: 'HabitRepository');
      return null;
    }
  }

  /// Completes habit for today and updates streak
  ///
  /// Marks the specified habit as completed for the current day, updates the
  /// streak count, and calculates any XP rewards. The operation is queued for
  /// synchronization with the cloud.
  Future<Habit?> completeHabit(String habitId) async {
    try {
      // Complete in local database first
      final habitData = await _database.habitDao.completeHabit(habitId);
      if (habitData == null) return null;

      final completedHabit = _convertFromData(habitData);

      // Queue for sync
      await _queueSyncOperation(
        SyncOperation.update(
          entityType: 'habit',
          entityId: habitId,
          data: completedHabit.toMap(),
        ),
      );

      // Invalidate cache and notify listeners
      _invalidateAllCaches();
      await _notifyHabitListUpdate(habitData.userId);
      _notifySingleHabitUpdate(completedHabit);

      return completedHabit;
    } catch (e) {
      developer.log('Error completing habit: $e', name: 'HabitRepository');
      return null;
    }
  }

  /// Resets habit for new day
  ///
  /// Resets the completion status for a new day. This should be called as part
  /// of a daily maintenance routine.
  Future<Habit?> resetHabitForNewDay(String habitId) async {
    try {
      final habitData = await _database.habitDao.resetHabitForNewDay(habitId);
      if (habitData == null) return null;

      final resetHabit = _convertFromData(habitData);

      // Queue for sync
      await _queueSyncOperation(
        SyncOperation.update(
          entityType: 'habit',
          entityId: habitId,
          data: resetHabit.toMap(),
        ),
      );

      // Invalidate cache and notify listeners
      _invalidateAllCaches();
      await _notifyHabitListUpdate(habitData.userId);
      _notifySingleHabitUpdate(resetHabit);

      return resetHabit;
    } catch (e) {
      developer.log('Error resetting habit: $e', name: 'HabitRepository');
      return null;
    }
  }

  /// Gets habits by category
  ///
  /// Retrieves all habits belonging to the specified category for a user.
  Future<List<Habit>> getHabitsByCategory(
    String userId,
    HabitCategory category,
  ) async {
    final habitDataList = await _database.habitDao.getHabitsByCategory(
      userId,
      category.name,
    );
    return habitDataList.map(_convertFromData).toList();
  }

  /// Gets habits by frequency
  ///
  /// Retrieves all habits with the specified frequency pattern.
  Future<List<Habit>> getHabitsByFrequency(
    String userId,
    HabitFrequency frequency,
  ) async {
    final habitDataList = await _database.habitDao.getHabitsByFrequency(
      userId,
      frequency.name,
    );
    return habitDataList.map(_convertFromData).toList();
  }

  /// Gets completed habits for today
  ///
  /// Retrieves all habits that have been completed today.
  Future<List<Habit>> getCompletedHabits(String userId) async {
    final habitDataList = await _database.habitDao.getCompletedHabits(userId);
    return habitDataList.map(_convertFromData).toList();
  }

  /// Gets pending habits for today
  ///
  /// Retrieves all habits that have not been completed today, sorted by priority.
  Future<List<Habit>> getPendingHabits(String userId) async {
    final habitDataList = await _database.habitDao.getPendingHabits(userId);
    final habits = habitDataList.map(_convertFromData).toList();

    // Sort by priority: streak length, then difficulty
    habits.sort((a, b) {
      // Prioritize habits with longer streaks to maintain consistency
      final streakComparison = b.streakCount.compareTo(a.streakCount);
      if (streakComparison != 0) return streakComparison;

      // Then by difficulty (higher difficulty first)
      return b.difficulty.compareTo(a.difficulty);
    });

    return habits;
  }

  /// Updates habit difficulty
  ///
  /// Updates the difficulty level of a habit, which affects XP rewards.
  Future<bool> updateHabitDifficulty(String habitId, int newDifficulty) async {
    final success = await _database.habitDao.updateHabitDifficulty(
      habitId,
      newDifficulty,
    );

    if (success) {
      // Invalidate cache
      _invalidateAllCaches();

      // Get updated habit and notify
      final updatedHabit = await getHabitById(habitId);
      if (updatedHabit != null) {
        _notifySingleHabitUpdate(updatedHabit);
      }
    }

    return success;
  }

  /// Updates habit reminder time
  ///
  /// Updates the reminder time for a habit.
  Future<bool> updateHabitReminder(String habitId, DateTime? reminderTime) async {
    final success = await _database.habitDao.updateHabitReminder(
      habitId,
      reminderTime,
    );

    if (success) {
      // Invalidate cache
      _invalidateAllCaches();

      // Get updated habit and notify
      final updatedHabit = await getHabitById(habitId);
      if (updatedHabit != null) {
        _notifySingleHabitUpdate(updatedHabit);
      }
    }

    return success;
  }

  /// Deletes habit
  ///
  /// Permanently removes a habit from the database.
  Future<bool> deleteHabit(String habitId, String userId) async {
    final success = await _database.habitDao.deleteHabit(habitId);

    if (success) {
      _invalidateUserCache(userId);
      await _notifyHabitListUpdate(userId);
    }

    return success;
  }

  /// Gets comprehensive habit statistics
  ///
  /// Retrieves aggregated statistics about habits for analytics and insights.
  Future<Map<String, dynamic>> getHabitStats(String userId) async =>
      _database.habitDao.getHabitStats(userId);

  /// Gets habit statistics by category
  ///
  /// Retrieves category-based breakdown of habit data for visualization.
  Future<List<Map<String, dynamic>>> getHabitStatsByCategory(
    String userId,
  ) async =>
      _database.habitDao.getHabitStatsByCategory(userId);

  /// Gets habit completion trend data
  ///
  /// Retrieves trend data for habit completions over time.
  Future<List<Map<String, dynamic>>> getHabitCompletionTrend(
    String userId, {
    int days = 30,
  }) async =>
      _database.habitDao.getHabitCompletionTrend(userId, days: days);

  /// Gets streak analytics
  ///
  /// Retrieves detailed analytics about habit streaks.
  Future<List<Map<String, dynamic>>> getStreakAnalytics(String userId) async =>
      _database.habitDao.getStreakAnalytics(userId);

  /// Gets category performance metrics
  ///
  /// Retrieves performance metrics grouped by habit category.
  Future<List<Map<String, dynamic>>> getCategoryPerformanceMetrics(
    String userId,
  ) async =>
      _database.habitDao.getCategoryPerformanceMetrics(userId);

  /// Gets habit stream for real-time updates
  ///
  /// Provides a stream of all habits for a user that emits updates when habits change.
  Stream<List<Habit>> getHabitsStream(String userId) {
    if (!_habitStreamControllers.containsKey(userId)) {
      _habitStreamControllers[userId] = StreamController<List<Habit>>.broadcast();
    }
    return _habitStreamControllers[userId]!.stream;
  }

  /// Gets single habit stream for real-time updates
  ///
  /// Provides a stream for a specific habit that emits updates when that habit changes.
  Stream<Habit> getHabitStream(String habitId) {
    if (!_singleHabitStreamControllers.containsKey(habitId)) {
      _singleHabitStreamControllers[habitId] = StreamController<Habit>.broadcast();
    }
    return _singleHabitStreamControllers[habitId]!.stream;
  }

  /// Batch operations for sync
  ///
  /// Performs batch updates of habits, typically used during synchronization.
  Future<void> batchUpdateHabits(List<Habit> habits) async {
    final companions = habits.map(_convertToCompanion).toList();
    await _database.habitDao.batchUpdateHabits(companions);

    // Clear cache and notify
    _invalidateAllCaches();
  }

  /// Sync habit data with cloud
  ///
  /// Placeholder for future cloud synchronization implementation.
  Future<void> syncHabitData(String userId) async {
    // This would implement cloud sync logic
    // For now, just refresh cache
    _invalidateUserCache(userId);
  }

  /// Disposes resources
  ///
  /// Cleans up streams and other resources when the repository is no longer needed.
  void dispose() {
    for (final controller in _habitStreamControllers.values) {
      controller.close();
    }
    for (final controller in _singleHabitStreamControllers.values) {
      controller.close();
    }
    _habitStreamControllers.clear();
    _singleHabitStreamControllers.clear();
    _clearCache();
  }

  // Private helper methods

  /// Gets cached habits for user
  List<Habit>? _getCachedHabits(String userId) {
    // Check if cache has expired
    final timestamp = _cacheTimestamps[userId];
    if (timestamp != null && 
        DateTime.now().difference(timestamp) > _cacheExpiration) {
      // Cache expired, remove it
      _habitCache.remove(userId);
      _cacheTimestamps.remove(userId);
      return null;
    }
    
    // Try to get from LRU cache
    return _habitCache.get(userId);
  }

  /// Gets cached habit by ID from any user's cache
  Habit? _getCachedHabitById(String habitId) {
    // Try to get from single habit cache first
    final cachedHabit = _singleHabitCache.get(habitId);
    if (cachedHabit != null) {
      return cachedHabit;
    }
    
    // Check all user caches
    for (final userId in _habitCache.keys) {
      final habits = _habitCache.get(userId);
      if (habits != null) {
        final habit = habits.where((h) => h.id == habitId).firstOrNull;
        if (habit != null) {
          // Cache this individual habit for faster access next time
          _singleHabitCache.put(habitId, habit);
          return habit;
        }
      }
    }
    return null;
  }

  /// Caches habits for user
  void _cacheHabits(String userId, List<Habit> habits) {
    _habitCache.put(userId, habits);
    _cacheTimestamps[userId] = DateTime.now();
    
    // Also cache individual habits for faster access
    for (final habit in habits) {
      _singleHabitCache.put(habit.id, habit);
    }
  }

  /// Invalidates cache for specific user
  void _invalidateUserCache(String userId) {
    _habitCache.remove(userId);
    _cacheTimestamps.remove(userId);
  }

  /// Invalidates all caches
  void _invalidateAllCaches() {
    _habitCache.clear();
    _singleHabitCache.clear();
    _statsCache.clear();
    _cacheTimestamps.clear();
  }

  /// Clears all cache
  void _clearCache() {
    _invalidateAllCaches();
  }

  /// Notifies habit list update
  Future<void> _notifyHabitListUpdate(String userId) async {
    final controller = _habitStreamControllers[userId];
    if (controller != null && !controller.isClosed) {
      final habits = await getHabitsByUserId(userId);
      controller.add(habits);
    }
  }

  /// Notifies single habit update
  void _notifySingleHabitUpdate(Habit habit) {
    final controller = _singleHabitStreamControllers[habit.id];
    if (controller != null && !controller.isClosed) {
      controller.add(habit);
    }
  }

  /// Converts database data to Habit model
  Habit _convertFromData(HabitData data) => Habit(
        id: data.id,
        userId: data.userId,
        title: data.title,
        description: data.description,
        category: HabitCategory.values.byName(data.category),
        frequency: HabitFrequency.values.byName(data.frequency),
        difficulty: data.difficulty,
        isCompletedToday: data.isCompletedToday,
        streakCount: data.streakCount,
        longestStreak: data.longestStreak,
        completionRate: data.completionRate,
        totalCompletions: data.totalCompletions,
        reminderTime: data.reminderTime,
        lastCompletedDate: data.lastCompletedDate,
        createdAt: data.createdAt,
        updatedAt: data.updatedAt,
      );

  /// Converts Habit model to database companion
  HabitsCompanion _convertToCompanion(Habit habit) => HabitsCompanion.insert(
        id: habit.id,
        userId: habit.userId,
        title: habit.title,
        description: Value(habit.description),
        category: habit.category.name,
        frequency: habit.frequency.name,
        difficulty: habit.difficulty,
        isCompletedToday: Value(habit.isCompletedToday),
        streakCount: Value(habit.streakCount),
        longestStreak: Value(habit.longestStreak),
        completionRate: Value(habit.completionRate),
        totalCompletions: Value(habit.totalCompletions),
        reminderTime: Value(habit.reminderTime),
        lastCompletedDate: Value(habit.lastCompletedDate),
        createdAt: habit.createdAt,
        updatedAt: habit.updatedAt,
      );

  /// Generates unique ID
  String _generateId() => DateTime.now().millisecondsSinceEpoch.toString();

  /// Queue sync operation for offline support
  Future<void> _queueSyncOperation(SyncOperation operation) async {
    try {
      await _offlineManager.queueSyncOperation(operation);
    } catch (e) {
      developer.log('Failed to queue sync operation: $e', name: 'HabitRepository');
      // Continue execution - offline support is not critical for core functionality
    }
  }
}