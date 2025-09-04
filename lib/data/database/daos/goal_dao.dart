part of '../database.dart';

/// Data Access Object for Goal operations
@DriftAccessor(tables: [Goals])
class GoalDao extends DatabaseAccessor<LifeXPDatabase> with _$GoalDaoMixin {
  GoalDao(super.db);

  /// Gets all goals for a user
  Future<List<GoalData>> getGoalsByUserId(String userId) async =>
      (select(goals)
            ..where((g) => g.userId.equals(userId))
            ..orderBy([(g) => OrderingTerm.desc(g.createdAt)]))
          .get();

  /// Gets goal by ID
  Future<GoalData?> getGoalById(String id) async =>
      (select(goals)..where((g) => g.id.equals(id))).getSingleOrNull();

  /// Gets goals by category
  Future<List<GoalData>> getGoalsByCategory(
    String userId,
    String category,
  ) async =>
      (select(goals)
            ..where(
              (g) => g.userId.equals(userId) & g.category.equals(category),
            )
            ..orderBy([(g) => OrderingTerm.desc(g.createdAt)]))
          .get();

  /// Gets goals by priority
  Future<List<GoalData>> getGoalsByPriority(
    String userId,
    String priority,
  ) async =>
      (select(goals)
            ..where(
              (g) => g.userId.equals(userId) & g.priority.equals(priority),
            )
            ..orderBy([(g) => OrderingTerm.desc(g.createdAt)]))
          .get();

  /// Gets goals by status
  Future<List<GoalData>> getGoalsByStatus(
    String userId,
    String status,
  ) async =>
      (select(goals)
            ..where((g) => g.userId.equals(userId) & g.status.equals(status))
            ..orderBy([(g) => OrderingTerm.desc(g.createdAt)]))
          .get();

  /// Gets active goals (not completed or cancelled)
  Future<List<GoalData>> getActiveGoals(String userId) async =>
      (select(goals)
            ..where(
              (g) =>
                  g.userId.equals(userId) &
                  g.status.isNotValue('completed') &
                  g.status.isNotValue('cancelled'),
            )
            ..orderBy([(g) => OrderingTerm.desc(g.createdAt)]))
          .get();

  /// Gets completed goals
  Future<List<GoalData>> getCompletedGoals(String userId) async =>
      (select(goals)
            ..where(
              (g) => g.userId.equals(userId) & g.status.equals('completed'),
            )
            ..orderBy([(g) => OrderingTerm.desc(g.completedAt)]))
          .get();

  /// Gets overdue goals
  Future<List<GoalData>> getOverdueGoals(String userId) async {
    final now = DateTime.now();

    return (select(goals)..where(
          (g) =>
              g.userId.equals(userId) &
              g.deadline.isSmallerThanValue(now) &
              g.status.isNotValue('completed') &
              g.status.isNotValue('cancelled'),
        ))
        .get();
  }

  /// Gets goals due soon (within 7 days)
  Future<List<GoalData>> getGoalsDueSoon(String userId) async {
    final now = DateTime.now();
    final oneWeekFromNow = now.add(const Duration(days: 7));

    return (select(goals)..where(
          (g) =>
              g.userId.equals(userId) &
              g.deadline.isBetweenValues(now, oneWeekFromNow) &
              g.status.isNotValue('completed') &
              g.status.isNotValue('cancelled'),
        ))
        .get();
  }

  /// Creates a new goal
  Future<void> createGoal(GoalsCompanion goal) async {
    await into(goals).insert(goal);
  }

  /// Updates goal data
  Future<bool> updateGoal(GoalsCompanion goal) async {
    return update(goals).replace(goal);
  }

  /// Updates goal progress
  Future<bool> updateGoalProgress(String goalId, double progress) async {
    final result = await (update(goals)..where((g) => g.id.equals(goalId)))
        .write(
          GoalsCompanion(
            progress: Value(progress),
            updatedAt: Value(DateTime.now()),
          ),
        );
    return result > 0;
  }

  /// Updates goal status
  Future<bool> updateGoalStatus(String goalId, String status) async {
    final updates = <GeneratedColumn, Value<Object?>>{
      goals.status: Value(status),
      goals.updatedAt: Value(DateTime.now()),
    };

    // If marking as completed, set completedAt
    if (status == 'completed') {
      updates[goals.completedAt] = Value(DateTime.now());
    }

    final result = await (update(goals)..where((g) => g.id.equals(goalId)))
        .write(GoalsCompanion.custom());
    return result > 0;
  }

  /// Deletes a goal
  Future<bool> deleteGoal(String goalId) async {
    final result =
        await (delete(goals)..where((g) => g.id.equals(goalId))).go();
    return result > 0;
  }

  /// Batch updates goals
  Future<void> batchUpdateGoals(List<GoalsCompanion> goalsList) async {
    await batch((batch) {
      for (final goal in goalsList) {
        batch.insert(
          goals,
          goal,
          mode: InsertMode.replace,
        );
      }
    });
  }

  /// Gets goal statistics
  Future<Map<String, dynamic>> getGoalStats(String userId) async {
    final result = await customSelect(
      '''
      SELECT 
        COUNT(*) as total_goals,
        COUNT(CASE WHEN status = 'completed' THEN 1 END) as completed_goals,
        COUNT(CASE WHEN status != 'completed' AND status != 'cancelled' THEN 1 END) as active_goals,
        AVG(progress) as avg_progress,
        MAX(CASE WHEN status = 'completed' THEN completed_at END) as last_completed_goal
      FROM goals 
      WHERE user_id = ?
      ''',
      variables: [Variable.withString(userId)],
    ).getSingleOrNull();

    return result?.data ?? {};
  }

  /// Gets goal statistics by category
  Future<List<Map<String, dynamic>>> getGoalStatsByCategory(
    String userId,
  ) async {
    final result = await customSelect(
      '''
      SELECT 
        category,
        COUNT(*) as total_goals,
        COUNT(CASE WHEN status = 'completed' THEN 1 END) as completed_goals,
        AVG(progress) as avg_progress
      FROM goals 
      WHERE user_id = ?
      GROUP BY category
      ORDER BY total_goals DESC
      ''',
      variables: [Variable.withString(userId)],
    ).get();

    return result.map((row) => row.data).toList();
  }

  /// Gets goal completion trend data
  Future<List<Map<String, dynamic>>> getGoalCompletionTrend(
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
        COUNT(g.id) as completed_count
      FROM dates d
      LEFT JOIN goals g ON date(g.completed_at) = d.day AND g.user_id = ?
      WHERE g.status = 'completed' OR g.status IS NULL
      GROUP BY d.day
      ORDER BY d.day
      ''',
      variables: [Variable.withString(userId)],
    ).get();

    return result.map((row) => row.data).toList();
  }

  /// Gets priority distribution
  Future<List<Map<String, dynamic>>> getPriorityDistribution(String userId) async {
    final result = await customSelect(
      '''
      SELECT 
        priority,
        COUNT(*) as goal_count
      FROM goals 
      WHERE user_id = ?
      GROUP BY priority
      ORDER BY goal_count DESC
      ''',
      variables: [Variable.withString(userId)],
    ).get();

    return result.map((row) => row.data).toList();
  }

  /// Gets status distribution
  Future<List<Map<String, dynamic>>> getStatusDistribution(String userId) async {
    final result = await customSelect(
      '''
      SELECT 
        status,
        COUNT(*) as goal_count
      FROM goals 
      WHERE user_id = ?
      GROUP BY status
      ORDER BY goal_count DESC
      ''',
      variables: [Variable.withString(userId)],
    ).get();

    return result.map((row) => row.data).toList();
  }
}