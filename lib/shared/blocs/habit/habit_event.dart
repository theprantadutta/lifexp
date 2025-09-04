import 'package:equatable/equatable.dart';

import '../../../data/models/habit.dart';

/// Base class for all habit events
abstract class HabitEvent extends Equatable {
  const HabitEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load habits for a user
class LoadHabits extends HabitEvent {
  const LoadHabits({required this.userId});

  final String userId;

  @override
  List<Object?> get props => [userId];
}

/// Event to create a new habit
class CreateHabit extends HabitEvent {
  const CreateHabit({
    required this.userId,
    required this.title,
    required this.category,
    required this.frequency,
    this.description = '',
    this.difficulty,
    this.reminderTime,
  });

  final String userId;
  final String title;
  final HabitCategory category;
  final HabitFrequency frequency;
  final String description;
  final int? difficulty;
  final DateTime? reminderTime;

  @override
  List<Object?> get props => [
        userId,
        title,
        category,
        frequency,
        description,
        difficulty,
        reminderTime,
      ];
}

/// Event to update an existing habit
class UpdateHabit extends HabitEvent {
  const UpdateHabit({required this.habit, required this.userId});

  final Habit habit;
  final String userId;

  @override
  List<Object?> get props => [habit, userId];
}

/// Event to complete a habit
class CompleteHabit extends HabitEvent {
  const CompleteHabit({required this.habitId});

  final String habitId;

  @override
  List<Object?> get props => [habitId];
}

/// Event to reset a habit to incomplete state
class ResetHabit extends HabitEvent {
  const ResetHabit({required this.habitId});

  final String habitId;

  @override
  List<Object?> get props => [habitId];
}

/// Event to delete a habit
class DeleteHabit extends HabitEvent {
  const DeleteHabit({required this.habitId, required this.userId});

  final String habitId;
  final String userId;

  @override
  List<Object?> get props => [habitId, userId];
}

/// Event to filter habits by category
class FilterHabitsByCategory extends HabitEvent {
  const FilterHabitsByCategory({required this.userId, required this.category});

  final String userId;
  final HabitCategory category;

  @override
  List<Object?> get props => [userId, category];
}

/// Event to filter habits by frequency
class FilterHabitsByFrequency extends HabitEvent {
  const FilterHabitsByFrequency({required this.userId, required this.frequency});

  final String userId;
  final HabitFrequency frequency;

  @override
  List<Object?> get props => [userId, frequency];
}

/// Event to get completed habits
class LoadCompletedHabits extends HabitEvent {
  const LoadCompletedHabits({required this.userId});

  final String userId;

  @override
  List<Object?> get props => [userId];
}

/// Event to get pending habits
class LoadPendingHabits extends HabitEvent {
  const LoadPendingHabits({required this.userId});

  final String userId;

  @override
  List<Object?> get props => [userId];
}

/// Event to update habit difficulty
class UpdateHabitDifficulty extends HabitEvent {
  const UpdateHabitDifficulty({
    required this.habitId,
    required this.newDifficulty,
  });

  final String habitId;
  final int newDifficulty;

  @override
  List<Object?> get props => [habitId, newDifficulty];
}

/// Event to update habit reminder time
class UpdateHabitReminder extends HabitEvent {
  const UpdateHabitReminder({
    required this.habitId,
    required this.reminderTime,
  });

  final String habitId;
  final DateTime? reminderTime;

  @override
  List<Object?> get props => [habitId, reminderTime];
}

/// Event to sort habits
class SortHabits extends HabitEvent {
  const SortHabits({required this.sortType});

  final HabitSortType sortType;

  @override
  List<Object?> get props => [sortType];
}

/// Event to search habits
class SearchHabits extends HabitEvent {
  const SearchHabits({required this.userId, required this.query});

  final String userId;
  final String query;

  @override
  List<Object?> get props => [userId, query];
}

/// Event to refresh habits
class RefreshHabits extends HabitEvent {
  const RefreshHabits({required this.userId});

  final String userId;

  @override
  List<Object?> get props => [userId];
}

/// Event to handle habit completion animation completion
class HabitCompletionAnimationCompleted extends HabitEvent {
  const HabitCompletionAnimationCompleted({required this.habitId});

  final String habitId;

  @override
  List<Object?> get props => [habitId];
}

/// Enum for habit sorting options
enum HabitSortType {
  streakCount,
  difficulty,
  xpReward,
  createdDate,
  alphabetical,
  category,
  frequency,
}