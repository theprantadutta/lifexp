import 'package:equatable/equatable.dart';

import '../../../data/models/task.dart';

/// Base class for all task events
abstract class TaskEvent extends Equatable {
  const TaskEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load tasks for a user
class LoadTasks extends TaskEvent {
  const LoadTasks({required this.userId});

  final String userId;

  @override
  List<Object?> get props => [userId];
}

/// Event to create a new task
class CreateTask extends TaskEvent {
  const CreateTask({
    required this.userId,
    required this.title,
    required this.type,
    required this.category,
    this.description = '',
    this.difficulty,
    this.dueDate,
  });

  final String userId;
  final String title;
  final TaskType type;
  final TaskCategory category;
  final String description;
  final int? difficulty;
  final DateTime? dueDate;

  @override
  List<Object?> get props => [
    userId,
    title,
    type,
    category,
    description,
    difficulty,
    dueDate,
  ];
}

/// Event to update an existing task
class UpdateTask extends TaskEvent {
  const UpdateTask({required this.task, required this.userId});

  final Task task;
  final String userId;

  @override
  List<Object?> get props => [task, userId];
}

/// Event to complete a task
class CompleteTask extends TaskEvent {
  const CompleteTask({required this.taskId, this.completionTime});

  final String taskId;
  final DateTime? completionTime;

  @override
  List<Object?> get props => [taskId, completionTime];
}

/// Event to batch complete multiple tasks
class BatchCompleteTasks extends TaskEvent {
  const BatchCompleteTasks({required this.taskIds});

  final List<String> taskIds;

  @override
  List<Object?> get props => [taskIds];
}

/// Event to reset a task to incomplete state
class ResetTask extends TaskEvent {
  const ResetTask({required this.taskId});

  final String taskId;

  @override
  List<Object?> get props => [taskId];
}

/// Event to delete a task
class DeleteTask extends TaskEvent {
  const DeleteTask({required this.taskId, required this.userId});

  final String taskId;
  final String userId;

  @override
  List<Object?> get props => [taskId, userId];
}

/// Event to filter tasks by category
class FilterTasksByCategory extends TaskEvent {
  const FilterTasksByCategory({required this.userId, required this.category});

  final String userId;
  final TaskCategory category;

  @override
  List<Object?> get props => [userId, category];
}

/// Event to filter tasks by type
class FilterTasksByType extends TaskEvent {
  const FilterTasksByType({required this.userId, required this.type});

  final String userId;
  final TaskType type;

  @override
  List<Object?> get props => [userId, type];
}

/// Event to get completed tasks
class LoadCompletedTasks extends TaskEvent {
  const LoadCompletedTasks({required this.userId});

  final String userId;

  @override
  List<Object?> get props => [userId];
}

/// Event to get pending tasks
class LoadPendingTasks extends TaskEvent {
  const LoadPendingTasks({required this.userId});

  final String userId;

  @override
  List<Object?> get props => [userId];
}

/// Event to get tasks due today
class LoadTasksDueToday extends TaskEvent {
  const LoadTasksDueToday({required this.userId});

  final String userId;

  @override
  List<Object?> get props => [userId];
}

/// Event to get overdue tasks
class LoadOverdueTasks extends TaskEvent {
  const LoadOverdueTasks({required this.userId});

  final String userId;

  @override
  List<Object?> get props => [userId];
}

/// Event to get tasks with active streaks
class LoadTasksWithStreaks extends TaskEvent {
  const LoadTasksWithStreaks({required this.userId});

  final String userId;

  @override
  List<Object?> get props => [userId];
}

/// Event to update task difficulty
class UpdateTaskDifficulty extends TaskEvent {
  const UpdateTaskDifficulty({
    required this.taskId,
    required this.newDifficulty,
  });

  final String taskId;
  final int newDifficulty;

  @override
  List<Object?> get props => [taskId, newDifficulty];
}

/// Event to break task streak
class BreakTaskStreak extends TaskEvent {
  const BreakTaskStreak({required this.taskId});

  final String taskId;

  @override
  List<Object?> get props => [taskId];
}

/// Event to sort tasks
class SortTasks extends TaskEvent {
  const SortTasks({required this.sortType});

  final TaskSortType sortType;

  @override
  List<Object?> get props => [sortType];
}

/// Event to search tasks
class SearchTasks extends TaskEvent {
  const SearchTasks({required this.userId, required this.query});

  final String userId;
  final String query;

  @override
  List<Object?> get props => [userId, query];
}

/// Event to refresh tasks
class RefreshTasks extends TaskEvent {
  const RefreshTasks({required this.userId});

  final String userId;

  @override
  List<Object?> get props => [userId];
}

/// Event to handle task completion animation completion
class TaskCompletionAnimationCompleted extends TaskEvent {
  const TaskCompletionAnimationCompleted({required this.taskId});

  final String taskId;

  @override
  List<Object?> get props => [taskId];
}

/// Event to schedule task reminders
class ScheduleTaskReminders extends TaskEvent {
  const ScheduleTaskReminders({
    required this.task,
    required this.userPreferences,
  });

  final Task task;
  final Map<String, dynamic> userPreferences;

  @override
  List<Object?> get props => [task, userPreferences];
}

/// Event to clear task filters
class ClearTaskFilters extends TaskEvent {
  const ClearTaskFilters({required this.userId});

  final String userId;

  @override
  List<Object?> get props => [userId];
}

/// Enum for task sorting options
enum TaskSortType {
  dueDate,
  difficulty,
  xpReward,
  streakCount,
  createdDate,
  alphabetical,
  category,
  type,
}
