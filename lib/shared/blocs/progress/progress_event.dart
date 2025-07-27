import 'package:equatable/equatable.dart';

import '../../../data/models/progress.dart';

/// Base class for all progress events
abstract class ProgressEvent extends Equatable {
  const ProgressEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load progress entries for a user
class LoadProgressEntries extends ProgressEvent {
  const LoadProgressEntries({required this.userId});

  final String userId;

  @override
  List<Object?> get props => [userId];
}

/// Event to load progress entries in a date range
class LoadProgressEntriesInRange extends ProgressEvent {
  const LoadProgressEntriesInRange({
    required this.userId,
    required this.startDate,
    required this.endDate,
  });

  final String userId;
  final DateTime startDate;
  final DateTime endDate;

  @override
  List<Object?> get props => [userId, startDate, endDate];
}

/// Event to load recent progress entries
class LoadRecentProgressEntries extends ProgressEvent {
  const LoadRecentProgressEntries({required this.userId, this.days = 30});

  final String userId;
  final int days;

  @override
  List<Object?> get props => [userId, days];
}

/// Event to create or update today's progress entry
class CreateOrUpdateTodayEntry extends ProgressEvent {
  const CreateOrUpdateTodayEntry({
    required this.userId,
    required this.xpGain,
    required this.tasksCompleted,
    this.category,
    this.categoryBreakdown,
    this.taskTypeBreakdown,
    this.streakCount,
    this.levelAtTime,
  });

  final String userId;
  final int xpGain;
  final int tasksCompleted;
  final String? category;
  final Map<String, int>? categoryBreakdown;
  final Map<String, int>? taskTypeBreakdown;
  final int? streakCount;
  final int? levelAtTime;

  @override
  List<Object?> get props => [
    userId,
    xpGain,
    tasksCompleted,
    category,
    categoryBreakdown,
    taskTypeBreakdown,
    streakCount,
    levelAtTime,
  ];
}

/// Event to add XP to today's progress
class AddXPToToday extends ProgressEvent {
  const AddXPToToday({
    required this.userId,
    required this.xpGain,
    this.category,
  });

  final String userId;
  final int xpGain;
  final String? category;

  @override
  List<Object?> get props => [userId, xpGain, category];
}

/// Event to add completed task to today's progress
class AddTaskToToday extends ProgressEvent {
  const AddTaskToToday({required this.userId, this.taskType});

  final String userId;
  final String? taskType;

  @override
  List<Object?> get props => [userId, taskType];
}

/// Event to record comprehensive progress update
class RecordProgressUpdate extends ProgressEvent {
  const RecordProgressUpdate({
    required this.userId,
    required this.xpGain,
    required this.tasksCompleted,
    required this.streakCount,
    required this.currentLevel,
    this.category,
    this.categoryBreakdown,
    this.taskTypeBreakdown,
    this.additionalMetrics,
  });

  final String userId;
  final int xpGain;
  final int tasksCompleted;
  final int streakCount;
  final int currentLevel;
  final String? category;
  final Map<String, int>? categoryBreakdown;
  final Map<String, int>? taskTypeBreakdown;
  final Map<String, dynamic>? additionalMetrics;

  @override
  List<Object?> get props => [
    userId,
    xpGain,
    tasksCompleted,
    streakCount,
    currentLevel,
    category,
    categoryBreakdown,
    taskTypeBreakdown,
    additionalMetrics,
  ];
}

/// Event to load daily XP trend data
class LoadDailyXPTrend extends ProgressEvent {
  const LoadDailyXPTrend({required this.userId, this.days = 30});

  final String userId;
  final int days;

  @override
  List<Object?> get props => [userId, days];
}

/// Event to load weekly progress summary
class LoadWeeklyProgressSummary extends ProgressEvent {
  const LoadWeeklyProgressSummary({required this.userId, this.weeks = 12});

  final String userId;
  final int weeks;

  @override
  List<Object?> get props => [userId, weeks];
}

/// Event to load monthly progress summary
class LoadMonthlyProgressSummary extends ProgressEvent {
  const LoadMonthlyProgressSummary({required this.userId, this.months = 12});

  final String userId;
  final int months;

  @override
  List<Object?> get props => [userId, months];
}

/// Event to load category breakdown
class LoadCategoryBreakdown extends ProgressEvent {
  const LoadCategoryBreakdown({
    required this.userId,
    required this.startDate,
    required this.endDate,
  });

  final String userId;
  final DateTime startDate;
  final DateTime endDate;

  @override
  List<Object?> get props => [userId, startDate, endDate];
}

/// Event to load progress statistics
class LoadProgressStats extends ProgressEvent {
  const LoadProgressStats({required this.userId});

  final String userId;

  @override
  List<Object?> get props => [userId];
}

/// Event to aggregate progress by date
class AggregateProgressByDate extends ProgressEvent {
  const AggregateProgressByDate({
    required this.userId,
    required this.startDate,
    required this.endDate,
  });

  final String userId;
  final DateTime startDate;
  final DateTime endDate;

  @override
  List<Object?> get props => [userId, startDate, endDate];
}

/// Event to aggregate progress by week
class AggregateProgressByWeek extends ProgressEvent {
  const AggregateProgressByWeek({
    required this.userId,
    required this.startDate,
    required this.endDate,
  });

