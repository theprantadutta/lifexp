import 'package:equatable/equatable.dart';

import '../../../data/models/progress.dart';
import 'progress_event.dart';

/// Base class for all progress states
abstract class ProgressState extends Equatable {
  const ProgressState();

  @override
  List<Object?> get props => [];
}

/// Initial state when no progress data is loaded
class ProgressInitial extends ProgressState {
  const ProgressInitial();
}

/// State when progress data is being loaded
class ProgressLoading extends ProgressState {
  const ProgressLoading();
}

/// State when progress data is successfully loaded
class ProgressLoaded extends ProgressState {
  const ProgressLoaded({
    required this.progressEntries,
    this.filteredEntries,
    this.activeFilter,
    this.sortType = ProgressSortType.date,
    this.dailyXPTrend = const [],
    this.weeklyProgressSummary = const [],
    this.monthlyProgressSummary = const [],
    this.categoryBreakdown = const [],
    this.progressStats = const {},
    this.aggregatedData = const {},
    this.trendData = const [],
    this.analysisData = const {},
    this.insights = const [],
    this.predictions = const {},
    this.comparison = const {},
  });

  final List<ProgressEntry> progressEntries;
  final List<ProgressEntry>? filteredEntries;
  final ProgressFilter? activeFilter;
  final ProgressSortType sortType;
  final List<Map<String, dynamic>> dailyXPTrend;
  final List<Map<String, dynamic>> weeklyProgressSummary;
  final List<Map<String, dynamic>> monthlyProgressSummary;
  final List<Map<String, dynamic>> categoryBreakdown;
  final Map<String, dynamic> progressStats;
  final Map<String, dynamic> aggregatedData;
  final List<ChartDataPoint> trendData;
  final Map<String, dynamic> analysisData;
  final List<String> insights;
  final Map<String, dynamic> predictions;
  final Map<String, dynamic> comparison;

  /// Gets the progress entries to display (filtered or all)
  List<ProgressEntry> get displayEntries => filteredEntries ?? progressEntries;

  /// Gets today's progress entry
  ProgressEntry? get todayEntry {
    final today = DateTime.now();
    final todayKey =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-'
        '${today.day.toString().padLeft(2, '0')}';

    return displayEntries
        .where((entry) => entry.dateKey == todayKey)
        .firstOrNull;
  }

  /// Gets this week's progress entries
  List<ProgressEntry> get thisWeekEntries {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));

    return displayEntries.where((entry) => entry.date.isAfter(
            startOfWeek.subtract(const Duration(days: 1)),
          ) &&
          entry.date.isBefore(endOfWeek.add(const Duration(days: 1)))).toList();
  }

  /// Gets this month's progress entries
  List<ProgressEntry> get thisMonthEntries {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);

    return displayEntries.where((entry) => entry.date.isAfter(
            startOfMonth.subtract(const Duration(days: 1)),
          ) &&
          entry.date.isBefore(endOfMonth.add(const Duration(days: 1)))).toList();
  }

  /// Gets progress statistics summary
  ProgressStatsSummary get statsSummary {
    if (displayEntries.isEmpty) {
      return const ProgressStatsSummary(
        totalXP: 0,
        totalTasks: 0,
        averageXP: 0,
        averageTasks: 0,
        maxStreak: 0,
        currentStreak: 0,
        productiveDays: 0,
        entryCount: 0,
      );
    }

    final totalXP = displayEntries.fold(
      0,
      (sum, entry) => sum + entry.xpGained,
    );
    final totalTasks = displayEntries.fold(
      0,
      (sum, entry) => sum + entry.tasksCompleted,
    );
    final maxStreak = displayEntries.fold(
      0,
      (max, entry) => entry.streakCount > max ? entry.streakCount : max,
    );
    final currentStreak = todayEntry?.streakCount ?? 0;
    final productiveDays = displayEntries
        .where((entry) => entry.isProductiveDay())
        .length;

    return ProgressStatsSummary(
      totalXP: totalXP,
      totalTasks: totalTasks,
      averageXP: totalXP / displayEntries.length,
      averageTasks: totalTasks / displayEntries.length,
      maxStreak: maxStreak,
      currentStreak: currentStreak,
      productiveDays: productiveDays,
      entryCount: displayEntries.length,
    );
  }

  /// Gets category performance data
  Map<String, CategoryPerformance> get categoryPerformance {
    final categoryData = <String, List<ProgressEntry>>{};

    for (final entry in displayEntries) {
      for (final category in entry.categoryBreakdown.keys) {
        categoryData[category] = (categoryData[category] ?? [])..add(entry);
      }
    }

    return categoryData.map((category, entries) {
      final totalXP = entries.fold(
        0,
        (sum, entry) => sum + entry.getXPForCategory(category),
      );
      final averageXP = entries.isNotEmpty ? totalXP / entries.length : 0.0;
      final bestDay = entries.fold<ProgressEntry?>(null, (best, entry) {
        final entryXP = entry.getXPForCategory(category);
        if (best == null || entryXP > best.getXPForCategory(category)) {
          return entry;
        }
        return best;
      });

      return MapEntry(
        category,
        CategoryPerformance(
          category: category,
          totalXP: totalXP,
          averageXP: averageXP,
          entryCount: entries.length,
          bestDay: bestDay,
        ),
      );
    });
  }

  @override
  List<Object?> get props => [
    progressEntries,
    filteredEntries,
    activeFilter,
    sortType,
    dailyXPTrend,
    weeklyProgressSummary,
    monthlyProgressSummary,
    categoryBreakdown,
    progressStats,
    aggregatedData,
    trendData,
    analysisData,
    insights,
    predictions,
    comparison,
  ];

  /// Creates a copy with updated fields
  ProgressLoaded copyWith({
    List<ProgressEntry>? progressEntries,
    List<ProgressEntry>? filteredEntries,
    ProgressFilter? activeFilter,
    ProgressSortType? sortType,
    List<Map<String, dynamic>>? dailyXPTrend,
    List<Map<String, dynamic>>? weeklyProgressSummary,
    List<Map<String, dynamic>>? monthlyProgressSummary,
    List<Map<String, dynamic>>? categoryBreakdown,
    Map<String, dynamic>? progressStats,
    Map<String, dynamic>? aggregatedData,
    List<ChartDataPoint>? trendData,
    Map<String, dynamic>? analysisData,
    List<String>? insights,
    Map<String, dynamic>? predictions,
    Map<String, dynamic>? comparison,
  }) => ProgressLoaded(
    progressEntries: progressEntries ?? this.progressEntries,
    filteredEntries: filteredEntries ?? this.filteredEntries,
    activeFilter: activeFilter ?? this.activeFilter,
    sortType: sortType ?? this.sortType,
    dailyXPTrend: dailyXPTrend ?? this.dailyXPTrend,
    weeklyProgressSummary: weeklyProgressSummary ?? this.weeklyProgressSummary,
    monthlyProgressSummary:
        monthlyProgressSummary ?? this.monthlyProgressSummary,
    categoryBreakdown: categoryBreakdown ?? this.categoryBreakdown,
    progressStats: progressStats ?? this.progressStats,
    aggregatedData: aggregatedData ?? this.aggregatedData,
    trendData: trendData ?? this.trendData,
    analysisData: analysisData ?? this.analysisData,
    insights: insights ?? this.insights,
    predictions: predictions ?? this.predictions,
    comparison: comparison ?? this.comparison,
  );

  /// Clears filters
  ProgressLoaded clearFilters() =>
      copyWith();
}

