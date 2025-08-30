import 'dart:async';
import 'dart:developer' as developer;

import 'package:drift/drift.dart';

import '../../shared/services/offline_data_manager.dart';
import '../database/database.dart';
import '../models/task.dart';

/// Repository for managing task data with advanced streak management and offline support
class TaskRepository {
  TaskRepository({
    required LifeXPDatabase database,
    OfflineDataManager? offlineManager,
  }) : _database = database,
       _offlineManager = offlineManager;

  final LifeXPDatabase _database;
  final OfflineDataManager? _offlineManager;

  // Cache for frequently accessed task data
  final Map<String, List<Task>> _taskCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};

  // Cache expiration time (3 minutes for tasks as they change frequently)
  static const Duration _cacheExpiration = Duration(minutes: 3);

  // Stream controllers for real-time updates
  final Map<String, StreamController<List<Task>>> _taskStreamControllers = {};
  final Map<String, StreamController<Task>> _singleTaskStreamControllers = {};

  /// Gets all tasks for a user with caching
  Future<List<Task>> getTasksByUserId(String userId) async {
    try {
      developer.log('Loading tasks for user $userId', name: 'TaskRepository');

      // Check cache first
      final cachedTasks = _getCachedTasks(userId);
      if (cachedTasks != null) {
        developer.log('Returning ${cachedTasks.length} cached tasks', name: 'TaskRepository');
        return cachedTasks;
      }

      // Fetch from database
      developer.log('Fetching tasks from database', name: 'TaskRepository');
      final taskDataList = await _database.taskDao.getTasksByUserId(userId);
      developer.log('Found ${taskDataList.length} tasks in database', name: 'TaskRepository');

      final tasks = taskDataList.map(_convertFromData).toList();

      _cacheTasks(userId, tasks);
      developer.log(
        'Successfully loaded and cached ${tasks.length} tasks', name: 'TaskRepository',
      );
      return tasks;
    } catch (e, stackTrace) {
      developer.log('Error loading tasks for user $userId', name: 'TaskRepository', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Gets task by ID with caching
  Future<Task?> getTaskById(String taskId) async {
    // Check if task exists in any cached list
    final cachedTask = _getCachedTaskById(taskId);
    if (cachedTask != null) {
      return cachedTask;
    }

    // Fetch from database
    final taskData = await _database.taskDao.getTaskById(taskId);
    if (taskData == null) return null;

    return _convertFromData(taskData);
  }

  /// Creates a new task with offline support
  Future<Task> createTask({
    required String userId,
    required String title,
    required TaskType type,
    required TaskCategory category,
    String description = '',
    int? difficulty,
    DateTime? dueDate,
  }) async {
    final taskId = _generateId();
    final task = Task.create(
      id: taskId,
      title: title,
      type: type,
      category: category,
      description: description,
      difficulty: difficulty,
      dueDate: dueDate,
    );

    try {
      // Save to local database first (offline-first approach)
      final companion = _convertToCompanion(task, userId);
      await _database.taskDao.createTask(companion);

      // Queue for sync if offline manager is available
      await _queueSyncOperation(
        SyncOperation(
          id: '${taskId}_create_${DateTime.now().millisecondsSinceEpoch}',
          entityType: 'task',
          entityId: taskId,
          operationType: SyncOperationType.create,
          data: task.toMap()..['userId'] = userId,
          timestamp: DateTime.now(),
        ),
      );

      // Invalidate cache and notify listeners
      _invalidateUserCache(userId);
      await _notifyTaskListUpdate(userId);

      return task;
    } catch (e) {
      developer.log('Error creating task: $e', name: 'TaskRepository');
      rethrow;
    }
  }

  /// Updates task with validation and offline support
  Future<Task?> updateTask(Task task, String userId) async {
    if (!task.isValid) return null;

    try {
      // Update local database first
      final companion = _convertToCompanion(task, userId);
      final success = await _database.taskDao.updateTask(companion);

      if (success) {
        // Queue for sync
        await _queueSyncOperation(
          SyncOperation(
            id: '${task.id}_update_${DateTime.now().millisecondsSinceEpoch}',
            entityType: 'task',
            entityId: task.id,
            operationType: SyncOperationType.update,
            data: task.toMap()..['userId'] = userId,
            timestamp: DateTime.now(),
          ),
        );

        // Invalidate cache and notify listeners
        _invalidateUserCache(userId);
        await _notifyTaskListUpdate(userId);
        _notifySingleTaskUpdate(task);
        return task;
      }

      return null;
    } catch (e) {
      developer.log('Error updating task: $e', name: 'TaskRepository');
      return null;
    }
  }

  /// Completes task with advanced streak management and offline support
  Future<Task?> completeTask(String taskId) async {
    try {
      // Complete in local database first
      final taskData = await _database.taskDao.completeTask(taskId);
      if (taskData == null) return null;

      final completedTask = _convertFromData(taskData);

      // Queue for sync
      await _queueSyncOperation(
        SyncOperation(
          id: '${taskId}_complete_${DateTime.now().millisecondsSinceEpoch}',
          entityType: 'task',
          entityId: taskId,
          operationType: SyncOperationType.update,
          data: completedTask.toMap()..['userId'] = taskData.userId,
          timestamp: DateTime.now(),
        ),
      );

      // Invalidate cache and notify listeners
      _invalidateAllCaches();
      await _notifyTaskListUpdate(taskData.userId);
      _notifySingleTaskUpdate(completedTask);

      return completedTask;
    } catch (e) {
      developer.log('Error completing task: $e', name: 'TaskRepository');
      return null;
    }
  }

  /// Batch complete multiple tasks with streak optimization
  Future<List<Task>> batchCompleteTasks(List<String> taskIds) async {
    final completedTaskData = await _database.taskDao.batchCompleteTasks(
      taskIds,
    );
    final completedTasks = completedTaskData.map(_convertFromData).toList();

    // Group by user for cache invalidation
    final userIds = completedTasks
        .map(
          (t) => completedTaskData.firstWhere((data) => data.id == t.id).userId,
        )
        .toSet();

    for (final userId in userIds) {
      _invalidateUserCache(userId);
      await _notifyTaskListUpdate(userId);
    }

    return completedTasks;
  }

  /// Gets tasks by category with caching
  Future<List<Task>> getTasksByCategory(
    String userId,
    TaskCategory category,
  ) async {
    final taskDataList = await _database.taskDao.getTasksByCategory(
      userId,
      category.name,
    );
    return taskDataList.map(_convertFromData).toList();
  }

  /// Gets tasks by type with caching
  Future<List<Task>> getTasksByType(String userId, TaskType type) async {
    final taskDataList = await _database.taskDao.getTasksByType(
      userId,
      type.name,
    );
    return taskDataList.map(_convertFromData).toList();
  }

  /// Gets completed tasks
  Future<List<Task>> getCompletedTasks(String userId) async {
    final taskDataList = await _database.taskDao.getCompletedTasks(userId);
    return taskDataList.map(_convertFromData).toList();
  }

  /// Gets pending tasks with priority sorting
  Future<List<Task>> getPendingTasks(String userId) async {
    final taskDataList = await _database.taskDao.getPendingTasks(userId);
    final tasks = taskDataList.map(_convertFromData).toList();

    // Sort by priority: overdue first, then by due date, then by difficulty
    tasks.sort((a, b) {
      if (a.isOverdue && !b.isOverdue) return -1;
      if (!a.isOverdue && b.isOverdue) return 1;

      if (a.dueDate != null && b.dueDate != null) {
        final dateComparison = a.dueDate!.compareTo(b.dueDate!);
        if (dateComparison != 0) return dateComparison;
      }

      return b.difficulty.compareTo(a.difficulty);
    });

    return tasks;
  }

  /// Gets tasks due today
  Future<List<Task>> getTasksDueToday(String userId) async {
    final taskDataList = await _database.taskDao.getTasksDueToday(userId);
    return taskDataList.map(_convertFromData).toList();
  }

  /// Gets overdue tasks
  Future<List<Task>> getOverdueTasks(String userId) async {
    final taskDataList = await _database.taskDao.getOverdueTasks(userId);
    return taskDataList.map(_convertFromData).toList();
  }

  /// Gets tasks with active streaks
  Future<List<Task>> getTasksWithStreaks(String userId) async {
    final taskDataList = await _database.taskDao.getTasksWithStreaks(userId);
    return taskDataList.map(_convertFromData).toList();
  }

  /// Updates task difficulty with XP recalculation
  Future<bool> updateTaskDifficulty(String taskId, int newDifficulty) async {
    final success = await _database.taskDao.updateTaskDifficulty(
      taskId,
      newDifficulty,
    );

    if (success) {
      // Invalidate cache
      _invalidateAllCaches();

      // Get updated task and notify
      final updatedTask = await getTaskById(taskId);
      if (updatedTask != null) {
        _notifySingleTaskUpdate(updatedTask);
      }
    }

    return success;
  }

  /// Breaks task streak with grace period consideration
  Future<bool> breakTaskStreak(String taskId) async {
    final task = await getTaskById(taskId);
    if (task == null) return false;

    // Check if within grace period
    if (_isWithinGracePeriod(task)) {
      return false; // Don't break streak if within grace period
    }

    final success = await _database.taskDao.breakTaskStreak(taskId);

    if (success) {
      _invalidateAllCaches();
      final updatedTask = await getTaskById(taskId);
      if (updatedTask != null) {
        _notifySingleTaskUpdate(updatedTask);
      }
    }

    return success;
  }

  /// Resets task to incomplete state
  Future<bool> resetTask(String taskId) async {
    final success = await _database.taskDao.resetTask(taskId);

    if (success) {
      _invalidateAllCaches();
      final updatedTask = await getTaskById(taskId);
      if (updatedTask != null) {
        _notifySingleTaskUpdate(updatedTask);
      }
    }

    return success;
  }

  /// Deletes task
  Future<bool> deleteTask(String taskId, String userId) async {
    final success = await _database.taskDao.deleteTask(taskId);

    if (success) {
      _invalidateUserCache(userId);
      await _notifyTaskListUpdate(userId);
    }

    return success;
  }

  /// Gets comprehensive task statistics
  Future<Map<String, dynamic>> getTaskStats(String userId) async =>
      _database.taskDao.getTaskStats(userId);

  /// Gets task statistics by category
  Future<List<Map<String, dynamic>>> getTaskStatsByCategory(
    String userId,
  ) async => _database.taskDao.getTaskStatsByCategory(userId);

  /// Gets task completion trend data
  Future<List<Map<String, dynamic>>> getTaskCompletionTrend(
    String userId, {
    int days = 30,
  }) async => _database.taskDao.getTaskCompletionTrend(userId, days: days);

  /// Gets streak analytics
  Future<List<Map<String, dynamic>>> getStreakAnalytics(String userId) async =>
      _database.taskDao.getStreakAnalytics(userId);

  /// Gets category performance metrics
  Future<List<Map<String, dynamic>>> getCategoryPerformanceMetrics(
    String userId,
  ) async => _database.taskDao.getCategoryPerformanceMetrics(userId);

  /// Calculates streak bonus XP
  int calculateStreakBonus({
    required int baseXP,
    required int streakCount,
    required TaskType taskType,
  }) {
    if (streakCount <= 1) return 0;

    // Base streak multiplier
    var multiplier = 0.0;

    switch (taskType) {
      case TaskType.daily:
        // Daily tasks get higher streak bonuses
        multiplier = (streakCount * 0.15).clamp(0.0, 1.0); // Up to 100% bonus
        break;
      case TaskType.weekly:
        // Weekly tasks get moderate streak bonuses
        multiplier = (streakCount * 0.12).clamp(0.0, 0.8); // Up to 80% bonus
        break;
      case TaskType.longTerm:
        // Long-term tasks get smaller streak bonuses
        multiplier = (streakCount * 0.08).clamp(0.0, 0.5); // Up to 50% bonus
        break;
    }

    return (baseXP * multiplier).round();
  }

  /// Calculates dynamic XP reward based on various factors
  int calculateDynamicXPReward({
    required Task task,
    required int streakCount,
    required bool isConsistencyBonus,
    required DateTime completionTime,
  }) {
    var totalXP = task.xpReward;

    // Streak bonus
    totalXP += calculateStreakBonus(
      baseXP: task.xpReward,
      streakCount: streakCount,
      taskType: task.type,
    );

    // Consistency bonus (completing tasks regularly)
    if (isConsistencyBonus) {
      totalXP += (task.xpReward * 0.2).round();
    }

    // Early completion bonus
    if (task.dueDate != null && completionTime.isBefore(task.dueDate!)) {
      final daysEarly = task.dueDate!.difference(completionTime).inDays;
      if (daysEarly > 0) {
        final earlyBonus = (task.xpReward * 0.1 * daysEarly).clamp(
          0,
          task.xpReward * 0.5,
        );
        totalXP += earlyBonus.round();
      }
    }

    // Difficulty scaling bonus
    if (task.difficulty >= 8) {
      totalXP += (task.xpReward * 0.25)
          .round(); // 25% bonus for very hard tasks
    } else if (task.difficulty >= 6) {
      totalXP += (task.xpReward * 0.15).round(); // 15% bonus for hard tasks
    }

    return totalXP;
  }

  /// Schedules task reminders based on type and user preferences
  Future<void> scheduleTaskReminders(
    Task task,
    Map<String, dynamic> userPreferences,
  ) async {
    // This would integrate with notification service
    // Implementation depends on notification system

    final reminderTimes = <DateTime>[];

    switch (task.type) {
      case TaskType.daily:
        // Daily reminders
        if (userPreferences['dailyReminders'] == true) {
          reminderTimes.add(
            userPreferences['dailyReminderTime'] as DateTime? ??
                DateTime.now().add(const Duration(hours: 1)),
          );
        }
        break;

      case TaskType.weekly:
        // Weekly reminders
        if (userPreferences['weeklyReminders'] == true) {
          reminderTimes.add(
            userPreferences['weeklyReminderTime'] as DateTime? ??
                DateTime.now().add(const Duration(days: 1)),
          );
        }
        break;

      case TaskType.longTerm:
        // Long-term milestone reminders
        if (task.dueDate != null &&
            userPreferences['longTermReminders'] == true) {
          final daysUntilDue = task.dueDate!.difference(DateTime.now()).inDays;
          if (daysUntilDue > 7) {
            reminderTimes.add(task.dueDate!.subtract(const Duration(days: 7)));
          }
          if (daysUntilDue > 1) {
            reminderTimes.add(task.dueDate!.subtract(const Duration(days: 1)));
          }
        }
        break;
    }

    // Schedule reminders (placeholder - would integrate with notification service)
    for (final _ in reminderTimes) {
      // await _notificationService.scheduleReminder(task, reminderTime);
    }
  }

  /// Gets task stream for real-time updates
  Stream<List<Task>> getTasksStream(String userId) {
    if (!_taskStreamControllers.containsKey(userId)) {
      _taskStreamControllers[userId] = StreamController<List<Task>>.broadcast();
    }
    return _taskStreamControllers[userId]!.stream;
  }

  /// Gets single task stream for real-time updates
  Stream<Task> getTaskStream(String taskId) {
    if (!_singleTaskStreamControllers.containsKey(taskId)) {
      _singleTaskStreamControllers[taskId] = StreamController<Task>.broadcast();
    }
    return _singleTaskStreamControllers[taskId]!.stream;
  }

  /// Batch operations for sync
  Future<void> batchUpdateTasks(List<Task> tasks, String userId) async {
    final companions = tasks
        .map((task) => _convertToCompanion(task, userId))
        .toList();
    await _database.taskDao.batchUpdateTasks(companions);

    // Clear cache and notify
    _invalidateUserCache(userId);
    await _notifyTaskListUpdate(userId);
  }

  /// Sync task data with cloud (placeholder for future implementation)
  Future<void> syncTaskData(String userId) async {
    // This would implement cloud sync logic
    // For now, just refresh cache
    _invalidateUserCache(userId);
  }

  /// Disposes resources
  void dispose() {
    for (final controller in _taskStreamControllers.values) {
      controller.close();
    }
    for (final controller in _singleTaskStreamControllers.values) {
      controller.close();
    }
    _taskStreamControllers.clear();
    _singleTaskStreamControllers.clear();
    _clearCache();
  }

  // Private helper methods

  /// Gets cached tasks for user
  List<Task>? _getCachedTasks(String userId) {
    if (_taskCache.containsKey(userId) && _isCacheValid(userId)) {
      return _taskCache[userId];
    }
    return null;
  }

  /// Gets cached task by ID from any user's cache
  Task? _getCachedTaskById(String taskId) {
    for (final tasks in _taskCache.values) {
      final task = tasks.where((t) => t.id == taskId).firstOrNull;
      if (task != null) return task;
    }
    return null;
  }

  /// Caches tasks for user
  void _cacheTasks(String userId, List<Task> tasks) {
    _taskCache[userId] = tasks;
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
    _taskCache.remove(userId);
    _cacheTimestamps.remove(userId);
  }

  /// Invalidates all caches
  void _invalidateAllCaches() {
    _taskCache.clear();
    _cacheTimestamps.clear();
  }

  /// Clears all cache
  void _clearCache() {
    _taskCache.clear();
    _cacheTimestamps.clear();
  }

  /// Checks if task is within grace period for streak maintenance
  bool _isWithinGracePeriod(Task task) {
    if (task.lastCompletedDate == null) return false;

    final hoursSinceCompletion = DateTime.now()
        .difference(task.lastCompletedDate!)
        .inHours;

    switch (task.type) {
      case TaskType.daily:
        return hoursSinceCompletion <= 24 + Task.streakGracePeriodHours;
      case TaskType.weekly:
        return hoursSinceCompletion <= (7 * 24) + Task.streakGracePeriodHours;
      case TaskType.longTerm:
        return true; // Long-term tasks have flexible grace periods
    }
  }

  /// Notifies task list update
  Future<void> _notifyTaskListUpdate(String userId) async {
    final controller = _taskStreamControllers[userId];
    if (controller != null && !controller.isClosed) {
      final tasks = await getTasksByUserId(userId);
      controller.add(tasks);
    }
  }

  /// Notifies single task update
  void _notifySingleTaskUpdate(Task task) {
    final controller = _singleTaskStreamControllers[task.id];
    if (controller != null && !controller.isClosed) {
      controller.add(task);
    }
  }

  /// Converts database data to Task model
  Task _convertFromData(TaskData data) => Task(
    id: data.id,
    title: data.title,
    description: data.description,
    type: TaskType.values.byName(data.type),
    category: TaskCategory.values.byName(data.category),
    xpReward: data.xpReward,
    difficulty: data.difficulty,
    dueDate: data.dueDate,
    isCompleted: data.isCompleted,
    streakCount: data.streakCount,
    lastCompletedDate: data.lastCompletedDate,
    createdAt: data.createdAt,
    updatedAt: data.updatedAt,
  );

  /// Converts Task model to database companion
  TasksCompanion _convertToCompanion(Task task, String userId) =>
      TasksCompanion.insert(
        id: task.id,
        userId: userId,
        title: task.title,
        description: Value(task.description),
        type: task.type.name,
        category: task.category.name,
        xpReward: task.xpReward,
        difficulty: task.difficulty,
        dueDate: Value(task.dueDate),
        isCompleted: Value(task.isCompleted),
        streakCount: Value(task.streakCount),
        lastCompletedDate: Value(task.lastCompletedDate),
        createdAt: task.createdAt,
        updatedAt: task.updatedAt,
      );

  /// Generates unique ID
  String _generateId() => DateTime.now().millisecondsSinceEpoch.toString();

  /// Queue sync operation for offline support
  Future<void> _queueSyncOperation(SyncOperation operation) async {
    if (_offlineManager == null) return;
    
    try {
      await _offlineManager.queueSyncOperation(operation);
    } catch (e) {
      developer.log('Failed to queue sync operation: $e', name: 'TaskRepository');
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
