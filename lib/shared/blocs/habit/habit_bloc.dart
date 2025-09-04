import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/habit.dart';
import '../../../data/repositories/habit_repository.dart';
import 'habit_event.dart';
import 'habit_state.dart';

/// BLoC for managing habit lifecycle, completion rewards, and streak maintenance
class HabitBloc extends Bloc<HabitEvent, HabitState> {
  HabitBloc({required HabitRepository habitRepository})
      : _habitRepository = habitRepository,
        super(const HabitInitial()) {
    on<LoadHabits>(_onLoadHabits);
    on<CreateHabit>(_onCreateHabit);
    on<UpdateHabit>(_onUpdateHabit);
    on<CompleteHabit>(_onCompleteHabit);
    on<ResetHabit>(_onResetHabit);
    on<DeleteHabit>(_onDeleteHabit);
    on<FilterHabitsByCategory>(_onFilterHabitsByCategory);
    on<FilterHabitsByFrequency>(_onFilterHabitsByFrequency);
    on<LoadCompletedHabits>(_onLoadCompletedHabits);
    on<LoadPendingHabits>(_onLoadPendingHabits);
    on<UpdateHabitDifficulty>(_onUpdateHabitDifficulty);
    on<UpdateHabitReminder>(_onUpdateHabitReminder);
    on<SortHabits>(_onSortHabits);
    on<SearchHabits>(_onSearchHabits);
    on<RefreshHabits>(_onRefreshHabits);
    on<HabitCompletionAnimationCompleted>(_onHabitCompletionAnimationCompleted);
  }

  final HabitRepository _habitRepository;

  /// Handles loading habits for a user
  Future<void> _onLoadHabits(
    LoadHabits event,
    Emitter<HabitState> emit,
  ) async {
    emit(const HabitLoading());

    try {
      final habits = await _habitRepository.getHabitsByUserId(event.userId);
      emit(HabitLoaded(habits: habits));
    } on Exception catch (e, stackTrace) {
      // Log the actual error for debugging
      developer.log('Failed to load habits for user ${event.userId}',
          name: 'HabitBloc', error: e, stackTrace: stackTrace);

      emit(
        const HabitError(
          message:
              'Unable to load your habits. Please check your connection and try again.',
        ),
      );
    }
  }

  /// Handles creating a new habit
  Future<void> _onCreateHabit(
    CreateHabit event,
    Emitter<HabitState> emit,
  ) async {
    final currentState = state;
    var currentHabits = <Habit>[];

    if (currentState is HabitLoaded) {
      currentHabits = currentState.habits;
      emit(HabitCreating(habits: currentHabits));
    } else {
      emit(const HabitLoading());
    }

    try {
      final newHabit = await _habitRepository.createHabit(
        userId: event.userId,
        title: event.title,
        category: event.category,
        frequency: event.frequency,
        description: event.description,
        difficulty: event.difficulty,
        reminderTime: event.reminderTime,
      );

      final updatedHabits = [...currentHabits, newHabit];
      emit(HabitLoaded(habits: updatedHabits));
    } on Exception catch (e, stackTrace) {
      // Log the actual error for debugging
      developer.log('Failed to create habit', name: 'HabitBloc',
          error: e, stackTrace: stackTrace);

      emit(
        HabitError(
          message: 'Unable to create habit. Please try again.',
          habits: currentHabits,
        ),
      );
    }
  }

  /// Handles updating an existing habit
  Future<void> _onUpdateHabit(
    UpdateHabit event,
    Emitter<HabitState> emit,
  ) async {
    final currentState = state;
    if (currentState is! HabitLoaded) return;

    emit(
      HabitUpdating(
        habits: currentState.habits,
        updateType: HabitUpdateType.update,
        updatingHabitId: event.habit.id,
      ),
    );

    try {
      final updatedHabit = await _habitRepository.updateHabit(
        event.habit,
      );

      if (updatedHabit == null) {
        emit(
          HabitError(
            message: 'Failed to update habit',
            habits: currentState.habits,
            errorType: HabitErrorType.validation,
          ),
        );
        return;
      }

      final updatedHabits = currentState.habits
          .map((habit) => habit.id == updatedHabit.id ? updatedHabit : habit)
          .toList();

      emit(currentState.copyWith(habits: updatedHabits));
    } on Exception catch (e, stackTrace) {
      // Log the actual error for debugging
      developer.log('Failed to update habit', name: 'HabitBloc',
          error: e, stackTrace: stackTrace);

      emit(
        HabitError(
          message: 'Unable to update habit. Please try again.',
          habits: currentState.habits,
        ),
      );
    }
  }

