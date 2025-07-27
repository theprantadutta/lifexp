import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/progress.dart';
import '../../../data/repositories/progress_repository.dart';
import 'progress_event.dart';
import 'progress_state.dart';

/// BLoC for managing progress analytics data, chart updates, and trend analysis
class ProgressBloc extends Bloc<ProgressEvent, ProgressState> {
  ProgressBloc({required ProgressRepository progressRepository})
    : _progressRepository = progressRepository,
      super(const ProgressInitial()) {
    on<LoadProgressEntries>(_onLoadProgressEntries);
    on<LoadProgressEntriesInRange>(_onLoadProgressEntriesInRange);
    on<LoadRecentProgressEntries>(_onLoadRecentProgressEntries);
    on<CreateOrUpdateTodayEntry>(_onCreateOrUpdateTodayEntry);
    on<AddXPToToday>(_onAddXPToToday);
    on<AddTaskToToday>(_onAddTaskToToday);
    on<RecordProgressUpdate>(_onRecordProgressUpdate);
    on<LoadDailyXPTrend>(_onLoadDailyXPTrend);
    on<LoadWeeklyProgressSummary>(_onLoadWeeklyProgressSummary);
    on<LoadMonthlyProgressSummary>(_onLoadMonthlyProgressSummary);
    on<LoadCategoryBreakdown>(_onLoadCategoryBreakdown);
    on<LoadProgressStats>(_onLoadProgressStats);
    on<AggregateProgressByDate>(_onAggregateProgressByDate);
    on<AggregateProgressByWeek>(_onAggregateProgressByWeek);
    on<AggregateProgressByMonth>(_onAggregateProgressByMonth);
    on<CalculateTrend>(_onCalculateTrend);
    on<AnalyzeProgressPatterns>(_onAnalyzeProgressPatterns);
    on<GenerateProgressInsights>(_onGenerateProgressInsights);
    on<PredictFutureProgress>(_onPredictFutureProgress);
    on<GetProgressComparison>(_onGetProgressComparison);
    on<RefreshProgressData>(_onRefreshProgressData);
    on<FilterProgressEntries>(_onFilterProgressEntries);
    on<SortProgressEntries>(_onSortProgressEntries);
    on<ClearProgressFilters>(_onClearProgressFilters);
  }

  final ProgressRepository _progressRepository;

  /// Handles loading progress entries for a user
  Future<void> _onLoadProgressEntries(
    LoadProgressEntries event,
    Emitter<ProgressState> emit,
  ) async {
    emit(const ProgressLoading());

    try {
      final progressEntries = await _progressRepository
          .getProgressEntriesByUserId(event.userId);
      emit(ProgressLoaded(progressEntries: progressEntries));
    } on Exception catch (e) {
      emit(
        ProgressError(
          message: 'Failed to load progress entries: ${e.toString()}',
          errorType: ProgressErrorType.general,
        ),
      );
    }
  }

  /// Handles loading progress entries in a date range
  Future<void> _onLoadProgressEntriesInRange(
    LoadProgressEntriesInRange event,
    Emitter<ProgressState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ProgressLoaded) {
      emit(const ProgressLoading());
    }