/// State when progress operation fails
class ProgressError extends ProgressState {
  const ProgressError({
    required this.message,
    this.progressEntries,
    this.errorType = ProgressErrorType.general,
  });

  final String message;
  final List<ProgressEntry>?
  progressEntries; // Keep current entries if available
  final ProgressErrorType errorType;

  @override
  List<Object?> get props => [message, progressEntries, errorType];
}

/// State when progress is being updated
class ProgressUpdating extends ProgressState {
  const ProgressUpdating({
    required this.progressEntries,
    required this.updateType,
  });

  final List<ProgressEntry> progressEntries;
  final ProgressUpdateType updateType;

  @override
  List<Object?> get props => [progressEntries, updateType];
}

/// State when progress analysis is being performed
class ProgressAnalyzing extends ProgressState {
  const ProgressAnalyzing({
    required this.progressEntries,
    required this.analysisType,
  });

  final List<ProgressEntry> progressEntries;
  final ProgressAnalysisType analysisType;

  @override
  List<Object?> get props => [progressEntries, analysisType];
}

/// Data class for progress statistics summary
class ProgressStatsSummary extends Equatable {
  const ProgressStatsSummary({
    required this.totalXP,
    required this.totalTasks,
    required this.averageXP,
    required this.averageTasks,
    required this.maxStreak,
    required this.currentStreak,
    required this.productiveDays,
    required this.entryCount,
  });

  final int totalXP;
  final int totalTasks;
  final double averageXP;
  final double averageTasks;
  final int maxStreak;
  final int currentStreak;
  final int productiveDays;
  final int entryCount;

  /// Gets productivity rate (productive days / total days)
  double get productivityRate =>
      entryCount > 0 ? productiveDays / entryCount : 0.0;

  /// Gets XP efficiency (XP per task)
  double get xpEfficiency => totalTasks > 0 ? totalXP / totalTasks : 0.0;

  @override
  List<Object?> get props => [
    totalXP,
    totalTasks,
    averageXP,
    averageTasks,
    maxStreak,
    currentStreak,
    productiveDays,
    entryCount,
  ];
}

/// Data class for category performance
class CategoryPerformance extends Equatable {
  const CategoryPerformance({
    required this.category,
    required this.totalXP,
    required this.averageXP,
    required this.entryCount,
    this.bestDay,
  });

  final String category;
  final int totalXP;
  final double averageXP;
  final int entryCount;
  final ProgressEntry? bestDay;

  /// Gets performance rating (0-5 stars)
  int get performanceRating {
    if (averageXP >= 200) return 5;
    if (averageXP >= 150) return 4;
    if (averageXP >= 100) return 3;
    if (averageXP >= 50) return 2;
    if (averageXP > 0) return 1;
    return 0;
  }

  @override
  List<Object?> get props => [
    category,
    totalXP,
    averageXP,
    entryCount,
    bestDay,
  ];
}

/// Enum for different types of progress errors
enum ProgressErrorType {
  general,
  network,
  validation,
  notFound,
  unauthorized,
  analysis,
}

/// Enum for different types of progress updates
enum ProgressUpdateType { creation, xpUpdate, taskUpdate, comprehensiveUpdate }

/// Enum for different types of progress analysis
enum ProgressAnalysisType {
  patterns,
  insights,
  predictions,
  comparison,
  trends,
}

// FirstOrNull extension removed to avoid conflicts with repository extensions
