part of '../database.dart';

/// Data Access Object for Habit operations
@DriftAccessor(tables: [Habits])
class HabitDao extends DatabaseAccessor<LifeXPDatabase> with _$HabitDaoMixin {
  HabitDao(super.db);

  /// Gets all habits for a user
  Future<List<HabitData>> getHabitsByUserId(String userId) async =>
      (select(habits)
            ..where((h) => h.userId.equals(userId))
            ..orderBy([(h) => OrderingTerm.desc(h.createdAt)]))
          .get();

  /// Gets habit by ID
  Future<HabitData?> getHabitById(String id) async =>
      (select(habits)..where((h) => h.id.equals(id))).getSingleOrNull();

  /// Gets habits by category
  Future<List<HabitData>> getHabitsByCategory(
    String userId,
    String category,
  ) async =>
      (select(habits)
            ..where(
              (h) => h.userId.equals(userId) & h.category.equals(category),
            )
            ..orderBy([(h) => OrderingTerm.desc(h.createdAt)]))
          .get();

  /// Gets habits by frequency
  Future<List<HabitData>> getHabitsByFrequency(
    String userId,
    String frequency,
  ) async =>
      (select(habits)
            ..where(
              (h) => h.userId.equals(userId) & h.frequency.equals(frequency),
            )
            ..orderBy([(h) => OrderingTerm.desc(h.createdAt)]))
          .get();

  /// Gets completed habits
  Future<List<HabitData>> getCompletedHabits(String userId) async =>
      (select(habits)
            ..where(
              (h) => h.userId.equals(userId) & h.isCompletedToday.equals(true),
            )
            ..orderBy([(h) => OrderingTerm.desc(h.lastCompletedDate)]))
          .get();

  /// Gets pending habits
  Future<List<HabitData>> getPendingHabits(String userId) async =>
      (select(habits)
            ..where(
              (h) =>
                  h.userId.equals(userId) & h.isCompletedToday.equals(false),
            )
            ..orderBy([
              (h) => OrderingTerm.desc(h.streakCount),
              (h) => OrderingTerm.desc(h.difficulty),
            ]))
          .get();

  /// Creates a new habit
  Future<void> createHabit(HabitsCompanion habit) async {
    await into(habits).insert(habit);
  }

  /// Updates habit data
  Future<bool> updateHabit(HabitsCompanion habit) async =>
      update(habits).replace(habit);

  /// Completes a habit and updates streak
  Future<HabitData?> completeHabit(String habitId) async =>
      transaction(() async {
        final habit = await getHabitById(habitId);
        if (habit == null || habit.isCompletedToday) {
          return null;
        }

        final now = DateTime.now();
        final newStreakCount = _calculateNewStreakCount(habit, now);
        final newLongestStreak =
            newStreakCount > habit.longestStreak ? newStreakCount : habit.longestStreak;
        final newTotalCompletions = habit.totalCompletions + 1;
        // In a real implementation, this would be calculated based on actual history
        final newCompletionRate = ((habit.completionRate * habit.totalCompletions) + 1) /
            (habit.totalCompletions + 1);

        await update(habits).replace(
          HabitsCompanion(
            id: Value(habitId),
            isCompletedToday: const Value(true),
            streakCount: Value(newStreakCount),
            longestStreak: Value(newLongestStreak),
            totalCompletions: Value(newTotalCompletions),
            completionRate: Value(newCompletionRate),
            lastCompletedDate: Value(now),
            updatedAt: Value(now),
          ),
        );
        return getHabitById(habitId);
      });

  /// Resets habit to incomplete (for new day)
  Future<HabitData?> resetHabitForNewDay(String habitId) async {
    final habit = await getHabitById(habitId);
    if (habit == null || !habit.isCompletedToday) {
      return null;
    }

    await update(habits).replace(
      HabitsCompanion(
        id: Value(habitId),
        isCompletedToday: const Value(false),
        updatedAt: Value(DateTime.now()),
      ),
    );
    return getHabitById(habitId);
  }

  /// Updates habit difficulty
  Future<bool> updateHabitDifficulty(String habitId, int newDifficulty) async {
    if (newDifficulty < 1 || newDifficulty > 10) {
      return false;
    }

    final result = await (update(habits)..where((h) => h.id.equals(habitId)))
        .write(
          HabitsCompanion(
            difficulty: Value(newDifficulty),
            updatedAt: Value(DateTime.now()),
          ),
        );
    return result > 0;
  }

  /// Updates habit reminder time
  Future<bool> updateHabitReminder(String habitId, DateTime? reminderTime) async {
    final result = await (update(habits)..where((h) => h.id.equals(habitId)))
        .write(
          HabitsCompanion(
            reminderTime: Value(reminderTime),
            updatedAt: Value(DateTime.now()),
          ),
        );
    return result > 0;
  }

