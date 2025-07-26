part of '../database.dart';

/// Data Access Object for Task operations
@DriftAccessor(tables: [Tasks, Users])
class TaskDao extends DatabaseAccessor<LifeXPDatabase> with _$TaskDaoMixin {
  TaskDao(super.db);

  /// Gets all tasks for a user
  Future<List<TaskData>> getTasksByUserId(String userId) async =>
      (select(tasks)
            ..where((t) => t.userId.equals(userId))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .get();

  /// Gets task by ID
  Future<TaskData?> getTaskById(String id) async =>
      (select(tasks)..where((t) => t.id.equals(id))).getSingleOrNull();

  /// Gets tasks by category
  Future<List<TaskData>> getTasksByCategory(
    String userId,
    String category,
  ) async =>
      (select(tasks)
            ..where(
              (t) => t.userId.equals(userId) & t.category.equals(category),
            )
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .get();

  /// Gets tasks by type
  Future<List<TaskData>> getTasksByType(String userId, String type) async =>
      (select(tasks)
            ..where((t) => t.userId.equals(userId) & t.type.equals(type))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .get();

  /// Gets completed tasks
  Future<List<TaskData>> getCompletedTasks(String userId) async =>
      (select(tasks)
            ..where((t) => t.userId.equals(userId) & t.isCompleted.equals(true))
            ..orderBy([(t) => OrderingTerm.desc(t.lastCompletedDate)]))
          .get();

  /// Gets pending tasks
  Future<List<TaskData>> getPendingTasks(String userId) async =>
      (select(tasks)
            ..where(
              (t) => t.userId.equals(userId) & t.isCompleted.equals(false),
            )
            ..orderBy([(t) => OrderingTerm.asc(t.dueDate)]))
          .get();

  /// Gets tasks due today
  Future<List<TaskData>> getTasksDueToday(String userId) async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return (select(tasks)..where(
          (t) =>
              t.userId.equals(userId) &
              t.dueDate.isBetweenValues(startOfDay, endOfDay) &
              t.isCompleted.equals(false),
        ))
        .get();
  }

  /// Gets overdue tasks
  Future<List<TaskData>> getOverdueTasks(String userId) async {
    final now = DateTime.now();

    return (select(tasks)..where(
          (t) =>
              t.userId.equals(userId) &
              t.dueDate.isSmallerThanValue(now) &
              t.isCompleted.equals(false),
        ))
        .get();
  }

  /// Gets tasks with active streaks
  Future<List<TaskData>> getTasksWithStreaks(String userId) async =>
      (select(tasks)
            ..where(
              (t) =>
                  t.userId.equals(userId) & t.streakCount.isBiggerThanValue(0),
            )
            ..orderBy([(t) => OrderingTerm.desc(t.streakCount)]))
          .get();

  /// Creates a new task
  Future<void> createTask(TasksCompanion task) async {
    await into(tasks).insert(task);
  }

  /// Updates task data
  Future<bool> updateTask(TasksCompanion task) async =>
      update(tasks).replace(task);

  /// Completes a task and updates streak
  Future<TaskData?> completeTask(String taskId) async => transaction(() async {
    final task = await getTaskById(taskId);
    if (task == null || task.isCompleted) {
      return null;
    }

    final now = DateTime.now();
    final newStreakCount = _calculateNewStreakCount(task, now);

    final updatedTask = TasksCompanion(
      id: Value(taskId),
      isCompleted: const Value(true),
      streakCount: Value(newStreakCount),
      lastCompletedDate: Value(now),
      updatedAt: Value(now),
    );

    await update(tasks).replace(updatedTask);
    return getTaskById(taskId);
  });

  /// Resets task to incomplete (for recurring tasks)
  Future<bool> resetTask(String taskId) async {
    final result = await (update(tasks)..where((t) => t.id.equals(taskId)))
        .write(
          TasksCompanion(
            isCompleted: const Value(false),
            updatedAt: Value(DateTime.now()),
          ),
        );
    return result > 0;
  }

  /// Updates task difficulty and XP reward
  Future<bool> updateTaskDifficulty(String taskId, int newDifficulty) async {
    if (newDifficulty < 1 || newDifficulty > 10) {
      return false;
    }

    final task = await getTaskById(taskId);
    if (task == null) {
      return false;
    }

    final newXPReward = _calculateXPReward(newDifficulty, task.type);

    final result = await (update(tasks)..where((t) => t.id.equals(taskId)))
        .write(
          TasksCompanion(
            difficulty: Value(newDifficulty),
            xpReward: Value(newXPReward),
            updatedAt: Value(DateTime.now()),
          ),
        );
    return result > 0;
  }

  /// Breaks task streak
  Future<bool> breakTaskStreak(String taskId) async {
    final result = await (update(tasks)..where((t) => t.id.equals(taskId)))
        .write(
          TasksCompanion(
            streakCount: const Value(0),
            updatedAt: Value(DateTime.now()),
          ),
        );
    return result > 0;
  }

  /// Gets task completion statistics
  Future<Map<String, dynamic>> getTaskStats(String userId) async {
    final result = await customSelect(
      '''
      SELECT 
        COUNT(*) as total_tasks,
        COUNT(CASE WHEN is_completed = 1 THEN 1 END) as completed_tasks,
        COUNT(CASE WHEN is_completed = 0 THEN 1 END) as pending_tasks,
        AVG(CASE WHEN is_completed = 1 THEN difficulty END) as avg_difficulty,
        MAX(streak_count) as max_streak,
        SUM(CASE WHEN is_completed = 1 THEN xp_reward END) as total_xp_earned
      FROM tasks 
      WHERE user_id = ?
      ''',
      variables: [Variable.withString(userId)],
    ).getSingleOrNull();

    return result?.data ?? {};
  }

  /// Gets task statistics by category
  Future<List<Map<String, dynamic>>> getTaskStatsByCategory(
    String userId,
  ) async {
    final result = await customSelect(
      '''
      SELECT 
        category,
        COUNT(*) as total_tasks,
        COUNT(CASE WHEN is_completed = 1 THEN 1 END) as completed_tasks,
        AVG(CASE WHEN is_completed = 1 THEN difficulty END) as avg_difficulty,
        SUM(CASE WHEN is_completed = 1 THEN xp_reward END) as total_xp
      FROM tasks 
      WHERE user_id = ?
      GROUP BY category
      ORDER BY total_xp DESC
      ''',
      variables: [Variable.withString(userId)],
    ).get();

    return result.map((row) => row.data).toList();
  }

  /// Gets task completion trend data
  Future<List<Map<String, dynamic>>> getTaskCompletionTrend(
    String userId, {
    int days = 30,
  }) async {
    final startDate = DateTime.now().subtract(Duration(days: days));

    final result = await customSelect(
      '''
      SELECT 
        DATE(last_completed_date) as completion_date,
        COUNT(*) as tasks_completed,
        SUM(xp_reward) as xp_gained
      FROM tasks 
      WHERE user_id = ? 
        AND is_completed = 1 
        AND last_completed_date >= ?
      GROUP BY DATE(last_completed_date)
      ORDER BY completion_date ASC
      ''',
      variables: [
        Variable.withString(userId),
        Variable.withDateTime(startDate),
      ],
    ).get();

    return result.map((row) => row.data).toList();
  }

  /// Deletes task
  Future<bool> deleteTask(String taskId) async {
    final result = await (delete(
      tasks,
    )..where((t) => t.id.equals(taskId))).go();
    return result > 0;
  }

  /// Batch operations for sync
  Future<void> batchUpdateTasks(List<TasksCompanion> taskUpdates) async {
    await batch((batch) {
      for (final task in taskUpdates) {
        batch.replace(tasks, task);
      }
    });
  }

  /// Batch delete tasks
  Future<int> batchDeleteTasks(List<String> taskIds) async =>
      (delete(tasks)..where((t) => t.id.isIn(taskIds))).go();

  /// Optimized streak tracking query
  Future<List<Map<String, dynamic>>> getStreakAnalytics(String userId) async {
    final result = await customSelect(
      '''
      SELECT 
        category,
        type,
        COUNT(*) as total_tasks,
        AVG(streak_count) as avg_streak,
        MAX(streak_count) as max_streak,
        COUNT(CASE WHEN streak_count > 0 THEN 1 END) as tasks_with_streaks,
        SUM(CASE WHEN is_completed = 1 THEN xp_reward END) as total_xp_from_streaks
      FROM tasks 
      WHERE user_id = ? AND streak_count > 0
      GROUP BY category, type
      ORDER BY max_streak DESC, avg_streak DESC
      ''',
      variables: [Variable.withString(userId)],
    ).get();

    return result.map((row) => row.data).toList();
  }

  /// Batch complete tasks with streak updates
  Future<List<TaskData>> batchCompleteTasks(List<String> taskIds) async =>
      transaction(() async {
        final completedTasks = <TaskData>[];

        for (final taskId in taskIds) {
          final completedTask = await completeTask(taskId);
          if (completedTask != null) {
            completedTasks.add(completedTask);
          }
        }

        return completedTasks;
      });

  /// Optimized category filtering with performance metrics
  Future<List<Map<String, dynamic>>> getCategoryPerformanceMetrics(
    String userId,
  ) async {
    final result = await customSelect(
      '''
      SELECT 
        category,
        COUNT(*) as total_tasks,
        COUNT(CASE WHEN is_completed = 1 THEN 1 END) as completed_tasks,
        ROUND(
          (COUNT(CASE WHEN is_completed = 1 THEN 1 END) * 100.0) / COUNT(*), 2
        ) as completion_rate,
        AVG(difficulty) as avg_difficulty,
        SUM(CASE WHEN is_completed = 1 THEN xp_reward END) as total_xp,
        AVG(streak_count) as avg_streak,
        MAX(streak_count) as max_streak,
        COUNT(CASE WHEN due_date < datetime('now') AND is_completed = 0 THEN 1 END) as overdue_count
      FROM tasks 
      WHERE user_id = ?
      GROUP BY category
      ORDER BY completion_rate DESC, total_xp DESC
      ''',
      variables: [Variable.withString(userId)],
    ).get();

    return result.map((row) => row.data).toList();
  }

  /// Calculates new streak count based on completion timing
  int _calculateNewStreakCount(TaskData task, DateTime completionDate) {
    if (task.lastCompletedDate == null) {
      return 1; // First completion
    }

    final daysSinceLastCompletion = completionDate
        .difference(task.lastCompletedDate!)
        .inDays;

    switch (task.type) {
      case 'daily':
        // Daily tasks: streak continues if completed within 1-2 days
        if (daysSinceLastCompletion <= 1) {
          return task.streakCount + 1;
        } else if (daysSinceLastCompletion == 2) {
          // Grace period
          return task.streakCount + 1;
        } else {
          return 1; // Streak broken, start over
        }

      case 'weekly':
        // Weekly tasks: streak continues if completed within 7-8 days
        if (daysSinceLastCompletion <= 7) {
          return task.streakCount + 1;
        } else if (daysSinceLastCompletion <= 8) {
          // Grace period
          return task.streakCount + 1;
        } else {
          return 1; // Streak broken, start over
        }

      case 'longTerm':
        // Long-term tasks don't have traditional streaks
        return task.streakCount + 1;

      default:
        return 1;
    }
  }

  /// Calculates XP reward based on difficulty and type
  int _calculateXPReward(int difficulty, String type) {
    final baseXP = difficulty * 10;

    switch (type) {
      case 'daily':
        return baseXP;
      case 'weekly':
        return (baseXP * 1.5).round();
      case 'longTerm':
        return baseXP * 2;
      default:
        return baseXP;
    }
  }
}
