import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/goal_repository.dart';
import 'goal_event.dart';
import 'goal_state.dart';

/// BLoC for managing goal state and business logic
class GoalBloc extends Bloc<GoalEvent, GoalState> {
  GoalBloc({required GoalRepository goalRepository})
      : _goalRepository = goalRepository,
        super(GoalInitial()) {
    on<LoadGoals>(_onLoadGoals);
    on<LoadGoal>(_onLoadGoal);
    on<CreateGoal>(_onCreateGoal);
    on<UpdateGoal>(_onUpdateGoal);
    on<UpdateGoalProgress>(_onUpdateGoalProgress);
    on<UpdateGoalStatus>(_onUpdateGoalStatus);
    on<DeleteGoal>(_onDeleteGoal);
    on<LoadGoalsByCategory>(_onLoadGoalsByCategory);
    on<LoadGoalsByPriority>(_onLoadGoalsByPriority);
    on<LoadGoalsByStatus>(_onLoadGoalsByStatus);
    on<LoadActiveGoals>(_onLoadActiveGoals);
    on<LoadCompletedGoals>(_onLoadCompletedGoals);
    on<LoadOverdueGoals>(_onLoadOverdueGoals);
    on<LoadGoalsDueSoon>(_onLoadGoalsDueSoon);
  }

  final GoalRepository _goalRepository;

  /// Handles loading all goals for a user
  Future<void> _onLoadGoals(
    LoadGoals event,
    Emitter<GoalState> emit,
  ) async {
    // print('Loading goals for user: ${event.userId}');
    emit(GoalLoading());

    try {
      final goals = await _goalRepository.getGoalsByUserId(event.userId);
      emit(GoalLoaded(goals));
    } catch (e) {
      // print('Error loading goals: $e');
      emit(GoalError('Failed to load goals: $e'));
    }
  }

  /// Handles loading a specific goal by ID
  Future<void> _onLoadGoal(
    LoadGoal event,
    Emitter<GoalState> emit,
  ) async {
    // print('Loading goal: ${event.goalId}');
    emit(GoalLoading());

    try {
      final goal = await _goalRepository.getGoalById(event.goalId);
      if (goal != null) {
        emit(SingleGoalLoaded(goal));
      } else {
        emit(GoalError('Goal not found'));
      }
    } catch (e) {
      // print('Error loading goal: $e');
      emit(GoalError('Failed to load goal: $e'));
    }
  }

  /// Handles creating a new goal
  Future<void> _onCreateGoal(
    CreateGoal event,
    Emitter<GoalState> emit,
  ) async {
    // print('Creating new goal: ${event.title}');
    emit(GoalLoading());

    try {
      await _goalRepository.createGoal(
        userId: event.userId,
        title: event.title,
        description: event.description,
        category: event.category,
        priority: event.priority,
        deadline: event.deadline,
        startDate: event.startDate,
      );

      // Reload all goals to reflect the new one
      final goals = await _goalRepository.getGoalsByUserId(event.userId);
      emit(GoalLoaded(goals));
      emit(GoalOperationSuccess('Goal created successfully'));
    } catch (e) {
      // print('Error creating goal: $e');
      emit(GoalError('Failed to create goal: $e'));
    }
  }

  /// Handles updating an existing goal
  Future<void> _onUpdateGoal(
    UpdateGoal event,
    Emitter<GoalState> emit,
  ) async {
    // print('Updating goal: ${event.goal.id}');
    emit(GoalLoading());

    try {
      final updatedGoal = await _goalRepository.updateGoal(event.goal);
      if (updatedGoal != null) {
        // Reload all goals to reflect the update
        final goals = await _goalRepository.getGoalsByUserId(event.goal.userId);
        emit(GoalLoaded(goals));
        emit(GoalOperationSuccess('Goal updated successfully'));
      } else {
        emit(GoalError('Failed to update goal'));
      }
    } catch (e) {
      // print('Error updating goal: $e');
      emit(GoalError('Failed to update goal: $e'));
    }
  }

  /// Handles updating goal progress
  Future<void> _onUpdateGoalProgress(
    UpdateGoalProgress event,
    Emitter<GoalState> emit,
  ) async {
    // print('Updating goal progress: ${event.goalId} to ${event.progress}');
    emit(GoalLoading());

    try {
      final updatedGoal = await _goalRepository.updateGoalProgress(
        event.goalId,
        event.progress,
      );

      if (updatedGoal != null) {
        // Reload all goals to reflect the update
        final goals = await _goalRepository.getGoalsByUserId(updatedGoal.userId);
        emit(GoalLoaded(goals));
        emit(GoalOperationSuccess('Goal progress updated successfully'));
      } else {
        emit(GoalError('Failed to update goal progress'));
      }
    } catch (e) {
      // print('Error updating goal progress: $e');
      emit(GoalError('Failed to update goal progress: $e'));
    }
  }

  /// Handles updating goal status
  Future<void> _onUpdateGoalStatus(
    UpdateGoalStatus event,
    Emitter<GoalState> emit,
  ) async {
    // print('Updating goal status: ${event.goalId} to ${event.status}');
    emit(GoalLoading());

    try {
      final updatedGoal = await _goalRepository.updateGoalStatus(
        event.goalId,
        event.status,
      );

      if (updatedGoal != null) {
        // Reload all goals to reflect the update
        final goals = await _goalRepository.getGoalsByUserId(updatedGoal.userId);
        emit(GoalLoaded(goals));
        emit(GoalOperationSuccess('Goal status updated successfully'));
      } else {
        emit(GoalError('Failed to update goal status'));
      }
    } catch (e) {
      // print('Error updating goal status: $e');
      emit(GoalError('Failed to update goal status: $e'));
    }
  }

