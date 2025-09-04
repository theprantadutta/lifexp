import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';

import '../../shared/services/lru_cache_service.dart';
import '../database/database.dart';
import '../models/progress.dart';

/// Repository for managing progress data with analytics aggregation
class ProgressRepository {
  ProgressRepository({required LifeXPDatabase database}) : _database = database;

  final LifeXPDatabase _database;

  // LRU Cache for progress data
  final _progressCache = LRUCache<String, List<ProgressEntry>>(100); // Max 100 user entries
  final _singleProgressCache = LRUCache<String, ProgressEntry>(200); // Max 200 individual entries
  final _statsCache = LRUCache<String, Map<String, dynamic>>(50); // Max 50 stats entries

  // Cache expiration time (5 minutes for progress data as it updates
  // frequently)
  static const Duration _cacheExpiration = Duration(minutes: 5);

  // Cache timestamps for expiration tracking
  final Map<String, DateTime> _cacheTimestamps = {};

  // Stream controllers for real-time updates
  final Map<String, StreamController<List<ProgressEntry>>>
  _progressStreamControllers = {};
  final Map<String, StreamController<ProgressEntry>>
  _dailyProgressStreamControllers = {};

  /// Gets all progress entries for a user with caching
  Future<List<ProgressEntry>> getProgressEntriesByUserId(String userId) async {
    // Check cache first
    final cachedEntries = _getCachedProgressEntries(userId);
    if (cachedEntries != null) {
      return cachedEntries;
    }

    // Fetch from database
    final entryDataList = await _database.progressDao
        .getProgressEntriesByUserId(userId);
    final entries = entryDataList.map(_convertFromData).toList();

    _cacheProgressEntries(userId, entries);
    return entries;
  }

  /// Gets progress entry by ID
  Future<ProgressEntry?> getProgressEntryById(String entryId) async {
    // Check if entry exists in any cached list
    final cachedEntry = _getCachedEntryById(entryId);
    if (cachedEntry != null) {
      return cachedEntry;
    }

    // Fetch from database
    final entryData = await _database.progressDao.getProgressEntryById(entryId);
    if (entryData == null) return null;

    return _convertFromData(entryData);
  }

  /// Gets progress entry for a specific date
  Future<ProgressEntry?> getProgressEntryByDate(
    String userId,
    DateTime date,
  ) async {
    final entryData = await _database.progressDao.getProgressEntryByDate(
      userId,
      date,
    );
    if (entryData == null) return null;

    return _convertFromData(entryData);
  }