  final String userId;
  final DateTime startDate;
  final DateTime endDate;

  @override
  List<Object?> get props => [userId, startDate, endDate];
}

/// Event to aggregate progress by month
class AggregateProgressByMonth extends ProgressEvent {
  const AggregateProgressByMonth({
    required this.userId,
    required this.startDate,
    required this.endDate,
  });

  final String userId;
  final DateTime startDate;
  final DateTime endDate;

  @override
  List<Object?> get props => [userId, startDate, endDate];
}

/// Event to calculate trend data
class CalculateTrend extends ProgressEvent {
  const CalculateTrend({
    required this.userId,
    required this.type,
    this.limitDays,
  });

  final String userId;
  final TrendType type;
  final int? limitDays;

  @override
  List<Object?> get props => [userId, type, limitDays];
}

/// Event to analyze progress patterns
class AnalyzeProgressPatterns extends ProgressEvent {
  const AnalyzeProgressPatterns({required this.userId});

  final String userId;

  @override
  List<Object?> get props => [userId];
}

/// Event to generate progress insights
class GenerateProgressInsights extends ProgressEvent {
  const GenerateProgressInsights({required this.userId});

  final String userId;

  @override
  List<Object?> get props => [userId];
}

/// Event to predict future progress
class PredictFutureProgress extends ProgressEvent {
  const PredictFutureProgress({required this.userId, this.daysAhead = 30});

  final String userId;
  final int daysAhead;

  @override
  List<Object?> get props => [userId, daysAhead];
}

/// Event to get progress comparison
class GetProgressComparison extends ProgressEvent {
  const GetProgressComparison({required this.userId, this.days = 30});

  final String userId;
  final int days;

  @override
  List<Object?> get props => [userId, days];
}

/// Event to refresh progress data
class RefreshProgressData extends ProgressEvent {
  const RefreshProgressData({required this.userId});

  final String userId;

  @override
  List<Object?> get props => [userId];
}

/// Event to filter progress entries
class FilterProgressEntries extends ProgressEvent {
  const FilterProgressEntries({required this.filter});

  final ProgressFilter filter;

  @override
  List<Object?> get props => [filter];
}

/// Event to sort progress entries
class SortProgressEntries extends ProgressEvent {
  const SortProgressEntries({required this.sortType});

  final ProgressSortType sortType;

  @override
  List<Object?> get props => [sortType];
}

/// Event to clear progress filters
class ClearProgressFilters extends ProgressEvent {
  const ClearProgressFilters({required this.userId});

  final String userId;

  @override
  List<Object?> get props => [userId];
}

/// Data class for progress filters
class ProgressFilter extends Equatable {
  const ProgressFilter({
    this.category,
    this.minXP,
    this.maxXP,
    this.minTasks,
    this.maxTasks,
    this.minStreak,
    this.maxStreak,
    this.dateRange,
  });

  final String? category;
  final int? minXP;
  final int? maxXP;
  final int? minTasks;
  final int? maxTasks;
  final int? minStreak;
  final int? maxStreak;
  final DateRange? dateRange;

  @override
  List<Object?> get props => [
    category,
    minXP,
    maxXP,
    minTasks,
    maxTasks,
    minStreak,
    maxStreak,
    dateRange,
  ];

  /// Creates a copy with updated fields
  ProgressFilter copyWith({
    String? category,
    int? minXP,
    int? maxXP,
    int? minTasks,
    int? maxTasks,
    int? minStreak,
    int? maxStreak,
    DateRange? dateRange,
  }) => ProgressFilter(
    category: category ?? this.category,
    minXP: minXP ?? this.minXP,
    maxXP: maxXP ?? this.maxXP,
    minTasks: minTasks ?? this.minTasks,
    maxTasks: maxTasks ?? this.maxTasks,
    minStreak: minStreak ?? this.minStreak,
    maxStreak: maxStreak ?? this.maxStreak,
    dateRange: dateRange ?? this.dateRange,
  );

  /// Checks if a progress entry matches this filter
  bool matches(ProgressEntry entry) {
    if (category != null && entry.category != category) return false;
    if (minXP != null && entry.xpGained < minXP!) return false;
    if (maxXP != null && entry.xpGained > maxXP!) return false;
    if (minTasks != null && entry.tasksCompleted < minTasks!) return false;
    if (maxTasks != null && entry.tasksCompleted > maxTasks!) return false;
    if (minStreak != null && entry.streakCount < minStreak!) return false;
    if (maxStreak != null && entry.streakCount > maxStreak!) return false;
    if (dateRange != null && !dateRange!.contains(entry.date)) return false;

    return true;
  }
}

/// Data class for date ranges
class DateRange extends Equatable {
  const DateRange({required this.startDate, required this.endDate});

  final DateTime startDate;
  final DateTime endDate;

  /// Checks if a date is within this range
  bool contains(DateTime date) =>
      date.isAfter(startDate.subtract(const Duration(days: 1))) &&
      date.isBefore(endDate.add(const Duration(days: 1)));

  @override
  List<Object?> get props => [startDate, endDate];
}

/// Enum for progress sorting options
enum ProgressSortType {
  date,
  xpGained,
  tasksCompleted,
  streakCount,
  levelAtTime,
  category,
}