  /// Handles deleting a goal
  Future<void> _onDeleteGoal(
    DeleteGoal event,
    Emitter<GoalState> emit,
  ) async {
    // print('Deleting goal: ${event.goalId}');
    emit(GoalLoading());

    try {
      final success = await _goalRepository.deleteGoal(
        event.goalId,
        event.userId,
      );

      if (success) {
        // Reload all goals to reflect the deletion
        final goals = await _goalRepository.getGoalsByUserId(event.userId);
        emit(GoalLoaded(goals));
        emit(GoalOperationSuccess('Goal deleted successfully'));
      } else {
        emit(GoalError('Failed to delete goal'));
      }
    } catch (e) {
      // print('Error deleting goal: $e');
      emit(GoalError('Failed to delete goal: $e'));
    }
  }

  /// Handles loading goals by category
  Future<void> _onLoadGoalsByCategory(
    LoadGoalsByCategory event,
    Emitter<GoalState> emit,
  ) async {
    // print('Loading goals by category: ${event.category}');
    emit(GoalLoadingWithFilter('category'));

    try {
      final goals = await _goalRepository.getGoalsByCategory(
        event.userId,
        event.category,
      );
      emit(GoalLoadedWithFilter(
        goals,
        'category',
        event.category.name,
      ));
    } catch (e) {
      // print('Error loading goals by category: $e');
      emit(GoalError('Failed to load goals by category: $e'));
    }
  }

  /// Handles loading goals by priority
  Future<void> _onLoadGoalsByPriority(
    LoadGoalsByPriority event,
    Emitter<GoalState> emit,
  ) async {
    // print('Loading goals by priority: ${event.priority}');
    emit(GoalLoadingWithFilter('priority'));

    try {
      final goals = await _goalRepository.getGoalsByPriority(
        event.userId,
        event.priority,
      );
      emit(GoalLoadedWithFilter(
        goals,
        'priority',
        event.priority.name,
      ));
    } catch (e) {
      // print('Error loading goals by priority: $e');
      emit(GoalError('Failed to load goals by priority: $e'));
    }
  }

  /// Handles loading goals by status
  Future<void> _onLoadGoalsByStatus(
    LoadGoalsByStatus event,
    Emitter<GoalState> emit,
  ) async {
    // print('Loading goals by status: ${event.status}');
    emit(GoalLoadingWithFilter('status'));

    try {
      final goals = await _goalRepository.getGoalsByStatus(
        event.userId,
        event.status,
      );
      emit(GoalLoadedWithFilter(
        goals,
        'status',
        event.status.name,
      ));
    } catch (e) {
      // print('Error loading goals by status: $e');
      emit(GoalError('Failed to load goals by status: $e'));
    }
  }

  /// Handles loading active goals
  Future<void> _onLoadActiveGoals(
    LoadActiveGoals event,
    Emitter<GoalState> emit,
  ) async {
    // print('Loading active goals for user: ${event.userId}');
    emit(GoalLoading());

    try {
      final goals = await _goalRepository.getActiveGoals(event.userId);
      emit(GoalLoaded(goals));
    } catch (e) {
      // print('Error loading active goals: $e');
      emit(GoalError('Failed to load active goals: $e'));
    }
  }

  /// Handles loading completed goals
  Future<void> _onLoadCompletedGoals(
    LoadCompletedGoals event,
    Emitter<GoalState> emit,
  ) async {
    // print('Loading completed goals for user: ${event.userId}');
    emit(GoalLoading());

    try {
      final goals = await _goalRepository.getCompletedGoals(event.userId);
      emit(GoalLoaded(goals));
    } catch (e) {
      // print('Error loading completed goals: $e');
      emit(GoalError('Failed to load completed goals: $e'));
    }
  }

  /// Handles loading overdue goals
  Future<void> _onLoadOverdueGoals(
    LoadOverdueGoals event,
    Emitter<GoalState> emit,
  ) async {
    // print('Loading overdue goals for user: ${event.userId}');
    emit(GoalLoading());

    try {
      final goals = await _goalRepository.getOverdueGoals(event.userId);
      emit(GoalLoaded(goals));
    } catch (e) {
      // print('Error loading overdue goals: $e');
      emit(GoalError('Failed to load overdue goals: $e'));
    }
  }

  /// Handles loading goals due soon
  Future<void> _onLoadGoalsDueSoon(
    LoadGoalsDueSoon event,
    Emitter<GoalState> emit,
  ) async {
    // print('Loading goals due soon for user: ${event.userId}');
    emit(GoalLoading());

    try {
      final goals = await _goalRepository.getGoalsDueSoon(event.userId);
      emit(GoalLoaded(goals));
    } catch (e) {
      // print('Error loading goals due soon: $e');
      emit(GoalError('Failed to load goals due soon: $e'));
    }
  }

  @override
  Future<void> close() {
    // Clean up resources if needed
    return super.close();
  }
}