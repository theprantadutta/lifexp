import 'package:equatable/equatable.dart';

import '../../../data/models/task.dart';
import 'task_event.dart';

/// Base class for all task states
abstract class TaskState extends Equatable {
  const TaskState();

  @override
  List<Object?> get props => [];
}

/// Initial state when no tasks are loaded
class TaskInitial extends TaskState {
  const TaskInitial();
}

/// State when tasks are being loaded
class TaskLoading extends TaskState {
  const TaskLoading();
}

/// State when tasks are successfully loaded
class TaskLoaded extends TaskState {
  const TaskLoaded({
    required this.tasks,
    this.filteredTasks,
    this.activeFilter,
    this.sortType = TaskSortType.dueDate,
    this.searchQuery = '',
    this.completingTasks = const [],
    this.showCompletionAnimation = false,
    this.completedTaskId,
    this.streakBonuses = const {},
    this.xpRewards = const {},
  });

  final List<Task> tasks;
  final List<Task>? filteredTasks;
  final TaskFilter? activeFilter;
  final TaskSortType sortType;
  final String searchQuery;
  final List<String> completingTasks;
  final bool showCompletionAnimation;
  final String? completedTaskId;
  final Map<String, int> streakBonuses; // taskId -> bonus XP
  final Map<String, int> xpRewards; // taskId -> total XP reward

  /// Gets the tasks to display (filtered or all)
  List<Task> get displayTasks => filteredTasks ?? tasks;

  /// Gets pending tasks
  List<Task> get pendingTasks =>
      displayTasks.where((task) => !task.isCompleted).toList();

  /// Gets completed tasks
  List<Task> get completedTasks =>
      displayTasks.where((task) => task.isCompleted).toList();

  /// Gets overdue tasks
  List<Task> get overdueTasks =>
      displayTasks.where((task) => task.isOverdue).toList();

  /// Gets tasks due today
  List<Task> get tasksDueToday =>
      displayTasks.where((task) => task.isDueToday).toList();

  /// Gets tasks with active streaks
  List<Task> get tasksWithStreaks =>
      displayTasks.where((task) => task.streakCount > 0).toList();

  /// Gets tasks by category
  Map<TaskCategory, List<Task>> get tasksByCategory {
    final categorizedTasks = <TaskCategory, List<Task>>{};
    for (final category in TaskCategory.values) {
      categorizedTasks[category] = displayTasks
          .where((task) => task.category == category)
          .toList();
    }
    return categorizedTasks;
  }

  /// Gets tasks by type
  Map<TaskType, List<Task>> get tasksByType {
    final typedTasks = <TaskType, List<Task>>{};
    for (final type in TaskType.values) {
      typedTasks[type] = displayTasks
          .where((task) => task.type == type)
          .toList();
    }
    return typedTasks;
  }

  /// Gets completion statistics
  TaskCompletionStats get completionStats {
    final total = tasks.length;
    final completed = completedTasks.length;
    final pending = pendingTasks.length;
    final overdue = overdueTasks.length;
    final dueToday = tasksDueToday.length;

    return TaskCompletionStats(
      total: total,
      completed: completed,
      pending: pending,
      overdue: overdue,
      dueToday: dueToday,
      completionRate: total > 0 ? completed / total : 0.0,
    );
  }

  @override
  List<Object?> get props => [
    tasks,
    filteredTasks,
    activeFilter,
    sortType,
    searchQuery,
    completingTasks,
    showCompletionAnimation,
    completedTaskId,
    streakBonuses,
    xpRewards,
  ];

  /// Creates a copy with updated fields
  TaskLoaded copyWith({
    List<Task>? tasks,
    List<Task>? filteredTasks,
    TaskFilter? activeFilter,
    TaskSortType? sortType,
    String? searchQuery,
    List<String>? completingTasks,
    bool? showCompletionAnimation,
    String? completedTaskId,
    Map<String, int>? streakBonuses,
    Map<String, int>? xpRewards,
  }) => TaskLoaded(
    tasks: tasks ?? this.tasks,
    filteredTasks: filteredTasks ?? this.filteredTasks,
    activeFilter: activeFilter ?? this.activeFilter,
    sortType: sortType ?? this.sortType,
    searchQuery: searchQuery ?? this.searchQuery,
    completingTasks: completingTasks ?? this.completingTasks,
    showCompletionAnimation:
        showCompletionAnimation ?? this.showCompletionAnimation,
    completedTaskId: completedTaskId ?? this.completedTaskId,
    streakBonuses: streakBonuses ?? this.streakBonuses,
    xpRewards: xpRewards ?? this.xpRewards,
  );