    try {
      final progressEntries = await _progressRepository
          .getProgressEntriesInRange(
            event.userId,
            event.startDate,
            event.endDate,
          );

      if (currentState is ProgressLoaded) {
        emit(
          currentState.copyWith(
            filteredEntries: progressEntries,
            activeFilter: ProgressFilter(
              dateRange: DateRange(
                startDate: event.startDate,
                endDate: event.endDate,
              ),
            ),
          ),
        );
      } else {
        emit(ProgressLoaded(progressEntries: progressEntries));
      }
    } on Exception catch (e) {
      emit(
        ProgressError(
          message: 'Failed to load progress entries in range: ${e.toString()}',
          progressEntries: currentState is ProgressLoaded
              ? currentState.progressEntries
              : null,
          errorType: ProgressErrorType.general,
        ),
      );
    }
  }

  /// Handles loading recent progress entries
  Future<void> _onLoadRecentProgressEntries(
    LoadRecentProgressEntries event,
    Emitter<ProgressState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ProgressLoaded) {
      emit(const ProgressLoading());
    }

    try {
      final progressEntries = await _progressRepository
          .getRecentProgressEntries(event.userId, days: event.days);

      if (currentState is ProgressLoaded) {
        emit(currentState.copyWith(progressEntries: progressEntries));
      } else {
        emit(ProgressLoaded(progressEntries: progressEntries));
      }
    } on Exception catch (e) {
      emit(
        ProgressError(
          message: 'Failed to load recent progress entries: ${e.toString()}',
          progressEntries: currentState is ProgressLoaded
              ? currentState.progressEntries
              : null,
          errorType: ProgressErrorType.general,
        ),
      );
    }
  }

  /// Handles creating or updating today's progress entry
  Future<void> _onCreateOrUpdateTodayEntry(
    CreateOrUpdateTodayEntry event,
    Emitter<ProgressState> emit,
  ) async {
    final currentState = state;
    if (currentState is ProgressLoaded) {
      emit(
        ProgressUpdating(
          progressEntries: currentState.progressEntries,
          updateType: ProgressUpdateType.comprehensiveUpdate,
        ),
      );
    }

    try {
      final updatedEntry = await _progressRepository.createOrUpdateTodayEntry(
        event.userId,
        event.xpGain,
        event.tasksCompleted,
        category: event.category,
        categoryBreakdown: event.categoryBreakdown,
        taskTypeBreakdown: event.taskTypeBreakdown,
        streakCount: event.streakCount,
        levelAtTime: event.levelAtTime,
      );

      // Update the progress entries list
      List<ProgressEntry> updatedEntries;
      if (currentState is ProgressLoaded) {
        updatedEntries =
            currentState.progressEntries
                .where((entry) => entry.dateKey != updatedEntry.dateKey)
                .toList()
              ..add(updatedEntry);
      } else {
        updatedEntries = [updatedEntry];
      }

      emit(
        ProgressLoaded(
          progressEntries: updatedEntries,
          filteredEntries: currentState is ProgressLoaded
              ? currentState.filteredEntries
              : null,
          activeFilter: currentState is ProgressLoaded
              ? currentState.activeFilter
              : null,
          sortType: currentState is ProgressLoaded
              ? currentState.sortType
              : ProgressSortType.date,
        ),
      );
    } on Exception catch (e) {
      emit(
        ProgressError(
          message: 'Failed to create or update today\'s entry: ${e.toString()}',
          progressEntries: currentState is ProgressLoaded
              ? currentState.progressEntries
              : null,
          errorType: ProgressErrorType.general,
        ),
      );
    }
  }

  /// Handles adding XP to today's progress
  Future<void> _onAddXPToToday(
    AddXPToToday event,
    Emitter<ProgressState> emit,
  ) async {
    final currentState = state;
    if (currentState is ProgressLoaded) {
      emit(
        ProgressUpdating(
          progressEntries: currentState.progressEntries,
          updateType: ProgressUpdateType.xpUpdate,
        ),
      );
    }

    try {
      final updatedEntry = await _progressRepository.addXPToToday(
        event.userId,
        event.xpGain,
        category: event.category,
      );

      // Update the progress entries list
      List<ProgressEntry> updatedEntries;
      if (currentState is ProgressLoaded) {
        updatedEntries =
            currentState.progressEntries
                .where((entry) => entry.dateKey != updatedEntry.dateKey)
                .toList()
              ..add(updatedEntry);
      } else {
        updatedEntries = [updatedEntry];
      }

      emit(
        ProgressLoaded(
          progressEntries: updatedEntries,
          filteredEntries: currentState is ProgressLoaded
              ? currentState.filteredEntries
              : null,
          activeFilter: currentState is ProgressLoaded
              ? currentState.activeFilter
              : null,
          sortType: currentState is ProgressLoaded
              ? currentState.sortType
              : ProgressSortType.date,
        ),
      );
    } on Exception catch (e) {
      emit(
        ProgressError(
          message: 'Failed to add XP to today: ${e.toString()}',
          progressEntries: currentState is ProgressLoaded
              ? currentState.progressEntries
              : null,
          errorType: ProgressErrorType.general,
        ),
      );
    }
  }

  /// Handles adding completed task to today's progress
  Future<void> _onAddTaskToToday(
    AddTaskToToday event,
    Emitter<ProgressState> emit,
  ) async {
    final currentState = state;
    if (currentState is ProgressLoaded) {
      emit(
        ProgressUpdating(
          progressEntries: currentState.progressEntries,
          updateType: ProgressUpdateType.taskUpdate,
        ),
      );
    }

    try {
      final updatedEntry = await _progressRepository.addTaskToToday(
        event.userId,
        taskType: event.taskType,
      );

      // Update the progress entries list
      List<ProgressEntry> updatedEntries;
      if (currentState is ProgressLoaded) {
        updatedEntries =
            currentState.progressEntries
                .where((entry) => entry.dateKey != updatedEntry.dateKey)
                .toList()
              ..add(updatedEntry);
      } else {
        updatedEntries = [updatedEntry];
      }

      emit(
        ProgressLoaded(
          progressEntries: updatedEntries,
          filteredEntries: currentState is ProgressLoaded
              ? currentState.filteredEntries
              : null,
          activeFilter: currentState is ProgressLoaded
              ? currentState.activeFilter
              : null,
          sortType: currentState is ProgressLoaded
              ? currentState.sortType
              : ProgressSortType.date,
        ),
      );
    } on Exception catch (e) {
      emit(
        ProgressError(
          message: 'Failed to add task to today: ${e.toString()}',
          progressEntries: currentState is ProgressLoaded
              ? currentState.progressEntries
              : null,
          errorType: ProgressErrorType.general,
        ),
      );
    }
  }

  /// Handles recording comprehensive progress update
  Future<void> _onRecordProgressUpdate(
    RecordProgressUpdate event,
    Emitter<ProgressState> emit,
  ) async {
    final currentState = state;
    if (currentState is ProgressLoaded) {
      emit(
        ProgressUpdating(
          progressEntries: currentState.progressEntries,
          updateType: ProgressUpdateType.comprehensiveUpdate,
        ),
      );
    }

    try {
      final updatedEntry = await _progressRepository.recordProgressUpdate(
        userId: event.userId,
        xpGain: event.xpGain,
        tasksCompleted: event.tasksCompleted,
        streakCount: event.streakCount,
        currentLevel: event.currentLevel,
        category: event.category,
        categoryBreakdown: event.categoryBreakdown,
        taskTypeBreakdown: event.taskTypeBreakdown,
        additionalMetrics: event.additionalMetrics,
      );

      // Update the progress entries list
      List<ProgressEntry> updatedEntries;
      if (currentState is ProgressLoaded) {
        updatedEntries =
            currentState.progressEntries
                .where((entry) => entry.dateKey != updatedEntry.dateKey)
                .toList()
              ..add(updatedEntry);
      } else {
        updatedEntries = [updatedEntry];
      }

      emit(
        ProgressLoaded(
          progressEntries: updatedEntries,
          filteredEntries: currentState is ProgressLoaded
              ? currentState.filteredEntries
              : null,
          activeFilter: currentState is ProgressLoaded
              ? currentState.activeFilter
              : null,
          sortType: currentState is ProgressLoaded
              ? currentState.sortType
              : ProgressSortType.date,
        ),
      );
    } on Exception catch (e) {
      emit(
        ProgressError(
          message: 'Failed to record progress update: ${e.toString()}',
          progressEntries: currentState is ProgressLoaded
              ? currentState.progressEntries
              : null,
          errorType: ProgressErrorType.general,
        ),
      );
    }
  }

  /// Handles loading daily XP trend data
  Future<void> _onLoadDailyXPTrend(
    LoadDailyXPTrend event,
    Emitter<ProgressState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ProgressLoaded) return;

    try {
      final dailyXPTrend = await _progressRepository.getDailyXPTrend(
        event.userId,
        days: event.days,
      );

      emit(currentState.copyWith(dailyXPTrend: dailyXPTrend));
    } on Exception catch (e) {
      emit(
        ProgressError(
          message: 'Failed to load daily XP trend: ${e.toString()}',
          progressEntries: currentState.progressEntries,
          errorType: ProgressErrorType.analysis,
        ),
      );
    }
  }

  /// Handles loading weekly progress summary
  Future<void> _onLoadWeeklyProgressSummary(
    LoadWeeklyProgressSummary event,
    Emitter<ProgressState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ProgressLoaded) return;

    try {
      final weeklyProgressSummary = await _progressRepository
          .getWeeklyProgressSummary(event.userId, weeks: event.weeks);

      emit(currentState.copyWith(weeklyProgressSummary: weeklyProgressSummary));
    } on Exception catch (e) {
      emit(
        ProgressError(
          message: 'Failed to load weekly progress summary: ${e.toString()}',
          progressEntries: currentState.progressEntries,
          errorType: ProgressErrorType.analysis,
        ),
      );
    }
  }

  /// Handles loading monthly progress summary
  Future<void> _onLoadMonthlyProgressSummary(
    LoadMonthlyProgressSummary event,
    Emitter<ProgressState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ProgressLoaded) return;

    try {
      final monthlyProgressSummary = await _progressRepository
          .getMonthlyProgressSummary(event.userId, months: event.months);

      emit(
        currentState.copyWith(monthlyProgressSummary: monthlyProgressSummary),
      );
    } on Exception catch (e) {
      emit(
        ProgressError(
          message: 'Failed to load monthly progress summary: ${e.toString()}',
          progressEntries: currentState.progressEntries,
          errorType: ProgressErrorType.analysis,
        ),
      );
    }
  }

  /// Handles loading category breakdown
  Future<void> _onLoadCategoryBreakdown(
    LoadCategoryBreakdown event,
    Emitter<ProgressState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ProgressLoaded) return;

    try {
      final categoryBreakdown = await _progressRepository.getCategoryBreakdown(
        event.userId,
        event.startDate,
        event.endDate,
      );

      emit(currentState.copyWith(categoryBreakdown: categoryBreakdown));
    } on Exception catch (e) {
      emit(
        ProgressError(
          message: 'Failed to load category breakdown: ${e.toString()}',
          progressEntries: currentState.progressEntries,
          errorType: ProgressErrorType.analysis,
        ),
      );
    }
  }

  /// Handles loading progress statistics
  Future<void> _onLoadProgressStats(
    LoadProgressStats event,
    Emitter<ProgressState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ProgressLoaded) return;

    try {
      final progressStats = await _progressRepository.getProgressStats(
        event.userId,
      );

      emit(currentState.copyWith(progressStats: progressStats));
    } on Exception catch (e) {
      emit(
        ProgressError(
          message: 'Failed to load progress stats: ${e.toString()}',
          progressEntries: currentState.progressEntries,
          errorType: ProgressErrorType.analysis,
        ),
      );
    }
  }

  /// Handles aggregating progress by date
  Future<void> _onAggregateProgressByDate(
    AggregateProgressByDate event,
    Emitter<ProgressState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ProgressLoaded) return;

    emit(
      ProgressAnalyzing(
        progressEntries: currentState.progressEntries,
        analysisType: ProgressAnalysisType.trends,
      ),
    );

    try {
      final aggregatedData = await _progressRepository.aggregateProgressByDate(
        event.userId,
        event.startDate,
        event.endDate,
      );

      emit(currentState.copyWith(aggregatedData: {'by_date': aggregatedData}));
    } on Exception catch (e) {
      emit(
        ProgressError(
          message: 'Failed to aggregate progress by date: ${e.toString()}',
          progressEntries: currentState.progressEntries,
          errorType: ProgressErrorType.analysis,
        ),
      );
    }
  }

  /// Handles aggregating progress by week
  Future<void> _onAggregateProgressByWeek(
    AggregateProgressByWeek event,
    Emitter<ProgressState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ProgressLoaded) return;

    emit(
      ProgressAnalyzing(
        progressEntries: currentState.progressEntries,
        analysisType: ProgressAnalysisType.trends,
      ),
    );

    try {
      final aggregatedData = await _progressRepository.aggregateProgressByWeek(
        event.userId,
        event.startDate,
        event.endDate,
      );

      emit(currentState.copyWith(aggregatedData: {'by_week': aggregatedData}));
    } on Exception catch (e) {
      emit(
        ProgressError(
          message: 'Failed to aggregate progress by week: ${e.toString()}',
          progressEntries: currentState.progressEntries,
          errorType: ProgressErrorType.analysis,
        ),
      );
    }
  }

  /// Handles aggregating progress by month
  Future<void> _onAggregateProgressByMonth(
    AggregateProgressByMonth event,
    Emitter<ProgressState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ProgressLoaded) return;

    emit(
      ProgressAnalyzing(
        progressEntries: currentState.progressEntries,
        analysisType: ProgressAnalysisType.trends,
      ),
    );

    try {
      final aggregatedData = await _progressRepository.aggregateProgressByMonth(
        event.userId,
        event.startDate,
        event.endDate,
      );

      emit(currentState.copyWith(aggregatedData: {'by_month': aggregatedData}));
    } on Exception catch (e) {
      emit(
        ProgressError(
          message: 'Failed to aggregate progress by month: ${e.toString()}',
          progressEntries: currentState.progressEntries,
          errorType: ProgressErrorType.analysis,
        ),
      );
    }
  }

  /// Handles calculating trend data
  Future<void> _onCalculateTrend(
    CalculateTrend event,
    Emitter<ProgressState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ProgressLoaded) return;

    emit(
      ProgressAnalyzing(
        progressEntries: currentState.progressEntries,
        analysisType: ProgressAnalysisType.trends,
      ),
    );

    try {
      final trendData = await _progressRepository.calculateTrend(
        event.userId,
        event.type,
        limitDays: event.limitDays,
      );

      emit(currentState.copyWith(trendData: trendData));
    } on Exception catch (e) {
      emit(
        ProgressError(
          message: 'Failed to calculate trend: ${e.toString()}',
          progressEntries: currentState.progressEntries,
          errorType: ProgressErrorType.analysis,
        ),
      );
    }
  }

  /// Handles analyzing progress patterns
  Future<void> _onAnalyzeProgressPatterns(
    AnalyzeProgressPatterns event,
    Emitter<ProgressState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ProgressLoaded) return;

    emit(
      ProgressAnalyzing(
        progressEntries: currentState.progressEntries,
        analysisType: ProgressAnalysisType.patterns,
      ),
    );

    try {
      final analysisData = await _progressRepository.analyzeProgressPatterns(
        event.userId,
      );

      emit(currentState.copyWith(analysisData: analysisData));
    } on Exception catch (e) {
      emit(
        ProgressError(
          message: 'Failed to analyze progress patterns: ${e.toString()}',
          progressEntries: currentState.progressEntries,
          errorType: ProgressErrorType.analysis,
        ),
      );
    }
  }

  /// Handles generating progress insights
  Future<void> _onGenerateProgressInsights(
    GenerateProgressInsights event,
    Emitter<ProgressState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ProgressLoaded) return;

    emit(
      ProgressAnalyzing(
        progressEntries: currentState.progressEntries,
        analysisType: ProgressAnalysisType.insights,
      ),
    );

    try {
      final insights = await _progressRepository.generateProgressInsights(
        event.userId,
      );

      emit(currentState.copyWith(insights: insights));
    } on Exception catch (e) {
      emit(
        ProgressError(
          message: 'Failed to generate progress insights: ${e.toString()}',
          progressEntries: currentState.progressEntries,
          errorType: ProgressErrorType.analysis,
        ),
      );
    }
  }

  /// Handles predicting future progress
  Future<void> _onPredictFutureProgress(
    PredictFutureProgress event,
    Emitter<ProgressState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ProgressLoaded) return;

    emit(
      ProgressAnalyzing(
        progressEntries: currentState.progressEntries,
        analysisType: ProgressAnalysisType.predictions,
      ),
    );

    try {
      final predictions = await _progressRepository.predictFutureProgress(
        event.userId,
        daysAhead: event.daysAhead,
      );

      emit(currentState.copyWith(predictions: predictions));
    } on Exception catch (e) {
      emit(
        ProgressError(
          message: 'Failed to predict future progress: ${e.toString()}',
          progressEntries: currentState.progressEntries,
          errorType: ProgressErrorType.analysis,
        ),
      );
    }
  }

  /// Handles getting progress comparison
  Future<void> _onGetProgressComparison(
    GetProgressComparison event,
    Emitter<ProgressState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ProgressLoaded) return;

    emit(
      ProgressAnalyzing(
        progressEntries: currentState.progressEntries,
        analysisType: ProgressAnalysisType.comparison,
      ),
    );

    try {
      final comparison = await _progressRepository.getProgressComparison(
        event.userId,
        days: event.days,
      );

      emit(currentState.copyWith(comparison: comparison));
    } on Exception catch (e) {
      emit(
        ProgressError(
          message: 'Failed to get progress comparison: ${e.toString()}',
          progressEntries: currentState.progressEntries,
          errorType: ProgressErrorType.analysis,
        ),
      );
    }
  }

  /// Handles refreshing progress data
  Future<void> _onRefreshProgressData(
    RefreshProgressData event,
    Emitter<ProgressState> emit,
  ) async {
    try {
      final progressEntries = await _progressRepository
          .getProgressEntriesByUserId(event.userId);

      final currentState = state;
      if (currentState is ProgressLoaded) {
        emit(currentState.copyWith(progressEntries: progressEntries));
      } else {
        emit(ProgressLoaded(progressEntries: progressEntries));
      }
    } on Exception catch (e) {
      emit(
        ProgressError(
          message: 'Failed to refresh progress data: ${e.toString()}',
          errorType: ProgressErrorType.general,
        ),
      );
    }
  }

  /// Handles filtering progress entries
  Future<void> _onFilterProgressEntries(
    FilterProgressEntries event,
    Emitter<ProgressState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ProgressLoaded) return;

    final filteredEntries = currentState.progressEntries
        .where((entry) => event.filter.matches(entry))
        .toList();

    emit(
      currentState.copyWith(
        filteredEntries: filteredEntries,
        activeFilter: event.filter,
      ),
    );
  }

  /// Handles sorting progress entries
  Future<void> _onSortProgressEntries(
    SortProgressEntries event,
    Emitter<ProgressState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ProgressLoaded) return;

    final sortedEntries = _sortProgressEntries(
      currentState.displayEntries,
      event.sortType,
    );

    if (currentState.filteredEntries != null) {
      emit(
        currentState.copyWith(
          filteredEntries: sortedEntries,
          sortType: event.sortType,
        ),
      );
    } else {
      emit(
        currentState.copyWith(
          progressEntries: sortedEntries,
          sortType: event.sortType,
        ),
      );
    }
  }

  /// Handles clearing progress filters
  Future<void> _onClearProgressFilters(
    ClearProgressFilters event,
    Emitter<ProgressState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ProgressLoaded) return;

    emit(currentState.clearFilters());
  }

  // Private helper methods

  /// Sorts progress entries based on the specified sort type
  List<ProgressEntry> _sortProgressEntries(
    List<ProgressEntry> entries,
    ProgressSortType sortType,
  ) {
    final sortedEntries = List<ProgressEntry>.from(entries);

    switch (sortType) {
      case ProgressSortType.date:
        sortedEntries.sort((a, b) => b.date.compareTo(a.date));
        break;

      case ProgressSortType.xpGained:
        sortedEntries.sort((a, b) => b.xpGained.compareTo(a.xpGained));
        break;

      case ProgressSortType.tasksCompleted:
        sortedEntries.sort(
          (a, b) => b.tasksCompleted.compareTo(a.tasksCompleted),
        );
        break;

      case ProgressSortType.streakCount:
        sortedEntries.sort((a, b) => b.streakCount.compareTo(a.streakCount));
        break;

      case ProgressSortType.levelAtTime:
        sortedEntries.sort((a, b) => b.levelAtTime.compareTo(a.levelAtTime));
        break;

      case ProgressSortType.category:
        sortedEntries.sort(
          (a, b) => (a.category ?? '').compareTo(b.category ?? ''),
        );
        break;
    }

    return sortedEntries;
  }

  @override
  Future<void> close() {
    _progressRepository.dispose();
    return super.close();
  }
}