  /// Deletes a habit
  Future<bool> deleteHabit(String habitId) async {
    final result =
        await (delete(habits)..where((h) => h.id.equals(habitId))).go();
    return result > 0;
  }

  /// Batch updates habits
  Future<void> batchUpdateHabits(List<HabitsCompanion> habitsList) async {
    await batch((batch) {
      for (final habit in habitsList) {
        batch.insert(habits, habit, mode: InsertMode.replace);
      }
    });
  }

  /// Gets comprehensive habit statistics
  Future<Map<String, dynamic>> getHabitStats(String userId) async {
    final result = await customSelect(
      '''
      SELECT 
        COUNT(*) as total_habits,
        COUNT(CASE WHEN is_completed_today = 1 THEN 1 END) as completed_today,
        AVG(CASE WHEN is_completed_today = 1 THEN difficulty END) as avg_difficulty,
        MAX(streak_count) as max_streak,
        AVG(completion_rate) as avg_completion_rate
      FROM habits 
      WHERE user_id = ?
      ''',
      variables: [Variable.withString(userId)],
    ).getSingleOrNull();

    return result?.data ?? {};
  }

  /// Gets habit statistics by category
  Future<List<Map<String, dynamic>>> getHabitStatsByCategory(
    String userId,
  ) async {
    final result = await customSelect(
      '''
      SELECT 
        category,
        COUNT(*) as total_habits,
        COUNT(CASE WHEN is_completed_today = 1 THEN 1 END) as completed_today,
        AVG(streak_count) as avg_streak,
        AVG(completion_rate) as avg_completion_rate
      FROM habits 
      WHERE user_id = ?
      GROUP BY category
      ORDER BY total_habits DESC
      ''',
      variables: [Variable.withString(userId)],
    ).get();

    return result.map((row) => row.data).toList();
  }

  /// Gets habit completion trend data
  Future<List<Map<String, dynamic>>> getHabitCompletionTrend(
    String userId, {
    int days = 30,
  }) async {
    final result = await customSelect(
      '''
      WITH RECURSIVE dates(day) AS (
        SELECT date('now', '-${days - 1} days')
        UNION ALL
        SELECT date(day, '+1 day')
        FROM dates
        WHERE day < date('now')
      )
      SELECT 
        d.day as date,
        COUNT(h.id) as completed_count
      FROM dates d
      LEFT JOIN habits h ON date(h.last_completed_date) = d.day AND h.user_id = ?
      WHERE h.is_completed_today = 1 OR h.is_completed_today IS NULL
      GROUP BY d.day
      ORDER BY d.day
      ''',
      variables: [Variable.withString(userId)],
    ).get();

    return result.map((row) => row.data).toList();
  }

  /// Gets streak analytics
  Future<List<Map<String, dynamic>>> getStreakAnalytics(String userId) async {
    final result = await customSelect(
      '''
      SELECT 
        streak_count,
        COUNT(*) as habit_count
      FROM habits 
      WHERE user_id = ? AND streak_count > 0
      GROUP BY streak_count
      ORDER BY streak_count DESC
      ''',
      variables: [Variable.withString(userId)],
    ).get();

    return result.map((row) => row.data).toList();
  }

  /// Gets category performance metrics
  Future<List<Map<String, dynamic>>> getCategoryPerformanceMetrics(
    String userId,
  ) async {
    final result = await customSelect(
      '''
      SELECT 
        category,
        COUNT(*) as total_habits,
        AVG(completion_rate) as avg_completion_rate,
        MAX(streak_count) as max_streak,
        SUM(total_completions) as total_completions
      FROM habits 
      WHERE user_id = ?
      GROUP BY category
      ORDER BY avg_completion_rate DESC
      ''',
      variables: [Variable.withString(userId)],
    ).get();

    return result.map((row) => row.data).toList();
  }

  /// Calculates new streak count based on completion timing
  int _calculateNewStreakCount(HabitData habit, DateTime completionDate) {
    if (habit.lastCompletedDate == null) {
      return 1; // First completion
    }

    final daysSinceLastCompletion = completionDate
        .difference(habit.lastCompletedDate!)
        .inDays;

    // For habits, we're more lenient with streaks
    // if completed within 1 day + grace period
    if (daysSinceLastCompletion <= 1) {
      return habit.streakCount + 1;
    } else if (daysSinceLastCompletion == 2) {
      // Check if within grace period (6 hours)
      final hoursSinceLastCompletion = completionDate
          .difference(habit.lastCompletedDate!)
          .inHours;

      if (hoursSinceLastCompletion <= 30) {
        // 24 hours + 6 hours grace period
        return habit.streakCount + 1;
      }
    }

    return 1; // Streak broken, start over
  }
}