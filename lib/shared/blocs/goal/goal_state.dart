import 'package:equatable/equatable.dart';

import '../../../data/models/goal.dart';

/// Base class for all goal states
abstract class GoalState extends Equatable {
  const GoalState();

  @override
  List<Object?> get props => [];
}

/// Initial state when the BLoC is created
class GoalInitial extends GoalState {}

/// State when loading goals
class GoalLoading extends GoalState {}

/// State when goals have been successfully loaded
class GoalLoaded extends GoalState {
  const GoalLoaded(this.goals);

  final List<Goal> goals;

  @override
  List<Object?> get props => [goals];
}

/// State when a single goal has been successfully loaded
class SingleGoalLoaded extends GoalState {
  const SingleGoalLoaded(this.goal);

  final Goal goal;

  @override
  List<Object?> get props => [goal];
}

/// State when goals are loading with a specific filter
class GoalLoadingWithFilter extends GoalState {
  const GoalLoadingWithFilter(this.filterType);

  final String filterType; // e.g., 'category', 'priority', 'status'

  @override
  List<Object?> get props => [filterType];
}

/// State when goals have been successfully loaded with a specific filter
class GoalLoadedWithFilter extends GoalState {
  const GoalLoadedWithFilter(this.goals, this.filterType, this.filterValue);

  final List<Goal> goals;
  final String filterType; // e.g., 'category', 'priority', 'status'
  final String filterValue; // e.g., 'health', 'high', 'completed'

  @override
  List<Object?> get props => [goals, filterType, filterValue];
}

/// State when an error occurs
class GoalError extends GoalState {
  const GoalError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

/// State when a goal operation is successful
class GoalOperationSuccess extends GoalState {
  const GoalOperationSuccess(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}