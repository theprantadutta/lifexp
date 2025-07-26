import 'package:equatable/equatable.dart';

/// Represents a progress entry for tracking user analytics
class ProgressEntry extends Equatable {
  const ProgressEntry({
    required this.id,
    required this.userId,
    required this.date,
    required this.xpGained,
    required this.tasksCompleted,
    required this.categoryBreakdown,
    required this.taskTypeBreakdown,
    required this.streakCount,
    required this.levelAtTime,
    required this.createdAt,
    required this.updatedAt,
    this.category,
    this.additionalMetrics = const {},
  });

  /// Creates a new progress entry with default values
  factory ProgressEntry.create({
    required String id,
    required String userId,
    DateTime? date,
    int xpGained = 0,
    int tasksCompleted = 0,
    String? category,
    Map<String, int> categoryBreakdown = const {},
    Map<String, int> taskTypeBreakdown = const {},
    int streakCount = 0,
    int levelAtTime = 1,
    Map<String, dynamic> additionalMetrics = const {},
  }) {
    final now = DateTime.now();
    final entryDate = date ?? DateTime(now.year, now.month, now.day);

    return ProgressEntry(
      id: id,
      userId: userId,
      date: entryDate,
      xpGained: xpGained,
      tasksCompleted: tasksCompleted,
      category: category,
      categoryBreakdown: categoryBreakdown,
      taskTypeBreakdown: taskTypeBreakdown,
      streakCount: streakCount,
      levelAtTime: levelAtTime,
      additionalMetrics: additionalMetrics,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Creates from JSON
  factory ProgressEntry.fromJson(Map<String, dynamic> json) => ProgressEntry(
    id: json['id'] as String,
    userId: json['userId'] as String,
    date: DateTime.parse(json['date'] as String),
    xpGained: json['xpGained'] as int,
    tasksCompleted: json['tasksCompleted'] as int,
    category: json['category'] as String?,
    categoryBreakdown: Map<String, int>.from(
      json['categoryBreakdown'] as Map? ?? {},
    ),
    taskTypeBreakdown: Map<String, int>.from(
      json['taskTypeBreakdown'] as Map? ?? {},
    ),
    streakCount: json['streakCount'] as int,
    levelAtTime: json['levelAtTime'] as int,
    additionalMetrics: Map<String, dynamic>.from(
      json['additionalMetrics'] as Map? ?? {},
    ),
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );
  final String id;
  final String userId;
  final DateTime date;
  final int xpGained;
  final int tasksCompleted;
  final String? category; // Optional category filter
  final Map<String, int> categoryBreakdown; // XP breakdown by category
  final Map<String, int> taskTypeBreakdown; // Tasks breakdown by type
  final int streakCount;
  final int levelAtTime;
  final Map<String, dynamic> additionalMetrics;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Maximum XP that can be gained in a day
  static const int maxDailyXP = 999999;

  /// Maximum tasks that can be completed in a day
  static const int maxDailyTasks = 1000;

  /// Gets the date as a string key for grouping
  String get dateKey =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  /// Gets the week key for weekly grouping
  String get weekKey {
    final startOfWeek = date.subtract(Duration(days: date.weekday - 1));
    return '${startOfWeek.year}-W${_getWeekOfYear(startOfWeek).toString().padLeft(2, '0')}';
  }

  /// Gets the month key for monthly grouping
  String get monthKey =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}';

  /// Gets the year key for yearly grouping
  String get yearKey => date.year.toString();

  /// Calculates week of year
  int _getWeekOfYear(DateTime date) {
    final startOfYear = DateTime(date.year);
    final daysSinceStartOfYear = date.difference(startOfYear).inDays;
    return ((daysSinceStartOfYear + startOfYear.weekday - 1) / 7).ceil();
  }

  /// Validates progress entry data
  bool get isValid =>
      _validateUserId() &&
      _validateXPGained() &&
      _validateTasksCompleted() &&
      _validateStreakCount() &&
      _validateLevelAtTime() &&
      _validateBreakdowns();

  /// Validates user ID
  bool _validateUserId() => userId.isNotEmpty;

  /// Validates XP gained bounds
  bool _validateXPGained() => xpGained >= 0 && xpGained <= maxDailyXP;

  /// Validates tasks completed bounds
  bool _validateTasksCompleted() =>
      tasksCompleted >= 0 && tasksCompleted <= maxDailyTasks;

  /// Validates streak count
  bool _validateStreakCount() => streakCount >= 0;

  /// Validates level at time
  bool _validateLevelAtTime() => levelAtTime >= 1;

  /// Validates breakdown data consistency
  bool _validateBreakdowns() {
    // Category breakdown should sum to total XP (if not empty)
    if (categoryBreakdown.isNotEmpty) {
      final categorySum = categoryBreakdown.values.fold(
        0,
        (sum, value) => sum + value,
      );
      if (categorySum != xpGained) return false;
    }

    // Task type breakdown should sum to total tasks (if not empty)
    if (taskTypeBreakdown.isNotEmpty) {
      final taskSum = taskTypeBreakdown.values.fold(
        0,
        (sum, value) => sum + value,
      );
      if (taskSum != tasksCompleted) return false;
    }

    return true;
  }

  /// Adds XP to the entry
  ProgressEntry addXP(int xp, {String? fromCategory}) {
    if (xp <= 0) return this;

    final newXPGained = (xpGained + xp).clamp(0, maxDailyXP);
    final newCategoryBreakdown = Map<String, int>.from(categoryBreakdown);

    if (fromCategory != null) {
      newCategoryBreakdown[fromCategory] =
          (newCategoryBreakdown[fromCategory] ?? 0) + xp;
    }

    return copyWith(
      xpGained: newXPGained,
      categoryBreakdown: newCategoryBreakdown,
      updatedAt: DateTime.now(),
    );
  }

  /// Adds completed task to the entry
  ProgressEntry addTask({String? taskType}) {
    final newTasksCompleted = (tasksCompleted + 1).clamp(0, maxDailyTasks);
    final newTaskTypeBreakdown = Map<String, int>.from(taskTypeBreakdown);

    if (taskType != null) {
      newTaskTypeBreakdown[taskType] =
          (newTaskTypeBreakdown[taskType] ?? 0) + 1;
    }

    return copyWith(
      tasksCompleted: newTasksCompleted,
      taskTypeBreakdown: newTaskTypeBreakdown,
      updatedAt: DateTime.now(),
    );
  }

  /// Updates streak count
  ProgressEntry updateStreak(int newStreakCount) {
    if (newStreakCount < 0) return this;

    return copyWith(streakCount: newStreakCount, updatedAt: DateTime.now());
  }

  /// Updates level at time
  ProgressEntry updateLevel(int newLevel) {
    if (newLevel < 1) return this;

    return copyWith(levelAtTime: newLevel, updatedAt: DateTime.now());
  }

  /// Adds additional metric
  ProgressEntry addMetric(String key, value) {
    final newMetrics = Map<String, dynamic>.from(additionalMetrics);
    newMetrics[key] = value;

    return copyWith(additionalMetrics: newMetrics, updatedAt: DateTime.now());
  }

  /// Gets XP for specific category
  int getXPForCategory(String category) => categoryBreakdown[category] ?? 0;

  /// Gets tasks for specific type
  int getTasksForType(String taskType) => taskTypeBreakdown[taskType] ?? 0;

  /// Gets completion rate (tasks completed vs some target)
  double getCompletionRate(int targetTasks) {
    if (targetTasks <= 0) return 0;
    return (tasksCompleted / targetTasks).clamp(0.0, 1.0);
  }

  /// Gets XP efficiency (XP per task)
  double get xpEfficiency {
    if (tasksCompleted == 0) return 0;
    return xpGained / tasksCompleted;
  }

  /// Checks if this is a productive day (above average)
  bool isProductiveDay({int averageXP = 100, int averageTasks = 5}) =>
      xpGained >= averageXP || tasksCompleted >= averageTasks;

  /// Creates a copy with updated fields
  ProgressEntry copyWith({
    String? id,
    String? userId,
    DateTime? date,
    int? xpGained,
    int? tasksCompleted,
    String? category,
    Map<String, int>? categoryBreakdown,
    Map<String, int>? taskTypeBreakdown,
    int? streakCount,
    int? levelAtTime,
    Map<String, dynamic>? additionalMetrics,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => ProgressEntry(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    date: date ?? this.date,
    xpGained: xpGained ?? this.xpGained,
    tasksCompleted: tasksCompleted ?? this.tasksCompleted,
    category: category ?? this.category,
    categoryBreakdown: categoryBreakdown ?? this.categoryBreakdown,
    taskTypeBreakdown: taskTypeBreakdown ?? this.taskTypeBreakdown,
    streakCount: streakCount ?? this.streakCount,
    levelAtTime: levelAtTime ?? this.levelAtTime,
    additionalMetrics: additionalMetrics ?? this.additionalMetrics,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  /// Converts to JSON
  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'date': date.toIso8601String(),
    'xpGained': xpGained,
    'tasksCompleted': tasksCompleted,
    'category': category,
    'categoryBreakdown': categoryBreakdown,
    'taskTypeBreakdown': taskTypeBreakdown,
    'streakCount': streakCount,
    'levelAtTime': levelAtTime,
    'additionalMetrics': additionalMetrics,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  @override
  List<Object?> get props => [
    id,
    userId,
    date,
    xpGained,
    tasksCompleted,
    category,
    categoryBreakdown,
    taskTypeBreakdown,
    streakCount,
    levelAtTime,
    additionalMetrics,
    createdAt,
    updatedAt,
  ];

  @override
  String toString() =>
      'ProgressEntry(id: $id, date: $dateKey, xp: $xpGained, '
      'tasks: $tasksCompleted, streak: $streakCount, level: $levelAtTime)';
}

/// Utility class for aggregating progress data
class ProgressAggregator {
  /// Aggregates progress entries by date
  static Map<String, ProgressSummary> aggregateByDate(
    List<ProgressEntry> entries,
  ) {
    final grouped = <String, List<ProgressEntry>>{};

    for (final entry in entries) {
      final key = entry.dateKey;
      grouped[key] = (grouped[key] ?? [])..add(entry);
    }

    return grouped.map(
      (key, entries) =>
          MapEntry(key, ProgressSummary.fromEntries(entries, key)),
    );
  }

  /// Aggregates progress entries by week
  static Map<String, ProgressSummary> aggregateByWeek(
    List<ProgressEntry> entries,
  ) {
    final grouped = <String, List<ProgressEntry>>{};

    for (final entry in entries) {
      final key = entry.weekKey;
      grouped[key] = (grouped[key] ?? [])..add(entry);
    }

    return grouped.map(
      (key, entries) =>
          MapEntry(key, ProgressSummary.fromEntries(entries, key)),
    );
  }

  /// Aggregates progress entries by month
  static Map<String, ProgressSummary> aggregateByMonth(
    List<ProgressEntry> entries,
  ) {
    final grouped = <String, List<ProgressEntry>>{};

    for (final entry in entries) {
      final key = entry.monthKey;
      grouped[key] = (grouped[key] ?? [])..add(entry);
    }

    return grouped.map(
      (key, entries) =>
          MapEntry(key, ProgressSummary.fromEntries(entries, key)),
    );
  }

  /// Calculates trend data for chart display
  static List<ChartDataPoint> calculateTrend(
    List<ProgressEntry> entries, {
    required TrendType type,
    int? limitDays,
  }) {
    final sortedEntries = List<ProgressEntry>.from(entries)
      ..sort((a, b) => a.date.compareTo(b.date));

    final limitedEntries = limitDays != null && limitDays > 0
        ? sortedEntries.take(limitDays).toList()
        : sortedEntries;

    return limitedEntries.map((entry) {
      final value = switch (type) {
        TrendType.xp => entry.xpGained.toDouble(),
        TrendType.tasks => entry.tasksCompleted.toDouble(),
        TrendType.streak => entry.streakCount.toDouble(),
        TrendType.level => entry.levelAtTime.toDouble(),
      };

      return ChartDataPoint(
        date: entry.date,
        value: value,
        label: entry.dateKey,
      );
    }).toList();
  }
}

/// Summary of progress data for a time period
class ProgressSummary extends Equatable {
  const ProgressSummary({
    required this.periodKey,
    required this.totalXP,
    required this.totalTasks,
    required this.averageXP,
    required this.averageTasks,
    required this.maxStreak,
    required this.maxLevel,
    required this.categoryTotals,
    required this.taskTypeTotals,
    required this.entryCount,
  });

  /// Creates summary from list of progress entries
  factory ProgressSummary.fromEntries(
    List<ProgressEntry> entries,
    String periodKey,
  ) {
    if (entries.isEmpty) {
      return ProgressSummary(
        periodKey: periodKey,
        totalXP: 0,
        totalTasks: 0,
        averageXP: 0,
        averageTasks: 0,
        maxStreak: 0,
        maxLevel: 1,
        categoryTotals: const {},
        taskTypeTotals: const {},
        entryCount: 0,
      );
    }

    final totalXP = entries.fold(0, (sum, entry) => sum + entry.xpGained);
    final totalTasks = entries.fold(
      0,
      (sum, entry) => sum + entry.tasksCompleted,
    );
    final maxStreak = entries.fold(
      0,
      (max, entry) => entry.streakCount > max ? entry.streakCount : max,
    );
    final maxLevel = entries.fold(
      1,
      (max, entry) => entry.levelAtTime > max ? entry.levelAtTime : max,
    );

    // Aggregate category totals
    final categoryTotals = <String, int>{};
    for (final entry in entries) {
      for (final category in entry.categoryBreakdown.keys) {
        categoryTotals[category] =
            (categoryTotals[category] ?? 0) +
            entry.categoryBreakdown[category]!;
      }
    }

    // Aggregate task type totals
    final taskTypeTotals = <String, int>{};
    for (final entry in entries) {
      for (final taskType in entry.taskTypeBreakdown.keys) {
        taskTypeTotals[taskType] =
            (taskTypeTotals[taskType] ?? 0) +
            entry.taskTypeBreakdown[taskType]!;
      }
    }

    return ProgressSummary(
      periodKey: periodKey,
      totalXP: totalXP,
      totalTasks: totalTasks,
      averageXP: totalXP / entries.length,
      averageTasks: totalTasks / entries.length,
      maxStreak: maxStreak,
      maxLevel: maxLevel,
      categoryTotals: categoryTotals,
      taskTypeTotals: taskTypeTotals,
      entryCount: entries.length,
    );
  }
  final String periodKey;
  final int totalXP;
  final int totalTasks;
  final double averageXP;
  final double averageTasks;
  final int maxStreak;
  final int maxLevel;
  final Map<String, int> categoryTotals;
  final Map<String, int> taskTypeTotals;
  final int entryCount;

  @override
  List<Object?> get props => [
    periodKey,
    totalXP,
    totalTasks,
    averageXP,
    averageTasks,
    maxStreak,
    maxLevel,
    categoryTotals,
    taskTypeTotals,
    entryCount,
  ];
}

/// Data point for chart display
class ChartDataPoint extends Equatable {
  const ChartDataPoint({
    required this.date,
    required this.value,
    required this.label,
  });
  final DateTime date;
  final double value;
  final String label;

  @override
  List<Object?> get props => [date, value, label];
}

/// Enum for trend types
enum TrendType { xp, tasks, streak, level }