  /// Handles habit completion with XP rewards and streak tracking
  Future<void> _onCompleteHabit(
    CompleteHabit event,
    Emitter<HabitState> emit,
  ) async {
    final currentState = state;
    if (currentState is! HabitLoaded) return;

    // Find the habit being completed
    final habitToComplete = currentState.habits
        .where((habit) => habit.id == event.habitId)
        .firstOrNull;

    if (habitToComplete == null || habitToComplete.isCompletedToday) return;

    // Add habit to completing list for UI feedback
    final completingHabits = [...currentState.completingHabits, event.habitId];
    emit(currentState.copyWith(completingHabits: completingHabits));

    try {
      final completedHabit =
          await _habitRepository.completeHabit(event.habitId);

      if (completedHabit == null) {
        // Remove from completing list on failure
        final updatedCompletingHabits = List<String>.from(currentState.completingHabits)
          ..remove(event.habitId);
        emit(currentState.copyWith(completingHabits: updatedCompletingHabits));
        
        emit(
          HabitError(
            message: 'Failed to complete habit',
            habits: currentState.habits,
          ),
        );
        return;
      }

      // Calculate XP rewards and streak bonuses
      final streakBonus = completedHabit.streakCount > 1
          ? (completedHabit.xpReward * 0.05 * completedHabit.streakCount)
              .round()
          : 0;

      final totalXPReward = completedHabit.xpReward + streakBonus;

      // Update habits list
      final updatedHabits = currentState.habits
          .map((habit) => habit.id == completedHabit.id ? completedHabit : habit)
          .toList();

      // Show completion animation with rewards
      emit(
        currentState.copyWith(
          habits: updatedHabits,
          completingHabits: [event.habitId], // Keep only the completed habit
          showCompletionAnimation: true,
          completedHabitId: event.habitId,
          streakBonuses: {
            ...currentState.streakBonuses,
            event.habitId: streakBonus,
          },
          xpRewards: {
            ...currentState.xpRewards,
            event.habitId: totalXPReward,
          },
        ),
      );
    } on Exception catch (e, stackTrace) {
      // Log the actual error for debugging
      developer.log('Failed to complete habit', name: 'HabitBloc',
          error: e, stackTrace: stackTrace);

      // Remove from completing list
      final updatedCompletingHabits = List<String>.from(currentState.completingHabits)
        ..remove(event.habitId);
      emit(currentState.copyWith(completingHabits: updatedCompletingHabits));

      emit(
        HabitError(
          message: 'Unable to complete habit. Please try again.',
          habits: currentState.habits,
        ),
      );
    }
  }

  /// Handles resetting a habit to incomplete state
  Future<void> _onResetHabit(
    ResetHabit event,
    Emitter<HabitState> emit,
  ) async {
    final currentState = state;
    if (currentState is! HabitLoaded) return;

    emit(
      HabitUpdating(
        habits: currentState.habits,
        updateType: HabitUpdateType.reset,
        updatingHabitId: event.habitId,
      ),
    );

    try {
      final resetHabit = await _habitRepository.resetHabitForNewDay(
        event.habitId,
      );

      if (resetHabit == null) {
        emit(
          HabitError(
            message: 'Failed to reset habit',
            habits: currentState.habits,
          ),
        );
        return;
      }

      final updatedHabits = currentState.habits
          .map((habit) => habit.id == resetHabit.id ? resetHabit : habit)
          .toList();

      emit(currentState.copyWith(habits: updatedHabits));
    } on Exception catch (e, stackTrace) {
      // Log the actual error for debugging
      developer.log('Failed to reset habit', name: 'HabitBloc',
          error: e, stackTrace: stackTrace);

      emit(
        HabitError(
          message: 'Unable to reset habit. Please try again.',
          habits: currentState.habits,
        ),
      );
    }
  }

  /// Handles deleting a habit
  Future<void> _onDeleteHabit(
    DeleteHabit event,
    Emitter<HabitState> emit,
  ) async {
    final currentState = state;
    if (currentState is! HabitLoaded) return;

    emit(
      HabitUpdating(
        habits: currentState.habits,
        updateType: HabitUpdateType.deletion,
        updatingHabitId: event.habitId,
      ),
    );

    try {
      final success = await _habitRepository.deleteHabit(
        event.habitId,
        event.userId,
      );

      if (!success) {
        emit(
          HabitError(
            message: 'Failed to delete habit',
            habits: currentState.habits,
          ),
        );
        return;
      }

      final updatedHabits = currentState.habits
          .where((habit) => habit.id != event.habitId)
          .toList();

      emit(currentState.copyWith(habits: updatedHabits));
    } on Exception catch (e, stackTrace) {
      // Log the actual error for debugging
      developer.log('Failed to delete habit', name: 'HabitBloc',
          error: e, stackTrace: stackTrace);

      emit(
        HabitError(
          message: 'Unable to delete habit. Please try again.',
          habits: currentState.habits,
        ),
      );
    }
  }