  /// Clears completion animation state
  TaskLoaded clearCompletionAnimation() => copyWith(
    showCompletionAnimation: false,
    completingTasks: const [],
    streakBonuses: const {},
    xpRewards: const {},
  );

  /// Clears filters
  TaskLoaded clearFilters() =>
      copyWith(searchQuery: '');
}

/// State when task operation fails
class TaskError extends TaskState {
  const TaskError({
    required this.message,
    this.tasks,
    this.errorType = TaskErrorType.general,
  });

  final String message;
  final List<Task>? tasks; // Keep current tasks if available
  final TaskErrorType errorType;

  @override
  List<Object?> get props => [message, tasks, errorType];
}

/// State when task is being updated
class TaskUpdating extends TaskState {
  const TaskUpdating({
    required this.tasks,
    required this.updateType,
    this.updatingTaskId,
  });

  final List<Task> tasks;
  final TaskUpdateType updateType;
  final String? updatingTaskId;

  @override
  List<Object?> get props => [tasks, updateType, updatingTaskId];
}

/// State when task is being created
class TaskCreating extends TaskState {
  const TaskCreating({required this.tasks});

  final List<Task> tasks;

  @override
  List<Object?> get props => [tasks];
}

/// Data class for task completion statistics
class TaskCompletionStats extends Equatable {
  const TaskCompletionStats({
    required this.total,
    required this.completed,
    required this.pending,
    required this.overdue,
    required this.dueToday,
    required this.completionRate,
  });

  final int total;
  final int completed;
  final int pending;
  final int overdue;
  final int dueToday;
  final double completionRate;

  @override
  List<Object?> get props => [
    total,
    completed,
    pending,
    overdue,
    dueToday,
    completionRate,
  ];
}

/// Data class for task filters
class TaskFilter extends Equatable {
  const TaskFilter({
    this.category,
    this.type,
    this.isCompleted,
    this.isOverdue,
    this.isDueToday,
    this.hasStreak,
    this.minDifficulty,
    this.maxDifficulty,
  });

  final TaskCategory? category;
  final TaskType? type;
  final bool? isCompleted;
  final bool? isOverdue;
  final bool? isDueToday;
  final bool? hasStreak;
  final int? minDifficulty;
  final int? maxDifficulty;

  @override
  List<Object?> get props => [
    category,
    type,
    isCompleted,
    isOverdue,
    isDueToday,
    hasStreak,
    minDifficulty,
    maxDifficulty,
  ];

  /// Creates a copy with updated fields
  TaskFilter copyWith({
    TaskCategory? category,
    TaskType? type,
    bool? isCompleted,
    bool? isOverdue,
    bool? isDueToday,
    bool? hasStreak,
    int? minDifficulty,
    int? maxDifficulty,
  }) => TaskFilter(
    category: category ?? this.category,
    type: type ?? this.type,
    isCompleted: isCompleted ?? this.isCompleted,
    isOverdue: isOverdue ?? this.isOverdue,
    isDueToday: isDueToday ?? this.isDueToday,
    hasStreak: hasStreak ?? this.hasStreak,
    minDifficulty: minDifficulty ?? this.minDifficulty,
    maxDifficulty: maxDifficulty ?? this.maxDifficulty,
  );

  /// Checks if a task matches this filter
  bool matches(Task task) {
    if (category != null && task.category != category) return false;
    if (type != null && task.type != type) return false;
    if (isCompleted != null && task.isCompleted != isCompleted) return false;
    if (isOverdue != null && task.isOverdue != isOverdue) return false;
    if (isDueToday != null && task.isDueToday != isDueToday) return false;
    if (hasStreak != null && (task.streakCount > 0) != hasStreak) return false;
    if (minDifficulty != null && task.difficulty < minDifficulty!) return false;
    if (maxDifficulty != null && task.difficulty > maxDifficulty!) return false;

    return true;
  }
}

/// Enum for different types of task errors
enum TaskErrorType {
  general,
  network,
  validation,
  notFound,
  unauthorized,
  streakBroken,
}

/// Enum for different types of task updates
enum TaskUpdateType {
  creation,
  completion,
  update,
  deletion,
  difficultyUpdate,
  streakBreak,
  reset,
  batchCompletion,
}
