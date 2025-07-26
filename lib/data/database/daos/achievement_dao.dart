part of '../database.dart';

/// Data Access Object for Achievement operations
@DriftAccessor(tables: [Achievements, Users])
class AchievementDao extends DatabaseAccessor<LifeXPDatabase>
    with _$AchievementDaoMixin {
  AchievementDao(super.db);

  /// Gets all achievements for a user
  Future<List<AchievementData>> getAchievementsByUserId(String userId) async =>
      (select(achievements)
            ..where((a) => a.userId.equals(userId))
            ..orderBy([(a) => OrderingTerm.desc(a.createdAt)]))
          .get();

  /// Gets achievement by ID
  Future<AchievementData?> getAchievementById(String id) async =>
      (select(achievements)..where((a) => a.id.equals(id))).getSingleOrNull();

  /// Gets unlocked achievements
  Future<List<AchievementData>> getUnlockedAchievements(String userId) async =>
      (select(achievements)
            ..where((a) => a.userId.equals(userId) & a.isUnlocked.equals(true))
            ..orderBy([(a) => OrderingTerm.desc(a.unlockedAt)]))
          .get();

  /// Gets locked achievements
  Future<List<AchievementData>> getLockedAchievements(String userId) async =>
      (select(achievements)
            ..where((a) => a.userId.equals(userId) & a.isUnlocked.equals(false))
            ..orderBy([(a) => OrderingTerm.desc(a.progress)]))
          .get();

  /// Gets achievements by type
  Future<List<AchievementData>> getAchievementsByType(
    String userId,
    String achievementType,
  ) async =>
      (select(achievements)
            ..where(
              (a) =>
                  a.userId.equals(userId) &
                  a.achievementType.equals(achievementType),
            )
            ..orderBy([(a) => OrderingTerm.desc(a.progress)]))
          .get();

  /// Gets achievements that can be unlocked
  Future<List<AchievementData>> getUnlockableAchievements(String userId) async {
    final result = await customSelect(
      r'''
      SELECT a.* FROM achievements a
      WHERE a.user_id = ? 
        AND a.is_unlocked = 0
        AND JSON_EXTRACT(a.criteria, '$.targetValue') <= a.progress
      ORDER BY a.progress DESC
      ''',
      variables: [Variable.withString(userId)],
    ).get();

    return result
        .map(
          (row) => AchievementData.fromJson(row.data.cast<String, dynamic>()),
        )
        .toList();
  }

  /// Creates a new achievement
  Future<void> createAchievement(AchievementsCompanion achievement) async {
    await into(achievements).insert(achievement);
  }

  /// Updates achievement data
  Future<bool> updateAchievement(AchievementsCompanion achievement) async =>
      update(achievements).replace(achievement);

  /// Updates achievement progress
  Future<AchievementData?> updateProgress(
    String achievementId,
    int newProgress,
  ) async => transaction(() async {
    final achievement = await getAchievementById(achievementId);
    if (achievement == null || achievement.isUnlocked) {
      return null;
    }

    // Parse criteria to check if achievement should be unlocked
    final criteriaMap =
        json.decode(achievement.criteria) as Map<String, dynamic>;
    final targetValue = criteriaMap['targetValue'] as int;
    final shouldUnlock = newProgress >= targetValue;

    final updatedAchievement = AchievementsCompanion(
      id: Value(achievementId),
      progress: Value(newProgress),
      isUnlocked: Value(shouldUnlock),
      unlockedAt: shouldUnlock ? Value(DateTime.now()) : const Value.absent(),
      updatedAt: Value(DateTime.now()),
    );

    await update(achievements).replace(updatedAchievement);
    return getAchievementById(achievementId);
  });

  /// Increments achievement progress
  Future<AchievementData?> incrementProgress(
    String achievementId,
    int amount,
  ) async {
    if (amount <= 0) {
      return null;
    }

    final achievement = await getAchievementById(achievementId);
    if (achievement == null) {
      return null;
    }

    return updateProgress(achievementId, achievement.progress + amount);
  }

  /// Unlocks achievement manually
  Future<bool> unlockAchievement(String achievementId) async =>
      transaction(() async {
        final achievement = await getAchievementById(achievementId);
        if (achievement == null || achievement.isUnlocked) {
          return false;
        }

        // Parse criteria to set progress to target value
        final criteriaMap =
            json.decode(achievement.criteria) as Map<String, dynamic>;
        final targetValue = criteriaMap['targetValue'] as int;

        final result =
            await (update(
              achievements,
            )..where((a) => a.id.equals(achievementId))).write(
              AchievementsCompanion(
                isUnlocked: const Value(true),
                progress: Value(targetValue),
                unlockedAt: Value(DateTime.now()),
                updatedAt: Value(DateTime.now()),
              ),
            );
        return result > 0;
      });

  /// Resets achievement (for testing/admin purposes)
  Future<bool> resetAchievement(String achievementId) async {
    final result =
        await (update(
          achievements,
        )..where((a) => a.id.equals(achievementId))).write(
          const AchievementsCompanion(
            isUnlocked: Value(false),
            progress: Value(0),
          ),
        );
    return result > 0;
  }

  /// Checks and updates achievements based on criteria
  Future<List<AchievementData>> checkAndUpdateAchievements(
    String userId,
    Map<String, dynamic> userStats,
  ) async {
    final unlockedAchievements = <AchievementData>[];
    final lockedAchievements = await getLockedAchievements(userId);

    for (final achievement in lockedAchievements) {
      final criteriaMap =
          json.decode(achievement.criteria) as Map<String, dynamic>;
      final newProgress = _calculateProgress(
        achievement.achievementType,
        criteriaMap,
        userStats,
      );

      if (newProgress > achievement.progress) {
        final updatedAchievement = await updateProgress(
          achievement.id,
          newProgress,
        );
        if (updatedAchievement != null && updatedAchievement.isUnlocked) {
          unlockedAchievements.add(updatedAchievement);
        }
      }
    }

    return unlockedAchievements;
  }

  /// Gets achievement statistics
  Future<Map<String, dynamic>> getAchievementStats(String userId) async {
    final result = await customSelect(
      '''
      SELECT 
        COUNT(*) as total_achievements,
        COUNT(CASE WHEN is_unlocked = 1 THEN 1 END) as unlocked_achievements,
        COUNT(CASE WHEN is_unlocked = 0 THEN 1 END) as locked_achievements,
        AVG(CASE WHEN is_unlocked = 1 THEN progress END) as avg_progress_unlocked,
        COUNT(CASE WHEN achievement_type = 'streak' AND is_unlocked = 1 THEN 1 END) as streak_achievements,
        COUNT(CASE WHEN achievement_type = 'total' AND is_unlocked = 1 THEN 1 END) as total_achievements_unlocked,
        COUNT(CASE WHEN achievement_type = 'milestone' AND is_unlocked = 1 THEN 1 END) as milestone_achievements
      FROM achievements 
      WHERE user_id = ?
      ''',
      variables: [Variable.withString(userId)],
    ).getSingleOrNull();

    return result?.data ?? {};
  }

  /// Gets recent achievement unlocks
  Future<List<AchievementData>> getRecentUnlocks(
    String userId, {
    int days = 7,
  }) async {
    final cutoffDate = DateTime.now().subtract(Duration(days: days));

    return (select(achievements)
          ..where(
            (a) =>
                a.userId.equals(userId) &
                a.isUnlocked.equals(true) &
                a.unlockedAt.isBiggerThanValue(cutoffDate),
          )
          ..orderBy([(a) => OrderingTerm.desc(a.unlockedAt)]))
        .get();
  }

  /// Deletes achievement
  Future<bool> deleteAchievement(String achievementId) async {
    final result = await (delete(
      achievements,
    )..where((a) => a.id.equals(achievementId))).go();
    return result > 0;
  }

  /// Batch operations for sync
  Future<void> batchUpdateAchievements(
    List<AchievementsCompanion> achievementUpdates,
  ) async {
    await batch((batch) {
      for (final achievement in achievementUpdates) {
        batch.replace(achievements, achievement);
      }
    });
  }

  /// Optimized criteria checking with batch processing
  Future<List<AchievementData>> batchCheckCriteria(
    String userId,
    Map<String, dynamic> userStats,
  ) async => transaction(() async {
    final unlockedAchievements = <AchievementData>[];

    // Get all locked achievements in one query
    final lockedAchievements = await customSelect(
      '''
      SELECT * FROM achievements 
      WHERE user_id = ? AND is_unlocked = 0
      ORDER BY achievement_type, progress DESC
      ''',
      variables: [Variable.withString(userId)],
    ).get();

    final achievementUpdates = <AchievementsCompanion>[];

    for (final row in lockedAchievements) {
      final achievement = AchievementData.fromJson(
        row.data.cast<String, dynamic>(),
      );
      final criteriaMap =
          json.decode(achievement.criteria) as Map<String, dynamic>;
      final newProgress = _calculateProgress(
        achievement.achievementType,
        criteriaMap,
        userStats,
      );

      if (newProgress > achievement.progress) {
        final targetValue = criteriaMap['targetValue'] as int;
        final shouldUnlock = newProgress >= targetValue;

        final updatedAchievement = AchievementsCompanion(
          id: Value(achievement.id),
          progress: Value(newProgress),
          isUnlocked: Value(shouldUnlock),
          unlockedAt: shouldUnlock
              ? Value(DateTime.now())
              : const Value.absent(),
          updatedAt: Value(DateTime.now()),
        );

        achievementUpdates.add(updatedAchievement);

        if (shouldUnlock) {
          unlockedAchievements.add(
            achievement.copyWith(
              progress: newProgress,
              isUnlocked: true,
              unlockedAt: Value(DateTime.now()),
            ),
          );
        }
      }
    }

    // Batch update all achievements
    if (achievementUpdates.isNotEmpty) {
      await batch((batch) {
        for (final achievement in achievementUpdates) {
          batch.replace(achievements, achievement);
        }
      });
    }

    return unlockedAchievements;
  });

  /// Progress monitoring with detailed analytics
  Future<List<Map<String, dynamic>>> getProgressMonitoring(
    String userId,
  ) async {
    final result = await customSelect(
      '''
      SELECT 
        achievement_type,
        COUNT(*) as total_count,
        COUNT(CASE WHEN is_unlocked = 1 THEN 1 END) as unlocked_count,
        AVG(progress) as avg_progress,
        MIN(progress) as min_progress,
        MAX(progress) as max_progress,
        COUNT(CASE WHEN progress > 0 THEN 1 END) as started_count,
        ROUND(
          (COUNT(CASE WHEN is_unlocked = 1 THEN 1 END) * 100.0) / COUNT(*), 2
        ) as unlock_rate
      FROM achievements 
      WHERE user_id = ?
      GROUP BY achievement_type
      ORDER BY unlock_rate DESC, unlocked_count DESC
      ''',
      variables: [Variable.withString(userId)],
    ).get();

    return result.map((row) => row.data).toList();
  }

  /// Calculates progress based on achievement type and user stats
  int _calculateProgress(
    String achievementType,
    Map<String, dynamic> criteria,
    Map<String, dynamic> userStats,
  ) {
    switch (achievementType) {
      case 'streak':
        return userStats['maxStreak'] as int? ?? 0;

      case 'total':
        final category = criteria['category'] as String?;
        if (category != null) {
          return userStats['categoryTotals']?[category] as int? ?? 0;
        }
        return userStats['totalTasksCompleted'] as int? ?? 0;

      case 'milestone':
        return userStats['totalXP'] as int? ?? 0;

      case 'category':
        final category = criteria['category'] as String?;
        if (category != null) {
          return userStats['categoryTotals']?[category] as int? ?? 0;
        }
        return 0;

      case 'level':
        return userStats['level'] as int? ?? 1;

      case 'special':
        // Special achievements would have custom logic
        return userStats['specialMetric'] as int? ?? 0;

      default:
        return 0;
    }
  }
}