  /// Gets progress entries for a date range
  Future<List<ProgressEntry>> getProgressEntriesInRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final entryDataList = await _database.progressDao.getProgressEntriesInRange(
      userId,
      startDate,
      endDate,
    );
    return entryDataList.map(_convertFromData).toList();
  }

  /// Gets progress entries by category
  Future<List<ProgressEntry>> getProgressEntriesByCategory(
    String userId,
    String category,
  ) async {
    final entryDataList = await _database.progressDao
        .getProgressEntriesByCategory(userId, category);
    return entryDataList.map(_convertFromData).toList();
  }

  /// Gets recent progress entries
  Future<List<ProgressEntry>> getRecentProgressEntries(
    String userId, {
    int days = 30,
  }) async {
    final entryDataList = await _database.progressDao.getRecentProgressEntries(
      userId,
      days: days,
    );
    return entryDataList.map(_convertFromData).toList();
  }

  /// Creates or updates today's progress entry
  Future<ProgressEntry> createOrUpdateTodayEntry(
    String userId,
    int xpGain,
    int tasksCompleted, {
    String? category,
    Map<String, int>? categoryBreakdown,
    Map<String, int>? taskTypeBreakdown,
    int? streakCount,
    int? levelAtTime,
  }) async {
    final entryData = await _database.progressDao.createOrUpdateTodayEntry(
      userId,
      xpGain,
      tasksCompleted,
      category: category,
      categoryBreakdown: categoryBreakdown,
      taskTypeBreakdown: taskTypeBreakdown,
      streakCount: streakCount,
      levelAtTime: levelAtTime,
    );

    final entry = _convertFromData(entryData);

    // Invalidate cache and notify listeners
    _invalidateUserCache(userId);
    await _notifyProgressUpdate(userId);
    _notifyDailyProgressUpdate(userId, entry);

    return entry;
  }

  /// Adds XP to today's progress entry
  Future<ProgressEntry> addXPToToday(
    String userId,
    int xpGain, {
    String? category,
  }) async {
    final entryData = await _database.progressDao.addXPToToday(
      userId,
      xpGain,
      category: category,
    );

    final entry = _convertFromData(entryData);

    // Invalidate cache and notify listeners
    _invalidateUserCache(userId);
    await _notifyProgressUpdate(userId);
    _notifyDailyProgressUpdate(userId, entry);

    return entry;
  }

  /// Adds completed task to today's progress entry
  Future<ProgressEntry> addTaskToToday(
    String userId, {
    String? taskType,
  }) async {
    final entryData = await _database.progressDao.addTaskToToday(
      userId,
      taskType: taskType,
    );

    final entry = _convertFromData(entryData);

    // Invalidate cache and notify listeners
    _invalidateUserCache(userId);
    await _notifyProgressUpdate(userId);
    _notifyDailyProgressUpdate(userId, entry);

    return entry;
  }

  /// Records comprehensive progress update
  Future<ProgressEntry> recordProgressUpdate({
    required String userId,
    required int xpGain,
    required int tasksCompleted,
    required int streakCount,
    required int currentLevel,
    String? category,
    Map<String, int>? categoryBreakdown,
    Map<String, int>? taskTypeBreakdown,
    Map<String, dynamic>? additionalMetrics,
  }) async => createOrUpdateTodayEntry(
    userId,
    xpGain,
    tasksCompleted,
    category: category,
    categoryBreakdown: categoryBreakdown,
    taskTypeBreakdown: taskTypeBreakdown,
    streakCount: streakCount,
    levelAtTime: currentLevel,
  );

  /// Gets daily XP trend data for charts
  Future<List<Map<String, dynamic>>> getDailyXPTrend(
    String userId, {
    int days = 30,
  }) async => _database.progressDao.getDailyXPTrend(userId, days: days);

  /// Gets weekly progress summary
  Future<List<Map<String, dynamic>>> getWeeklyProgressSummary(
    String userId, {
    int weeks = 12,
  }) async =>
      _database.progressDao.getWeeklyProgressSummary(userId, weeks: weeks);

  /// Gets monthly progress summary
  Future<List<Map<String, dynamic>>> getMonthlyProgressSummary(
    String userId, {
    int months = 12,
  }) async =>
      _database.progressDao.getMonthlyProgressSummary(userId, months: months);

  /// Gets category breakdown for a time period
  Future<List<Map<String, dynamic>>> getCategoryBreakdown(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async =>
      _database.progressDao.getCategoryBreakdown(userId, startDate, endDate);

  /// Gets overall progress statistics
  Future<Map<String, dynamic>> getProgressStats(String userId) async =>
      _database.progressDao.getProgressStats(userId);

  /// Gets productivity streaks
  Future<List<Map<String, dynamic>>> getProductivityStreaks(
    String userId, {
    int minXP = 50,
    int minTasks = 3,
  }) async => _database.progressDao.getProductivityStreaks(
    userId,
    minXP: minXP,
    minTasks: minTasks,
  );

  /// Gets batch analytics for performance optimization
  Future<Map<String, dynamic>> getBatchAnalytics(
    String userId, {
    int days = 30,
  }) async => _database.progressDao.getBatchAnalytics(userId, days: days);

  /// Aggregates progress entries by date
  Future<Map<String, ProgressSummary>> aggregateProgressByDate(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final entries = await getProgressEntriesInRange(userId, startDate, endDate);
    return ProgressAggregator.aggregateByDate(entries);
  }

  /// Aggregates progress entries by week
  Future<Map<String, ProgressSummary>> aggregateProgressByWeek(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final entries = await getProgressEntriesInRange(userId, startDate, endDate);
    return ProgressAggregator.aggregateByWeek(entries);
  }

  /// Aggregates progress entries by month
  Future<Map<String, ProgressSummary>> aggregateProgressByMonth(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final entries = await getProgressEntriesInRange(userId, startDate, endDate);
    return ProgressAggregator.aggregateByMonth(entries);
  }

  /// Calculates trend data for chart display
  Future<List<ChartDataPoint>> calculateTrend(
    String userId,
    TrendType type, {
    int? limitDays,
  }) async {
    final entries = limitDays != null
        ? await getRecentProgressEntries(userId, days: limitDays)
        : await getProgressEntriesByUserId(userId);

    return ProgressAggregator.calculateTrend(
      entries,
      type: type,
      limitDays: limitDays,
    );
  }

  /// Analyzes progress patterns and provides insights
  Future<Map<String, dynamic>> analyzeProgressPatterns(String userId) async {
    final stats = await getProgressStats(userId);
    final recentEntries = await getRecentProgressEntries(userId);
    final streaks = await getProductivityStreaks(userId);

    // Calculate patterns
    final weekdayPerformance = _analyzeWeekdayPerformance(recentEntries);
    final categoryTrends = await _analyzeCategoryTrends(userId);
    final consistencyScore = _calculateConsistencyScore(recentEntries);
    final improvementTrend = _calculateImprovementTrend(recentEntries);

    return {
      'overall_stats': stats,
      'weekday_performance': weekdayPerformance,
      'category_trends': categoryTrends,
      'consistency_score': consistencyScore,
      'improvement_trend': improvementTrend,
      'productivity_streaks': streaks,
      'insights': _generateInsights(recentEntries, streaks),
    };
  }

  /// Generates personalized progress insights
  Future<List<String>> generateProgressInsights(String userId) async {
    final analysis = await analyzeProgressPatterns(userId);
    return analysis['insights'] as List<String>;
  }

  /// Predicts future progress based on current trends
  Future<Map<String, dynamic>> predictFutureProgress(
    String userId, {
    int daysAhead = 30,
  }) async {
    final recentEntries = await getRecentProgressEntries(userId);

    if (recentEntries.isEmpty) {
      return {
        'predicted_xp': 0,
        'predicted_tasks': 0,
        'confidence': 0.0,
        'trend': 'insufficient_data',
      };
    }

    // Simple linear regression for prediction
    final xpTrend = _calculateLinearTrend(
      recentEntries.map((e) => e.xpGained.toDouble()).toList(),
    );
    final taskTrend = _calculateLinearTrend(
      recentEntries.map((e) => e.tasksCompleted.toDouble()).toList(),
    );

    final avgXP =
        recentEntries.fold(0, (sum, e) => sum + e.xpGained) /
        recentEntries.length;
    final avgTasks =
        recentEntries.fold(0, (sum, e) => sum + e.tasksCompleted) /
        recentEntries.length;

    final predictedDailyXP = (avgXP + (xpTrend * daysAhead / 2)).clamp(
      0,
      double.infinity,
    );
    final predictedDailyTasks = (avgTasks + (taskTrend * daysAhead / 2)).clamp(
      0,
      double.infinity,
    );

    return {
      'predicted_daily_xp': predictedDailyXP.round(),
      'predicted_daily_tasks': predictedDailyTasks.round(),
      'predicted_total_xp': (predictedDailyXP * daysAhead).round(),
      'predicted_total_tasks': (predictedDailyTasks * daysAhead).round(),
      'confidence': _calculatePredictionConfidence(recentEntries),
      'trend': xpTrend > 0
          ? 'improving'
          : xpTrend < 0
          ? 'declining'
          : 'stable',
    };
  }

  /// Gets progress comparison with previous periods
  Future<Map<String, dynamic>> getProgressComparison(
    String userId, {
    int days = 30,
  }) async {
    final now = DateTime.now();
    final currentPeriodStart = now.subtract(Duration(days: days));
    final previousPeriodStart = currentPeriodStart.subtract(
      Duration(days: days),
    );

    final currentEntries = await getProgressEntriesInRange(
      userId,
      currentPeriodStart,
      now,
    );
    final previousEntries = await getProgressEntriesInRange(
      userId,
      previousPeriodStart,
      currentPeriodStart,
    );

    final currentStats = _calculatePeriodStats(currentEntries);
    final previousStats = _calculatePeriodStats(previousEntries);

    return {
      'current_period': currentStats,
      'previous_period': previousStats,
      'xp_change': currentStats['total_xp'] - previousStats['total_xp'],
      'tasks_change':
          currentStats['total_tasks'] - previousStats['total_tasks'],
      'xp_change_percent': previousStats['total_xp'] > 0
          ? ((currentStats['total_xp'] - previousStats['total_xp']) /
                previousStats['total_xp'] *
                100)
          : 0.0,
      'tasks_change_percent': previousStats['total_tasks'] > 0
          ? ((currentStats['total_tasks'] - previousStats['total_tasks']) /
                previousStats['total_tasks'] *
                100)
          : 0.0,
    };
  }

  /// Gets progress stream for real-time updates
  Stream<List<ProgressEntry>> getProgressStream(String userId) {
    if (!_progressStreamControllers.containsKey(userId)) {
      _progressStreamControllers[userId] =
          StreamController<List<ProgressEntry>>.broadcast();
    }
    return _progressStreamControllers[userId]!.stream;
  }

  /// Gets daily progress stream for real-time updates
  Stream<ProgressEntry> getDailyProgressStream(String userId) {
    if (!_dailyProgressStreamControllers.containsKey(userId)) {
      _dailyProgressStreamControllers[userId] =
          StreamController<ProgressEntry>.broadcast();
    }
    return _dailyProgressStreamControllers[userId]!.stream;
  }

  /// Batch operations for sync
  Future<void> batchUpdateProgressEntries(
    List<ProgressEntry> entries,
    String userId,
  ) async {
    final companions = entries.map(_convertToCompanion).toList();
    await _database.progressDao.batchUpdateProgressEntries(companions);

    // Clear cache and notify
    _invalidateUserCache(userId);
    await _notifyProgressUpdate(userId);
  }

  /// Sync progress data with cloud
  Future<void> syncProgressData(
    String userId,
    List<Map<String, dynamic>> syncData,
  ) async {
    await _database.progressDao.batchSyncProgressEntries(userId, syncData);

    // Clear cache and notify
    _invalidateUserCache(userId);
    await _notifyProgressUpdate(userId);
  }

  /// Cleans up old progress entries
  Future<int> cleanupOldEntries(String userId, {int keepDays = 365}) async {
    final deletedCount = await _database.progressDao.cleanupOldEntries(
      userId,
      keepDays: keepDays,
    );

    if (deletedCount > 0) {
      _invalidateUserCache(userId);
      await _notifyProgressUpdate(userId);
    }

    return deletedCount;
  }

  /// Disposes resources
  void dispose() {
    for (final controller in _progressStreamControllers.values) {
      controller.close();
    }
    for (final controller in _dailyProgressStreamControllers.values) {
      controller.close();
    }
    _progressStreamControllers.clear();
    _dailyProgressStreamControllers.clear();
    _clearCache();
  }

  // Private helper methods

  /// Gets cached progress entries for user
  List<ProgressEntry>? _getCachedProgressEntries(String userId) {
    // Check if cache has expired
    final timestamp = _cacheTimestamps[userId];
    if (timestamp != null && 
        DateTime.now().difference(timestamp) > _cacheExpiration) {
      // Cache expired, remove it
      _progressCache.remove(userId);
      _cacheTimestamps.remove(userId);
      return null;
    }
    
    // Try to get from LRU cache
    return _progressCache.get(userId);
  }

  /// Gets cached entry by ID from any user's cache
  ProgressEntry? _getCachedEntryById(String entryId) {
    // Try to get from single entry cache first
    final cachedEntry = _singleProgressCache.get(entryId);
    if (cachedEntry != null) {
      return cachedEntry;
    }
    
    // Check all user caches
    for (final userId in _progressCache.keys) {
      final entries = _progressCache.get(userId);
      if (entries != null) {
        final entry = entries.where((e) => e.id == entryId).firstOrNull;
        if (entry != null) {
          // Cache this individual entry for faster access next time
          _singleProgressCache.put(entryId, entry);
          return entry;
        }
      }
    }
    return null;
  }

  /// Caches progress entries for user
  void _cacheProgressEntries(String userId, List<ProgressEntry> entries) {
    _progressCache.put(userId, entries);
    _cacheTimestamps[userId] = DateTime.now();
    
    // Also cache individual entries for faster access
    for (final entry in entries) {
      _singleProgressCache.put(entry.id, entry);
    }
  }

  /// Invalidates cache for specific user
  void _invalidateUserCache(String userId) {
    _progressCache.remove(userId);
    _cacheTimestamps.remove(userId);
  }

  /// Invalidates all caches
  void _invalidateAllCaches() {
    _progressCache.clear();
    _singleProgressCache.clear();
    _statsCache.clear();
    _cacheTimestamps.clear();
  }

  /// Clears all cache
  void _clearCache() {
    _invalidateAllCaches();
  }

  /// Notifies progress update
  Future<void> _notifyProgressUpdate(String userId) async {
    final controller = _progressStreamControllers[userId];
    if (controller != null && !controller.isClosed) {
      final entries = await getProgressEntriesByUserId(userId);
      controller.add(entries);
    }
  }

  /// Notifies daily progress update
  void _notifyDailyProgressUpdate(String userId, ProgressEntry entry) {
    final controller = _dailyProgressStreamControllers[userId];
    if (controller != null && !controller.isClosed) {
      controller.add(entry);
    }
  }

  /// Analyzes weekday performance patterns
  Map<String, double> _analyzeWeekdayPerformance(List<ProgressEntry> entries) {
    final weekdayTotals = <int, List<int>>{};

    for (final entry in entries) {
      final weekday = entry.date.weekday;
      weekdayTotals[weekday] = (weekdayTotals[weekday] ?? [])
        ..add(entry.xpGained);
    }

    final weekdayAverages = <String, double>{};
    final weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    for (var i = 1; i <= 7; i++) {
      final values = weekdayTotals[i] ?? [];
      final average = values.isEmpty
          ? 0.0
          : values.fold(0, (sum, xp) => sum + xp) / values.length;
      weekdayAverages[weekdays[i - 1]] = average;
    }

    return weekdayAverages;
  }

  /// Analyzes category trends
  Future<Map<String, dynamic>> _analyzeCategoryTrends(String userId) async {
    final categoryBreakdown = await getCategoryBreakdown(
      userId,
      DateTime.now().subtract(const Duration(days: 30)),
      DateTime.now(),
    );

    return {
      'category_totals': Map.fromEntries(
        categoryBreakdown.map(
          (item) =>
              MapEntry(item['category'] as String, item['total_xp'] as int),
        ),
      ),
      'dominant_category': categoryBreakdown.isNotEmpty
          ? categoryBreakdown.first['category'] as String
          : 'none',
    };
  }

  /// Calculates consistency score (0-100)
  double _calculateConsistencyScore(List<ProgressEntry> entries) {
    if (entries.length < 7) return 0;

    final sortedEntries = List<ProgressEntry>.from(entries)
      ..sort((a, b) => a.date.compareTo(b.date));

    var consistentDays = 0;
    final avgXP =
        entries.fold(0, (sum, e) => sum + e.xpGained) / entries.length;
    final threshold = avgXP * 0.5; // 50% of average is considered consistent

    for (final entry in sortedEntries) {
      if (entry.xpGained >= threshold) {
        consistentDays++;
      }
    }

    return (consistentDays / entries.length * 100).clamp(0.0, 100.0);
  }

  /// Calculates improvement trend
  double _calculateImprovementTrend(List<ProgressEntry> entries) {
    if (entries.length < 2) return 0;

    final sortedEntries = List<ProgressEntry>.from(entries)
      ..sort((a, b) => a.date.compareTo(b.date));

    final firstHalf = sortedEntries.take(sortedEntries.length ~/ 2).toList();
    final secondHalf = sortedEntries.skip(sortedEntries.length ~/ 2).toList();

    final firstHalfAvg =
        firstHalf.fold(0, (sum, e) => sum + e.xpGained) / firstHalf.length;
    final secondHalfAvg =
        secondHalf.fold(0, (sum, e) => sum + e.xpGained) / secondHalf.length;

    return secondHalfAvg - firstHalfAvg;
  }

  /// Generates insights based on progress data
  List<String> _generateInsights(
    List<ProgressEntry> entries,
    List<Map<String, dynamic>> streaks,
  ) {
    final insights = <String>[];

    if (entries.isEmpty) {
      insights.add('Start tracking your progress to see insights!');
      return insights;
    }

    // Consistency insights
    final consistencyScore = _calculateConsistencyScore(entries);
    if (consistencyScore >= 80) {
      insights.add(
        "🔥 Excellent consistency! You're maintaining great daily habits.",
      );
    } else if (consistencyScore >= 60) {
      insights.add('👍 Good consistency! Try to maintain your daily routine.');
    } else {
      insights.add('💪 Focus on building more consistent daily habits.');
    }

    // Streak insights
    if (streaks.isNotEmpty) {
      final longestStreak = streaks.first['streak_length'] as int;
      if (longestStreak >= 30) {
        insights.add(
          '🏆 Amazing! Your longest productive streak is $longestStreak days!',
        );
      } else if (longestStreak >= 7) {
        insights.add(
          '⭐ Great job! Your longest streak is $longestStreak days.',
        );
      }
    }

    // Improvement insights
    final improvementTrend = _calculateImprovementTrend(entries);
    if (improvementTrend > 10) {
      insights.add(
        "📈 You're improving! Your recent performance is trending upward.",
      );
    } else if (improvementTrend < -10) {
      insights.add(
        '📉 Consider reviewing your goals - recent performance has declined.',
      );
    }

    // Weekday insights
    final weekdayPerformance = _analyzeWeekdayPerformance(entries);
    final bestDay = weekdayPerformance.entries.reduce(
      (a, b) => a.value > b.value ? a : b,
    );
    insights.add('🗓️ Your most productive day is ${bestDay.key}.');

    return insights;
  }

  /// Calculates linear trend
  double _calculateLinearTrend(List<double> values) {
    if (values.length < 2) return 0;

    final n = values.length;
    final sumX = (n * (n - 1)) / 2; // Sum of indices
    final sumY = values.reduce((sum, value) => sum + value);
    final sumXY = values.asMap().entries.fold(
      0.0,
      (sum, entry) => sum + (entry.key.toDouble() * entry.value),
    );
    final sumX2 = (n * (n - 1) * (2 * n - 1)) / 6; // Sum of squared indices

    final slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX);
    return slope;
  }

  /// Calculates prediction confidence
  double _calculatePredictionConfidence(List<ProgressEntry> entries) {
    if (entries.length < 7) {
      return 0.2;
    }
    if (entries.length < 14) {
      return 0.5;
    }
    if (entries.length < 30) {
      return 0.7;
    }
    return 0.9;
  }

  /// Calculates period statistics
  Map<String, dynamic> _calculatePeriodStats(List<ProgressEntry> entries) {
    if (entries.isEmpty) {
      return {
        'total_xp': 0,
        'total_tasks': 0,
        'avg_xp': 0.0,
        'avg_tasks': 0.0,
        'max_streak': 0,
        'entry_count': 0,
      };
    }

    final totalXP = entries.fold(0, (sum, e) => sum + e.xpGained);
    final totalTasks = entries.fold(0, (sum, e) => sum + e.tasksCompleted);
    final maxStreak = entries.fold(
      0,
      (max, e) => e.streakCount > max ? e.streakCount : max,
    );

    return {
      'total_xp': totalXP,
      'total_tasks': totalTasks,
      'avg_xp': totalXP / entries.length,
      'avg_tasks': totalTasks / entries.length,
      'max_streak': maxStreak,
      'entry_count': entries.length,
    };
  }

  /// Converts database data to ProgressEntry model
  ProgressEntry _convertFromData(ProgressEntryData data) {
    final categoryBreakdown = data.categoryBreakdown.isNotEmpty
        ? Map<String, int>.from(json.decode(data.categoryBreakdown) as Map)
        : <String, int>{};

    final taskTypeBreakdown = data.taskTypeBreakdown.isNotEmpty
        ? Map<String, int>.from(json.decode(data.taskTypeBreakdown) as Map)
        : <String, int>{};

    final additionalMetrics = data.additionalMetrics.isNotEmpty
        ? Map<String, dynamic>.from(json.decode(data.additionalMetrics) as Map)
        : <String, dynamic>{};

    return ProgressEntry(
      id: data.id,
      userId: data.userId,
      date: data.date,
      xpGained: data.xpGained,
      tasksCompleted: data.tasksCompleted,
      category: data.category,
      categoryBreakdown: categoryBreakdown,
      taskTypeBreakdown: taskTypeBreakdown,
      streakCount: data.streakCount,
      levelAtTime: data.levelAtTime,
      additionalMetrics: additionalMetrics,
      createdAt: data.createdAt,
      updatedAt: data.updatedAt,
    );
  }

  /// Converts ProgressEntry model to database companion
  ProgressEntriesCompanion _convertToCompanion(ProgressEntry entry) =>
      ProgressEntriesCompanion.insert(
        id: entry.id,
        userId: entry.userId,
        date: entry.date,
        xpGained: Value(entry.xpGained),
        tasksCompleted: Value(entry.tasksCompleted),
        category: Value(entry.category),
        categoryBreakdown: Value(json.encode(entry.categoryBreakdown)),
        taskTypeBreakdown: Value(json.encode(entry.taskTypeBreakdown)),
        streakCount: Value(entry.streakCount),
        levelAtTime: Value(entry.levelAtTime),
        additionalMetrics: Value(json.encode(entry.additionalMetrics)),
        createdAt: entry.createdAt,
        updatedAt: entry.updatedAt,
      );
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