  /// Handles filtering habits by category
  Future<void> _onFilterHabitsByCategory(
    FilterHabitsByCategory event,
    Emitter<HabitState> emit,
  ) async {
    final currentState = state;
    if (currentState is! HabitLoaded) return;

    try {
      final filteredHabits = await _habitRepository.getHabitsByCategory(
        event.userId,
        event.category,
      );

      emit(
        currentState.copyWith(
          filteredHabits: filteredHabits,
          activeFilter: HabitFilter(category: event.category),
        ),
      );
    } on Exception catch (e, stackTrace) {
      // Log the actual error for debugging
      developer.log('Failed to filter habits by category', name: 'HabitBloc',
          error: e, stackTrace: stackTrace);

      emit(
        HabitError(
          message: 'Unable to filter habits. Please try again.',
          habits: currentState.habits,
        ),
      );
    }
  }

  /// Handles filtering habits by frequency
  Future<void> _onFilterHabitsByFrequency(
    FilterHabitsByFrequency event,
    Emitter<HabitState> emit,
  ) async {
    final currentState = state;
    if (currentState is! HabitLoaded) return;

    try {
      final filteredHabits = await _habitRepository.getHabitsByFrequency(
        event.userId,
        event.frequency,
      );

      emit(
        currentState.copyWith(
          filteredHabits: filteredHabits,
          activeFilter: HabitFilter(frequency: event.frequency),
        ),
      );
    } on Exception catch (e, stackTrace) {
      // Log the actual error for debugging
      developer.log('Failed to filter habits by frequency', name: 'HabitBloc',
          error: e, stackTrace: stackTrace);

      emit(
        HabitError(
          message: 'Unable to filter habits. Please try again.',
          habits: currentState.habits,
        ),
      );
    }
  }

  /// Handles loading completed habits
  Future<void> _onLoadCompletedHabits(
    LoadCompletedHabits event,
    Emitter<HabitState> emit,
  ) async {
    final currentState = state;
    if (currentState is! HabitLoaded) return;

    try {
      final completedHabits = await _habitRepository.getCompletedHabits(
        event.userId,
      );

      emit(
        currentState.copyWith(
          filteredHabits: completedHabits,
          activeFilter: const HabitFilter(isCompleted: true),
        ),
      );
    } on Exception catch (e, stackTrace) {
      // Log the actual error for debugging
      developer.log('Failed to load completed habits', name: 'HabitBloc',
          error: e, stackTrace: stackTrace);

      emit(
        HabitError(
          message: 'Unable to load completed habits. Please try again.',
          habits: currentState.habits,
        ),
      );
    }
  }

  /// Handles loading pending habits
  Future<void> _onLoadPendingHabits(
    LoadPendingHabits event,
    Emitter<HabitState> emit,
  ) async {
    final currentState = state;
    if (currentState is! HabitLoaded) return;

    try {
      final pendingHabits = await _habitRepository.getPendingHabits(
        event.userId,
      );

      emit(
        currentState.copyWith(
          filteredHabits: pendingHabits,
          activeFilter: const HabitFilter(isCompleted: false),
        ),
      );
    } on Exception catch (e, stackTrace) {
      // Log the actual error for debugging
      developer.log('Failed to load pending habits', name: 'HabitBloc',
          error: e, stackTrace: stackTrace);

      emit(
        HabitError(
          message: 'Unable to load pending habits. Please try again.',
          habits: currentState.habits,
        ),
      );
    }
  }

  /// Handles updating habit difficulty
  Future<void> _onUpdateHabitDifficulty(
    UpdateHabitDifficulty event,
    Emitter<HabitState> emit,
  ) async {
    final currentState = state;
    if (currentState is! HabitLoaded) return;

    emit(
      HabitUpdating(
        habits: currentState.habits,
        updateType: HabitUpdateType.difficultyUpdate,
        updatingHabitId: event.habitId,
      ),
    );

    try {
      final success = await _habitRepository.updateHabitDifficulty(
        event.habitId,
        event.newDifficulty,
      );

      if (!success) {
        emit(
          HabitError(
            message: 'Failed to update habit difficulty',
            habits: currentState.habits,
          ),
        );
        return;
      }

      // Get updated habit
      final updatedHabit = await _habitRepository.getHabitById(event.habitId);
      if (updatedHabit == null) {
        emit(
          HabitError(
            message: 'Failed to retrieve updated habit',
            habits: currentState.habits,
          ),
        );
        return;
      }

      final updatedHabits = currentState.habits
          .map((habit) => habit.id == updatedHabit.id ? updatedHabit : habit)
          .toList();

      emit(currentState.copyWith(habits: updatedHabits));
    } on Exception catch (e, stackTrace) {
      // Log the actual error for debugging
      developer.log('Failed to update habit difficulty', name: 'HabitBloc',
          error: e, stackTrace: stackTrace);

      emit(
        HabitError(
          message: 'Unable to update habit difficulty. Please try again.',
          habits: currentState.habits,
        ),
      );
    }
  }

