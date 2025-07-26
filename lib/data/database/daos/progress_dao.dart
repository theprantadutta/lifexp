part of '../database.dart';

/// Data Access Object for Progress operations
@DriftAccessor(tables: [ProgressEntries, Users])
class ProgressDao extends DatabaseAccessor<LifeXPDatabase>
    with _$ProgressDaoMixin {
  ProgressDao(super.db);

  /// Gets all progress entries for a user
  Future<List<ProgressEntryData>> getProgressEntriesByUserId(
    String userId,
  ) async =>
      (select(progressEntries)
            ..where((p) => p.userId.equals(userId))
            ..orderBy([(p) => OrderingTerm.desc(p.date)]))
          .get();

  /// Gets progress entry by ID
  Future<ProgressEntryData?> getProgressEntryById(String id) async => (select(
    progressEntries,
  )..where((p) => p.id.equals(id))).getSingleOrNull();

  /// Gets progress entry for a specific date
  Future<ProgressEntryData?> getProgressEntryByDate(
    String userId,
    DateTime date,
  ) async {
    final dateOnly = DateTime(date.year, date.month, date.day);
    return (select(progressEntries)
          ..where((p) => p.userId.equals(userId) & p.date.equals(dateOnly)))
        .getSingleOrNull();
  }

  /// Gets progress entries for a date range
  Future<List<ProgressEntryData>> getProgressEntriesInRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async =>
      (select(progressEntries)
            ..where(
              (p) =>
                  p.userId.equals(userId) &
                  p.date.isBetweenValues(startDate, endDate),
            )
            ..orderBy([(p) => OrderingTerm.asc(p.date)]))
          .get();

  /// Gets progress entries by category
  Future<List<ProgressEntryData>> getProgressEntriesByCategory(
    String userId,
    String category,
  ) async =>
      (select(progressEntries)
            ..where(
              (p) => p.userId.equals(userId) & p.category.equals(category),
            )
            ..orderBy([(p) => OrderingTerm.desc(p.date)]))
          .get();

  /// Gets recent progress entries
  Future<List<ProgressEntryData>> getRecentProgressEntries(
    String userId, {
    int days = 30,
  }) async {
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    return getProgressEntriesInRange(userId, cutoffDate, DateTime.now());
  }

  /// Creates a new progress entry
  Future<void> createProgressEntry(ProgressEntriesCompanion entry) async {
    await into(progressEntries).insert(entry);
  }

  /// Updates progress entry data
  Future<bool> updateProgressEntry(ProgressEntriesCompanion entry) async =>
      update(progressEntries).replace(entry);

  /// Creates or updates progress entry for today
  Future<ProgressEntryData> createOrUpdateTodayEntry(
    String userId,
    int xpGain,
    int tasksCompleted, {
    String? category,
    Map<String, int>? categoryBreakdown,
    Map<String, int>? taskTypeBreakdown,
    int? streakCount,
    int? levelAtTime,
  }) async => transaction(() async {
    final today = DateTime.now();
    final dateOnly = DateTime(today.year, today.month, today.day);

    final existingEntry = await getProgressEntryByDate(userId, dateOnly);

    if (existingEntry != null) {
      // Update existing entry
      final newXP = existingEntry.xpGained + xpGain;
      final newTasks = existingEntry.tasksCompleted + tasksCompleted;

      // Merge category breakdowns
      final existingCategoryBreakdown =
          json.decode(existingEntry.categoryBreakdown) as Map<String, dynamic>;
      final newCategoryBreakdown = Map<String, int>.from(
        existingCategoryBreakdown,
      );

      if (categoryBreakdown != null) {
        for (final entry in categoryBreakdown.entries) {
          newCategoryBreakdown[entry.key] =
              (newCategoryBreakdown[entry.key] ?? 0) + entry.value;
        }
      }

      // Merge task type breakdowns
      final existingTaskTypeBreakdown =
          json.decode(existingEntry.taskTypeBreakdown) as Map<String, dynamic>;
      final newTaskTypeBreakdown = Map<String, int>.from(
        existingTaskTypeBreakdown,
      );

      if (taskTypeBreakdown != null) {
        for (final entry in taskTypeBreakdown.entries) {
          newTaskTypeBreakdown[entry.key] =
              (newTaskTypeBreakdown[entry.key] ?? 0) + entry.value;
        }
      }

      final updatedEntry = ProgressEntriesCompanion(
        id: Value(existingEntry.id),
        xpGained: Value(newXP),
        tasksCompleted: Value(newTasks),
        categoryBreakdown: Value(json.encode(newCategoryBreakdown)),
        taskTypeBreakdown: Value(json.encode(newTaskTypeBreakdown)),
        streakCount: streakCount != null
            ? Value(streakCount)
            : const Value.absent(),
        levelAtTime: levelAtTime != null
            ? Value(levelAtTime)
            : const Value.absent(),
        updatedAt: Value(DateTime.now()),
      );

      await update(progressEntries).replace(updatedEntry);
      return (await getProgressEntryById(existingEntry.id))!;
    } else {
      // Create new entry
      final newEntry = ProgressEntriesCompanion.insert(
        id: const uuid.Uuid().v4(),
        userId: userId,
        date: dateOnly,
        xpGained: Value(xpGain),
        tasksCompleted: Value(tasksCompleted),
        category: Value(category),
        categoryBreakdown: Value(json.encode(categoryBreakdown ?? {})),
        taskTypeBreakdown: Value(json.encode(taskTypeBreakdown ?? {})),
        streakCount: Value(streakCount ?? 0),
        levelAtTime: Value(levelAtTime ?? 1),
        additionalMetrics: const Value('{}'),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await into(progressEntries).insert(newEntry);
      return (await getProgressEntryByDate(userId, dateOnly))!;
    }
  });

  /// Adds XP to today's progress entry
  Future<ProgressEntryData> addXPToToday(
    String userId,
    int xpGain, {
    String? category,
  }) async {
    final categoryBreakdown = category != null
        ? {category: xpGain}
        : <String, int>{};
    return createOrUpdateTodayEntry(
      userId,
      xpGain,
      0,
      categoryBreakdown: categoryBreakdown,
    );
  }

  /// Adds completed task to today's progress entry
  Future<ProgressEntryData> addTaskToToday(
    String userId, {
    String? taskType,
  }) async {
    final taskTypeBreakdown = taskType != null
        ? {taskType: 1}
        : <String, int>{};
    return createOrUpdateTodayEntry(
      userId,
      0,
      1,
      taskTypeBreakdown: taskTypeBreakdown,
    );
  }

  /// Gets daily XP trend data
  Future<List<Map<String, dynamic>>> getDailyXPTrend(
    String userId, {
    int days = 30,
  }) async {
    final startDate = DateTime.now().subtract(Duration(days: days));

    final result = await customSelect(
      '''
      SELECT 
        DATE(date) as entry_date,
        xp_gained,
        tasks_completed,
        streak_count,
        level_at_time
      FROM progress_entries 
      WHERE user_id = ? AND date >= ?
      ORDER BY date ASC
      ''',
      variables: [
        Variable.withString(userId),
        Variable.withDateTime(startDate),
      ],
    ).get();

    return result.map((row) => row.data).toList();
  }

  /// Gets weekly progress summary
  Future<List<Map<String, dynamic>>> getWeeklyProgressSummary(
    String userId, {
    int weeks = 12,
  }) async {
    final startDate = DateTime.now().subtract(Duration(days: weeks * 7));

    final result = await customSelect(
      '''
      SELECT 
        strftime('%Y-W%W', date) as week_key,
        SUM(xp_gained) as total_xp,
        SUM(tasks_completed) as total_tasks,
        AVG(xp_gained) as avg_daily_xp,
        AVG(tasks_completed) as avg_daily_tasks,
        MAX(streak_count) as max_streak,
        MAX(level_at_time) as max_level,
        COUNT(*) as entry_count
      FROM progress_entries 
      WHERE user_id = ? AND date >= ?
      GROUP BY strftime('%Y-W%W', date)
      ORDER BY week_key ASC
      ''',
      variables: [
        Variable.withString(userId),
        Variable.withDateTime(startDate),
      ],
    ).get();

    return result.map((row) => row.data).toList();
  }

  /// Gets monthly progress summary
  Future<List<Map<String, dynamic>>> getMonthlyProgressSummary(
    String userId, {
    int months = 12,
  }) async {
    final startDate = DateTime.now().subtract(Duration(days: months * 30));

    final result = await customSelect(
      '''
      SELECT 
        strftime('%Y-%m', date) as month_key,
        SUM(xp_gained) as total_xp,
        SUM(tasks_completed) as total_tasks,
        AVG(xp_gained) as avg_daily_xp,
        AVG(tasks_completed) as avg_daily_tasks,
        MAX(streak_count) as max_streak,
        MAX(level_at_time) as max_level,
        COUNT(*) as entry_count
      FROM progress_entries 
      WHERE user_id = ? AND date >= ?
      GROUP BY strftime('%Y-%m', date)
      ORDER BY month_key ASC
      ''',
      variables: [
        Variable.withString(userId),
        Variable.withDateTime(startDate),
      ],
    ).get();

    return result.map((row) => row.data).toList();
  }

  /// Gets category breakdown for a time period
  Future<List<Map<String, dynamic>>> getCategoryBreakdown(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final entries = await getProgressEntriesInRange(userId, startDate, endDate);
    final categoryTotals = <String, int>{};

    for (final entry in entries) {
      final breakdown =
          json.decode(entry.categoryBreakdown) as Map<String, dynamic>;
      for (final category in breakdown.keys) {
        categoryTotals[category] =
            (categoryTotals[category] ?? 0) + (breakdown[category] as int);
      }
    }

    return categoryTotals.entries
        .map((e) => {'category': e.key, 'total_xp': e.value})
        .toList()
      ..sort(
        (a, b) => (b['total_xp']! as int).compareTo(a['total_xp']! as int),
      );
  }

  /// Gets overall progress statistics
  Future<Map<String, dynamic>> getProgressStats(String userId) async {
    final result = await customSelect(
      '''
      SELECT 
        COUNT(*) as total_entries,
        SUM(xp_gained) as total_xp,
        SUM(tasks_completed) as total_tasks,
        AVG(xp_gained) as avg_daily_xp,
        AVG(tasks_completed) as avg_daily_tasks,
        MAX(xp_gained) as max_daily_xp,
        MAX(tasks_completed) as max_daily_tasks,
        MAX(streak_count) as max_streak,
        MAX(level_at_time) as max_level,
        MIN(date) as first_entry_date,
        MAX(date) as last_entry_date
      FROM progress_entries 
      WHERE user_id = ?
      ''',
      variables: [Variable.withString(userId)],
    ).getSingleOrNull();

    return result?.data ?? {};
  }

  /// Gets productivity streaks
  Future<List<Map<String, dynamic>>> getProductivityStreaks(
    String userId, {
    int minXP = 50,
    int minTasks = 3,
  }) async {
    final result = await customSelect(
      '''
      WITH productive_days AS (
        SELECT 
          date,
          xp_gained,
          tasks_completed,
          CASE WHEN xp_gained >= ? OR tasks_completed >= ? THEN 1 ELSE 0 END as is_productive
        FROM progress_entries 
        WHERE user_id = ?
        ORDER BY date
      ),
      streak_groups AS (
        SELECT 
          *,
          SUM(CASE WHEN is_productive = 0 THEN 1 ELSE 0 END) OVER (ORDER BY date) as streak_group
        FROM productive_days
      )
      SELECT 
        MIN(date) as streak_start,
        MAX(date) as streak_end,
        COUNT(*) as streak_length,
        SUM(xp_gained) as total_xp,
        SUM(tasks_completed) as total_tasks
      FROM streak_groups
      WHERE is_productive = 1
      GROUP BY streak_group
      HAVING COUNT(*) >= 2
      ORDER BY streak_length DESC
      ''',
      variables: [
        Variable.withInt(minXP),
        Variable.withInt(minTasks),
        Variable.withString(userId),
      ],
    ).get();

    return result.map((row) => row.data).toList();
  }

  /// Deletes progress entry
  Future<bool> deleteProgressEntry(String entryId) async {
    final result = await (delete(
      progressEntries,
    )..where((p) => p.id.equals(entryId))).go();
    return result > 0;
  }

  /// Batch operations for sync
  Future<void> batchUpdateProgressEntries(
    List<ProgressEntriesCompanion> entryUpdates,
  ) async {
    await batch((batch) {
      for (final entry in entryUpdates) {
        batch.replace(progressEntries, entry);
      }
    });
  }

  /// Cleans up old progress entries (keep last N days)
  Future<int> cleanupOldEntries(String userId, {int keepDays = 365}) async {
    final cutoffDate = DateTime.now().subtract(Duration(days: keepDays));

    return (delete(progressEntries)..where(
          (p) =>
              p.userId.equals(userId) & p.date.isSmallerThanValue(cutoffDate),
        ))
        .go();
  }

  /// Batch analytics operations for performance optimization
  Future<Map<String, dynamic>> getBatchAnalytics(
    String userId, {
    int days = 30,
  }) async {
    final startDate = DateTime.now().subtract(Duration(days: days));

    final result = await customSelect(
      '''
      WITH daily_stats AS (
        SELECT 
          date,
          xp_gained,
          tasks_completed,
          streak_count,
          level_at_time,
          category_breakdown,
          task_type_breakdown
        FROM progress_entries 
        WHERE user_id = ? AND date >= ?
        ORDER BY date ASC
      ),
      aggregated_stats AS (
        SELECT 
          COUNT(*) as total_days,
          SUM(xp_gained) as total_xp,
          SUM(tasks_completed) as total_tasks,
          AVG(xp_gained) as avg_daily_xp,
          AVG(tasks_completed) as avg_daily_tasks,
          MAX(xp_gained) as max_daily_xp,
          MAX(tasks_completed) as max_daily_tasks,
          MAX(streak_count) as max_streak,
          MAX(level_at_time) as max_level,
          MIN(date) as first_date,
          MAX(date) as last_date
        FROM daily_stats
      )
      SELECT * FROM aggregated_stats
      ''',
      variables: [
        Variable.withString(userId),
        Variable.withDateTime(startDate),
      ],
    ).getSingleOrNull();

    return result?.data ?? {};
  }

  /// Optimized sync operations for batch updates
  Future<void> batchSyncProgressEntries(
    String userId,
    List<Map<String, dynamic>> syncData,
  ) async => transaction(() async {
    final updates = <ProgressEntriesCompanion>[];

    for (final data in syncData) {
      final date = DateTime.parse(data['date'] as String);
      final existingEntry = await getProgressEntryByDate(userId, date);

      if (existingEntry != null) {
        // Update existing entry
        updates.add(
          ProgressEntriesCompanion(
            id: Value(existingEntry.id),
            xpGained: Value(data['xpGained'] as int),
            tasksCompleted: Value(data['tasksCompleted'] as int),
            categoryBreakdown: Value(
              json.encode(data['categoryBreakdown'] ?? {}),
            ),
            taskTypeBreakdown: Value(
              json.encode(data['taskTypeBreakdown'] ?? {}),
            ),
            streakCount: Value(data['streakCount'] as int? ?? 0),
            levelAtTime: Value(data['levelAtTime'] as int? ?? 1),
            updatedAt: Value(DateTime.now()),
          ),
        );
      } else {
        // Create new entry
        updates.add(
          ProgressEntriesCompanion.insert(
            id: const uuid.Uuid().v4(),
            userId: userId,
            date: date,
            xpGained: Value(data['xpGained'] as int),
            tasksCompleted: Value(data['tasksCompleted'] as int),
            categoryBreakdown: Value(
              json.encode(data['categoryBreakdown'] ?? {}),
            ),
            taskTypeBreakdown: Value(
              json.encode(data['taskTypeBreakdown'] ?? {}),
            ),
            streakCount: Value(data['streakCount'] as int? ?? 0),
            levelAtTime: Value(data['levelAtTime'] as int? ?? 1),
            additionalMetrics: const Value('{}'),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
      }
    }

    // Batch update/insert all entries
    if (updates.isNotEmpty) {
      await batch((batch) {
        for (final entry in updates) {
          if (entry.id.present) {
            batch.replace(progressEntries, entry);
          } else {
            batch.insert(progressEntries, entry);
          }
        }
      });
    }
  });
}
