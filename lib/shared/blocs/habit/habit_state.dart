import 'package:equatable/equatable.dart';

import '../../../data/models/habit.dart';
import 'habit_event.dart';

/// Base class for all habit states
abstract class HabitState extends Equatable {
  const HabitState();

  @override
  List<Object?> get props => [];
}

/// Initial state when no habits are loaded
class HabitInitial extends HabitState {
  const HabitInitial();
}

/// State when habits are being loaded
class HabitLoading extends HabitState {
  const HabitLoading();
}

/// State when habits are successfully loaded
class HabitLoaded extends HabitState {
  const HabitLoaded({
    required this.habits,
    this.filteredHabits,
    this.activeFilter,
    this.sortType = HabitSortType.streakCount,
    this.searchQuery = '',
    this.completingHabits = const [],
    this.showCompletionAnimation = false,
    this.completedHabitId,
    this.streakBonuses = const {},
    this.xpRewards = const {},
  });

  final List<Habit> habits;
  final List<Habit>? filteredHabits;
  final HabitFilter? activeFilter;
  final HabitSortType sortType;
  final String searchQuery;
  final List<String> completingHabits;
  final bool showCompletionAnimation;
  final String? completedHabitId;
  final Map<String, int> streakBonuses; // habitId -> bonus XP
  final Map<String, int> xpRewards; // habitId -> total XP reward

  /// Gets the habits to display (filtered or all)
  List<Habit> get displayHabits => filteredHabits ?? habits;

  /// Gets pending habits
  List<Habit> get pendingHabits =>
      displayHabits.where((habit) => !habit.isCompletedToday).toList();

  /// Gets completed habits
  List<Habit> get completedHabits =>
      displayHabits.where((habit) => habit.isCompletedToday).toList();

  /// Gets habits by category
  Map<HabitCategory, List<Habit>> get habitsByCategory {
    final categorizedHabits = <HabitCategory, List<Habit>>{};
    for (final category in HabitCategory.values) {
      categorizedHabits[category] = displayHabits
          .where((habit) => habit.category == category)
          .toList();
    }
    return categorizedHabits;
  }

  /// Gets habits by frequency
  Map<HabitFrequency, List<Habit>> get habitsByFrequency {
    final frequencyHabits = <HabitFrequency, List<Habit>>{};
    for (final frequency in HabitFrequency.values) {
      frequencyHabits[frequency] = displayHabits
          .where((habit) => habit.frequency == frequency)
          .toList();
    }
    return frequencyHabits;
  }

  /// Gets completion statistics
  HabitCompletionStats get completionStats {
    final total = habits.length;
    final completed = completedHabits.length;
    final pending = pendingHabits.length;

    return HabitCompletionStats(
      total: total,
      completed: completed,
      pending: pending,
      completionRate: total > 0 ? completed / total : 0.0,
    );
  }

  @override
  List<Object?> get props => [
        habits,
        filteredHabits,
        activeFilter,
        sortType,
        searchQuery,
        completingHabits,
        showCompletionAnimation,
        completedHabitId,
        streakBonuses,
        xpRewards,
      ];

  /// Creates a copy with updated fields
  HabitLoaded copyWith({
    List<Habit>? habits,
    List<Habit>? filteredHabits,
    HabitFilter? activeFilter,
    HabitSortType? sortType,
    String? searchQuery,
    List<String>? completingHabits,
    bool? showCompletionAnimation,
    String? completedHabitId,
    Map<String, int>? streakBonuses,
    Map<String, int>? xpRewards,
  }) =>
      HabitLoaded(
        habits: habits ?? this.habits,
        filteredHabits: filteredHabits ?? this.filteredHabits,
        activeFilter: activeFilter ?? this.activeFilter,
        sortType: sortType ?? this.sortType,
        searchQuery: searchQuery ?? this.searchQuery,
        completingHabits: completingHabits ?? this.completingHabits,
        showCompletionAnimation:
            showCompletionAnimation ?? this.showCompletionAnimation,
        completedHabitId: completedHabitId ?? this.completedHabitId,
        streakBonuses: streakBonuses ?? this.streakBonuses,
        xpRewards: xpRewards ?? this.xpRewards,
      );

  /// Clears completion animation state
  HabitLoaded clearCompletionAnimation() => copyWith(
        showCompletionAnimation: false,
        completingHabits: const [],
        streakBonuses: const {},
        xpRewards: const {},
      );

  /// Clears filters
  HabitLoaded clearFilters() => copyWith(searchQuery: '');
}

/// State when habit operation fails
class HabitError extends HabitState {
  const HabitError({
    required this.message,
    this.habits,
    this.errorType = HabitErrorType.general,
  });

  final String message;
  final List<Habit>? habits; // Keep current habits if available
  final HabitErrorType errorType;

  @override
  List<Object?> get props => [message, habits, errorType];
}

/// State when habit is being updated
class HabitUpdating extends HabitState {
  const HabitUpdating({
    required this.habits,
    required this.updateType,
    this.updatingHabitId,
  });

  final List<Habit> habits;
  final HabitUpdateType updateType;
  final String? updatingHabitId;

  @override
  List<Object?> get props => [habits, updateType, updatingHabitId];
}

/// State when habit is being created
class HabitCreating extends HabitState {
  const HabitCreating({required this.habits});

  final List<Habit> habits;

  @override
  List<Object?> get props => [habits];
}

/// Data class for habit completion statistics
class HabitCompletionStats extends Equatable {
  const HabitCompletionStats({
    required this.total,
    required this.completed,
    required this.pending,
    required this.completionRate,
  });

  final int total;
  final int completed;
  final int pending;
  final double completionRate;

  @override
  List<Object?> get props => [
        total,
        completed,
        pending,
        completionRate,
      ];
}

/// Data class for habit filters
class HabitFilter extends Equatable {
  const HabitFilter({
    this.category,
    this.frequency,
    this.isCompleted,
  });

  final HabitCategory? category;
  final HabitFrequency? frequency;
  final bool? isCompleted;

  @override
  List<Object?> get props => [
        category,
        frequency,
        isCompleted,
      ];

  /// Creates a copy with updated fields
  HabitFilter copyWith({
    HabitCategory? category,
    HabitFrequency? frequency,
    bool? isCompleted,
  }) =>
      HabitFilter(
        category: category ?? this.category,
        frequency: frequency ?? this.frequency,
        isCompleted: isCompleted ?? this.isCompleted,
      );

  /// Checks if a habit matches this filter
  bool matches(Habit habit) {
    if (category != null && habit.category != category) return false;
    if (frequency != null && habit.frequency != frequency) return false;
    if (isCompleted != null && habit.isCompletedToday != isCompleted) {
      return false;
    }

    return true;
  }
}

/// Enum for different types of habit errors
enum HabitErrorType {
  general,
  network,
  validation,
  notFound,
  unauthorized,
}

/// Enum for different types of habit updates
enum HabitUpdateType {
  creation,
  completion,
  update,
  deletion,
  difficultyUpdate,
  reset,
}