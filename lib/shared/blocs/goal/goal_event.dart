import 'package:equatable/equatable.dart';

import '../../../data/models/goal.dart';

/// Base class for all goal events
abstract class GoalEvent extends Equatable {
  const GoalEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load all goals for a user
class LoadGoals extends GoalEvent {
  const LoadGoals(this.userId);

  final String userId;

  @override
  List<Object?> get props => [userId];
}

/// Event to load a specific goal by ID
class LoadGoal extends GoalEvent {
  const LoadGoal(this.goalId);

  final String goalId;

  @override
  List<Object?> get props => [goalId];
}

/// Event to create a new goal
class CreateGoal extends GoalEvent {
  const CreateGoal({
    required this.userId,
    required this.title,
    required this.category,
    required this.deadline,
    this.description = '',
    this.priority = GoalPriority.medium,
    this.startDate,
  });

  final String userId;
  final String title;
  final String description;
  final GoalCategory category;
  final GoalPriority priority;
  final DateTime deadline;
  final DateTime? startDate;

  @override
  List<Object?> get props => [
        userId,
        title,
        description,
        category,
        priority,
        deadline,
        startDate,
      ];
}

/// Event to update an existing goal
class UpdateGoal extends GoalEvent {
  const UpdateGoal(this.goal);

  final Goal goal;

  @override
  List<Object?> get props => [goal];
}

/// Event to update goal progress
class UpdateGoalProgress extends GoalEvent {
  const UpdateGoalProgress(this.goalId, this.progress);

  final String goalId;
  final double progress;

  @override
  List<Object?> get props => [goalId, progress];
}

/// Event to update goal status
class UpdateGoalStatus extends GoalEvent {
  const UpdateGoalStatus(this.goalId, this.status);

  final String goalId;
  final GoalStatus status;

  @override
  List<Object?> get props => [goalId, status];
}

/// Event to delete a goal
class DeleteGoal extends GoalEvent {
  const DeleteGoal(this.goalId, this.userId);

  final String goalId;
  final String userId;

  @override
  List<Object?> get props => [goalId, userId];
}

/// Event to load goals by category
class LoadGoalsByCategory extends GoalEvent {
  const LoadGoalsByCategory(this.userId, this.category);

  final String userId;
  final GoalCategory category;

  @override
  List<Object?> get props => [userId, category];
}

/// Event to load goals by priority
class LoadGoalsByPriority extends GoalEvent {
  const LoadGoalsByPriority(this.userId, this.priority);

  final String userId;
  final GoalPriority priority;

  @override
  List<Object?> get props => [userId, priority];
}

/// Event to load goals by status
class LoadGoalsByStatus extends GoalEvent {
  const LoadGoalsByStatus(this.userId, this.status);

  final String userId;
  final GoalStatus status;

  @override
  List<Object?> get props => [userId, status];
}

/// Event to load active goals
class LoadActiveGoals extends GoalEvent {
  const LoadActiveGoals(this.userId);

  final String userId;

  @override
  List<Object?> get props => [userId];
}

/// Event to load completed goals
class LoadCompletedGoals extends GoalEvent {
  const LoadCompletedGoals(this.userId);

  final String userId;

  @override
  List<Object?> get props => [userId];
}

/// Event to load overdue goals
class LoadOverdueGoals extends GoalEvent {
  const LoadOverdueGoals(this.userId);

  final String userId;

  @override
  List<Object?> get props => [userId];
}

/// Event to load goals due soon
class LoadGoalsDueSoon extends GoalEvent {
  const LoadGoalsDueSoon(this.userId);

  final String userId;

  @override
  List<Object?> get props => [userId];
}