  /// Handles updating habit reminder time
  Future<void> _onUpdateHabitReminder(
    UpdateHabitReminder event,
    Emitter<HabitState> emit,
  ) async {
    final currentState = state;
    if (currentState is! HabitLoaded) return;

    try {
      final success = await _habitRepository.updateHabitReminder(
        event.habitId,
        event.reminderTime,
      );

      if (!success) {
        emit(
          HabitError(
            message: 'Failed to update habit reminder',
            habits: currentState.habits,
          ),
        );
        return;
      }

      // Get updated habit
      final updatedHabit = await _habitRepository.getHabitById(event.habitId);
      if (updatedHabit == null) {
        emit(
          HabitError(
            message: 'Failed to retrieve updated habit',
            habits: currentState.habits,
          ),
        );
        return;
      }

      final updatedHabits = currentState.habits
          .map((habit) => habit.id == updatedHabit.id ? updatedHabit : habit)
          .toList();

      emit(currentState.copyWith(habits: updatedHabits));
    } on Exception catch (e, stackTrace) {
      // Log the actual error for debugging
      developer.log('Failed to update habit reminder', name: 'HabitBloc',
          error: e, stackTrace: stackTrace);

      emit(
        HabitError(
          message: 'Unable to update habit reminder. Please try again.',
          habits: currentState.habits,
        ),
      );
    }
  }

  /// Handles sorting habits
  Future<void> _onSortHabits(
    SortHabits event,
    Emitter<HabitState> emit,
  ) async {
    final currentState = state;
    if (currentState is! HabitLoaded) return;

    final sortedHabits = List<Habit>.from(currentState.habits);

    switch (event.sortType) {
      case HabitSortType.streakCount:
        sortedHabits.sort((a, b) => b.streakCount.compareTo(a.streakCount));
      case HabitSortType.difficulty:
        sortedHabits.sort((a, b) => b.difficulty.compareTo(a.difficulty));
      case HabitSortType.xpReward:
        sortedHabits.sort((a, b) => b.xpReward.compareTo(a.xpReward));
      case HabitSortType.createdDate:
        sortedHabits.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case HabitSortType.alphabetical:
        sortedHabits.sort((a, b) => a.title.compareTo(b.title));
      case HabitSortType.category:
        sortedHabits.sort((a, b) => a.category.index.compareTo(b.category.index));
      case HabitSortType.frequency:
        sortedHabits.sort((a, b) => a.frequency.index.compareTo(b.frequency.index));
    }

    emit(currentState.copyWith(
      habits: sortedHabits,
      sortType: event.sortType,
    ));
  }

  /// Handles searching habits
  Future<void> _onSearchHabits(
    SearchHabits event,
    Emitter<HabitState> emit,
  ) async {
    final currentState = state;
    if (currentState is! HabitLoaded) return;

    if (event.query.isEmpty) {
      // Clear search
      emit(currentState.copyWith(
        filteredHabits: null,
        searchQuery: '',
      ));
      return;
    }

    final filteredHabits = currentState.habits
        .where((habit) =>
            habit.title.toLowerCase().contains(event.query.toLowerCase()) ||
            habit.description.toLowerCase().contains(event.query.toLowerCase()))
        .toList();

    emit(currentState.copyWith(
      filteredHabits: filteredHabits,
      searchQuery: event.query,
    ));
  }

  /// Handles refreshing habits
  Future<void> _onRefreshHabits(
    RefreshHabits event,
    Emitter<HabitState> emit,
  ) async {
    emit(const HabitLoading());

    try {
      final habits = await _habitRepository.getHabitsByUserId(event.userId);
      emit(HabitLoaded(habits: habits));
    } on Exception catch (e, stackTrace) {
      // Log the actual error for debugging
      developer.log('Failed to refresh habits for user ${event.userId}',
          name: 'HabitBloc', error: e, stackTrace: stackTrace);

      emit(
        const HabitError(
          message:
              'Unable to refresh your habits. Please check your connection and try again.',
        ),
      );
    }
  }

  /// Handles habit completion animation completion
  Future<void> _onHabitCompletionAnimationCompleted(
    HabitCompletionAnimationCompleted event,
    Emitter<HabitState> emit,
  ) async {
    final currentState = state;
    if (currentState is! HabitLoaded) return;

    emit(currentState.clearCompletionAnimation());
  }
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