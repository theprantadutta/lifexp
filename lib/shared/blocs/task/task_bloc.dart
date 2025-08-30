import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/task.dart';
import '../../../data/repositories/task_repository.dart';
import 'task_event.dart';
import 'task_state.dart';

/// BLoC for managing task lifecycle, completion rewards, and streak maintenance
class TaskBloc extends Bloc<TaskEvent, TaskState> {
  TaskBloc({required TaskRepository taskRepository})
    : _taskRepository = taskRepository,
      super(const TaskInitial()) {
    on<LoadTasks>(_onLoadTasks);
    on<CreateTask>(_onCreateTask);
    on<UpdateTask>(_onUpdateTask);
    on<CompleteTask>(_onCompleteTask);
    on<BatchCompleteTasks>(_onBatchCompleteTasks);
    on<ResetTask>(_onResetTask);
    on<DeleteTask>(_onDeleteTask);
    on<FilterTasksByCategory>(_onFilterTasksByCategory);
    on<FilterTasksByType>(_onFilterTasksByType);
    on<LoadCompletedTasks>(_onLoadCompletedTasks);
    on<LoadPendingTasks>(_onLoadPendingTasks);
    on<LoadTasksDueToday>(_onLoadTasksDueToday);
    on<LoadOverdueTasks>(_onLoadOverdueTasks);
    on<LoadTasksWithStreaks>(_onLoadTasksWithStreaks);
    on<UpdateTaskDifficulty>(_onUpdateTaskDifficulty);
    on<BreakTaskStreak>(_onBreakTaskStreak);
    on<SortTasks>(_onSortTasks);
    on<SearchTasks>(_onSearchTasks);
    on<RefreshTasks>(_onRefreshTasks);
    on<TaskCompletionAnimationCompleted>(_onTaskCompletionAnimationCompleted);
    on<ScheduleTaskReminders>(_onScheduleTaskReminders);
    on<ClearTaskFilters>(_onClearTaskFilters);
  }

  final TaskRepository _taskRepository;

  /// Handles loading tasks for a user
  Future<void> _onLoadTasks(LoadTasks event, Emitter<TaskState> emit) async {
    emit(const TaskLoading());

    try {
      final tasks = await _taskRepository.getTasksByUserId(event.userId);
      emit(TaskLoaded(tasks: tasks));
    } on Exception catch (e, stackTrace) {
      // Log the actual error for debugging
      developer.log('Failed to load tasks for user ${event.userId}', name: 'TaskBloc', error: e, stackTrace: stackTrace);

      emit(
        const TaskError(
          message:
              'Unable to load your tasks. Please check your connection and try again.',
        ),
      );
    }
  }

  /// Handles creating a new task
  Future<void> _onCreateTask(CreateTask event, Emitter<TaskState> emit) async {
    final currentState = state;
    var currentTasks = <Task>[];

    if (currentState is TaskLoaded) {
      currentTasks = currentState.tasks;
      emit(TaskCreating(tasks: currentTasks));
    } else {
      emit(const TaskLoading());
    }

    try {
      final newTask = await _taskRepository.createTask(
        userId: event.userId,
        title: event.title,
        type: event.type,
        category: event.category,
        description: event.description,
        difficulty: event.difficulty,
        dueDate: event.dueDate,
      );

      final updatedTasks = [...currentTasks, newTask];
      emit(TaskLoaded(tasks: updatedTasks));
    } on Exception catch (e, stackTrace) {
      // Log the actual error for debugging
      developer.log('Failed to create task', name: 'TaskBloc', error: e, stackTrace: stackTrace);

      emit(
        TaskError(
          message: 'Unable to create task. Please try again.',
          tasks: currentTasks,
        ),
      );
    }
  }

  /// Handles updating an existing task
  Future<void> _onUpdateTask(UpdateTask event, Emitter<TaskState> emit) async {
    final currentState = state;
    if (currentState is! TaskLoaded) return;

    emit(
      TaskUpdating(
        tasks: currentState.tasks,
        updateType: TaskUpdateType.update,
        updatingTaskId: event.task.id,
      ),
    );

    try {
      final updatedTask = await _taskRepository.updateTask(
        event.task,
        event.userId,
      );

      if (updatedTask == null) {
        emit(
          TaskError(
            message: 'Failed to update task',
            tasks: currentState.tasks,
            errorType: TaskErrorType.validation,
          ),
        );
        return;
      }

      final updatedTasks = currentState.tasks
          .map((task) => task.id == updatedTask.id ? updatedTask : task)
          .toList();

      emit(currentState.copyWith(tasks: updatedTasks));
    } on Exception catch (e, stackTrace) {
      // Log the actual error for debugging
      developer.log('Failed to update task', name: 'TaskBloc', error: e, stackTrace: stackTrace);

      emit(
        TaskError(
          message: 'Unable to update task. Please try again.',
          tasks: currentState.tasks,
        ),
      );
    }
  }

  /// Handles task completion with XP rewards and streak tracking
  Future<void> _onCompleteTask(
    CompleteTask event,
    Emitter<TaskState> emit,
  ) async {
    final currentState = state;
    if (currentState is! TaskLoaded) return;

    // Find the task being completed
    final taskToComplete = currentState.tasks
        .where((task) => task.id == event.taskId)
        .firstOrNull;

    if (taskToComplete == null || taskToComplete.isCompleted) return;

    // Add task to completing list for UI feedback
    final completingTasks = [...currentState.completingTasks, event.taskId];
    emit(currentState.copyWith(completingTasks: completingTasks));

    try {
      final completedTask = await _taskRepository.completeTask(event.taskId);

      if (completedTask == null) {
        emit(
          TaskError(
            message: 'Failed to complete task',
            tasks: currentState.tasks,
          ),
        );
        return;
      }

      // Calculate XP rewards and streak bonuses
      final streakBonus = _taskRepository.calculateStreakBonus(
        baseXP: completedTask.xpReward,
        streakCount: completedTask.streakCount,
        taskType: completedTask.type,
      );

      final totalXPReward = _taskRepository.calculateDynamicXPReward(
        task: completedTask,
        streakCount: completedTask.streakCount,
        isConsistencyBonus: _isConsistencyBonus(completedTask),
        completionTime: event.completionTime ?? DateTime.now(),
      );

      // Update tasks list
      final updatedTasks = currentState.tasks
          .map((task) => task.id == completedTask.id ? completedTask : task)
          .toList();

      // Show completion animation with rewards
      emit(
        TaskLoaded(
          tasks: updatedTasks,
          filteredTasks: currentState.filteredTasks,
          activeFilter: currentState.activeFilter,
          sortType: currentState.sortType,
          searchQuery: currentState.searchQuery,
          showCompletionAnimation: true,
          completedTaskId: event.taskId,
          streakBonuses: {event.taskId: streakBonus},
          xpRewards: {event.taskId: totalXPReward},
        ),
      );
    } on Exception catch (e, stackTrace) {
      // Log the actual error for debugging
      developer.log('Failed to complete task', name: 'TaskBloc', error: e, stackTrace: stackTrace);

      emit(
        TaskError(
          message: 'Unable to complete task. Please try again.',
          tasks: currentState.tasks,
        ),
      );
    }
  }

  /// Handles batch completion of multiple tasks
  Future<void> _onBatchCompleteTasks(
    BatchCompleteTasks event,
    Emitter<TaskState> emit,
  ) async {
    final currentState = state;
    if (currentState is! TaskLoaded) return;

    emit(
      TaskUpdating(
        tasks: currentState.tasks,
        updateType: TaskUpdateType.batchCompletion,
      ),
    );

    try {
      final completedTasks = await _taskRepository.batchCompleteTasks(
        event.taskIds,
      );

      if (completedTasks.isEmpty) {
        emit(
          TaskError(
            message: 'Failed to complete tasks',
            tasks: currentState.tasks,
          ),
        );
        return;
      }

      // Calculate rewards for all completed tasks
      final streakBonuses = <String, int>{};
      final xpRewards = <String, int>{};

      for (final task in completedTasks) {
        final streakBonus = _taskRepository.calculateStreakBonus(
          baseXP: task.xpReward,
          streakCount: task.streakCount,
          taskType: task.type,
        );

        final totalXPReward = _taskRepository.calculateDynamicXPReward(
          task: task,
          streakCount: task.streakCount,
          isConsistencyBonus: _isConsistencyBonus(task),
          completionTime: DateTime.now(),
        );

        streakBonuses[task.id] = streakBonus;
        xpRewards[task.id] = totalXPReward;
      }

      // Update tasks list
      final updatedTasks = currentState.tasks.map((task) {
        final completedTask = completedTasks
            .where((ct) => ct.id == task.id)
            .firstOrNull;
        return completedTask ?? task;
      }).toList();

      emit(
        TaskLoaded(
          tasks: updatedTasks,
          filteredTasks: currentState.filteredTasks,
          activeFilter: currentState.activeFilter,
          sortType: currentState.sortType,
          searchQuery: currentState.searchQuery,
          showCompletionAnimation: true,
          streakBonuses: streakBonuses,
          xpRewards: xpRewards,
        ),
      );
    } on Exception catch (e) {
      emit(
        TaskError(
          message: 'Failed to batch complete tasks: ${e.toString()}',
          tasks: currentState.tasks,
        ),
      );
    }
  }

  /// Handles resetting a task to incomplete state
  Future<void> _onResetTask(ResetTask event, Emitter<TaskState> emit) async {
    final currentState = state;
    if (currentState is! TaskLoaded) return;

    emit(
      TaskUpdating(
        tasks: currentState.tasks,
        updateType: TaskUpdateType.reset,
        updatingTaskId: event.taskId,
      ),
    );

    try {
      final success = await _taskRepository.resetTask(event.taskId);

      if (!success) {
        emit(
          TaskError(message: 'Failed to reset task', tasks: currentState.tasks),
        );
        return;
      }

      // Get updated task
      final updatedTask = await _taskRepository.getTaskById(event.taskId);
      if (updatedTask == null) {
        emit(
          TaskError(
            message: 'Failed to refresh task after reset',
            tasks: currentState.tasks,
          ),
        );
        return;
      }

      final updatedTasks = currentState.tasks
          .map((task) => task.id == updatedTask.id ? updatedTask : task)
          .toList();

      emit(currentState.copyWith(tasks: updatedTasks));
    } on Exception catch (e) {
      emit(
        TaskError(
          message: 'Failed to reset task: ${e.toString()}',
          tasks: currentState.tasks,
        ),
      );
    }
  }

  /// Handles task deletion
  Future<void> _onDeleteTask(DeleteTask event, Emitter<TaskState> emit) async {
    final currentState = state;
    if (currentState is! TaskLoaded) return;

    emit(
      TaskUpdating(
        tasks: currentState.tasks,
        updateType: TaskUpdateType.deletion,
        updatingTaskId: event.taskId,
      ),
    );

    try {
      final success = await _taskRepository.deleteTask(
        event.taskId,
        event.userId,
      );

      if (!success) {
        emit(
          TaskError(
            message: 'Failed to delete task',
            tasks: currentState.tasks,
          ),
        );
        return;
      }

      final updatedTasks = currentState.tasks
          .where((task) => task.id != event.taskId)
          .toList();

      emit(currentState.copyWith(tasks: updatedTasks));
    } on Exception catch (e, stackTrace) {
      // Log the actual error for debugging
      developer.log('Failed to delete task', name: 'TaskBloc', error: e, stackTrace: stackTrace);

      emit(
        TaskError(
          message: 'Unable to delete task. Please try again.',
          tasks: currentState.tasks,
        ),
      );
    }
  }

  /// Handles filtering tasks by category
  Future<void> _onFilterTasksByCategory(
    FilterTasksByCategory event,
    Emitter<TaskState> emit,
  ) async {
    final currentState = state;
    if (currentState is! TaskLoaded) return;

    try {
      final filteredTasks = await _taskRepository.getTasksByCategory(
        event.userId,
        event.category,
      );

      final filter = TaskFilter(category: event.category);

      emit(
        currentState.copyWith(
          filteredTasks: filteredTasks,
          activeFilter: filter,
        ),
      );
    } on Exception catch (e, stackTrace) {
      // Log the actual error for debugging
      developer.log('Failed to filter tasks by category', name: 'TaskBloc', error: e, stackTrace: stackTrace);

      emit(
        TaskError(
          message: 'Unable to filter tasks. Please try again.',
          tasks: currentState.tasks,
        ),
      );
    }
  }

  /// Handles filtering tasks by type
  Future<void> _onFilterTasksByType(
    FilterTasksByType event,
    Emitter<TaskState> emit,
  ) async {
    final currentState = state;
    if (currentState is! TaskLoaded) return;

    try {
      final filteredTasks = await _taskRepository.getTasksByType(
        event.userId,
        event.type,
      );

      final filter = TaskFilter(type: event.type);

      emit(
        currentState.copyWith(
          filteredTasks: filteredTasks,
          activeFilter: filter,
        ),
      );
    } on Exception catch (e) {
      emit(
        TaskError(
          message: 'Failed to filter tasks: ${e.toString()}',
          tasks: currentState.tasks,
        ),
      );
    }
  }

  /// Handles loading completed tasks
  Future<void> _onLoadCompletedTasks(
    LoadCompletedTasks event,
    Emitter<TaskState> emit,
  ) async {
    final currentState = state;
    if (currentState is! TaskLoaded) return;

    try {
      final completedTasks = await _taskRepository.getCompletedTasks(
        event.userId,
      );

      const filter = TaskFilter(isCompleted: true);

      emit(
        currentState.copyWith(
          filteredTasks: completedTasks,
          activeFilter: filter,
        ),
      );
    } on Exception catch (e) {
      emit(
        TaskError(
          message: 'Failed to load completed tasks: ${e.toString()}',
          tasks: currentState.tasks,
        ),
      );
    }
  }

  /// Handles loading pending tasks
  Future<void> _onLoadPendingTasks(
    LoadPendingTasks event,
    Emitter<TaskState> emit,
  ) async {
    final currentState = state;
    if (currentState is! TaskLoaded) return;

    try {
      final pendingTasks = await _taskRepository.getPendingTasks(event.userId);

      const filter = TaskFilter(isCompleted: false);

      emit(
        currentState.copyWith(
          filteredTasks: pendingTasks,
          activeFilter: filter,
        ),
      );
    } on Exception catch (e) {
      emit(
        TaskError(
          message: 'Failed to load pending tasks: ${e.toString()}',
          tasks: currentState.tasks,
        ),
      );
    }
  }

  /// Handles loading tasks due today
  Future<void> _onLoadTasksDueToday(
    LoadTasksDueToday event,
    Emitter<TaskState> emit,
  ) async {
    final currentState = state;
    if (currentState is! TaskLoaded) return;

    try {
      final tasksDueToday = await _taskRepository.getTasksDueToday(
        event.userId,
      );

      const filter = TaskFilter(isDueToday: true);

      emit(
        currentState.copyWith(
          filteredTasks: tasksDueToday,
          activeFilter: filter,
        ),
      );
    } on Exception catch (e) {
      emit(
        TaskError(
          message: 'Failed to load tasks due today: ${e.toString()}',
          tasks: currentState.tasks,
        ),
      );
    }
  }

  /// Handles loading overdue tasks
  Future<void> _onLoadOverdueTasks(
    LoadOverdueTasks event,
    Emitter<TaskState> emit,
  ) async {
    final currentState = state;
    if (currentState is! TaskLoaded) return;

    try {
      final overdueTasks = await _taskRepository.getOverdueTasks(event.userId);

      const filter = TaskFilter(isOverdue: true);

      emit(
        currentState.copyWith(
          filteredTasks: overdueTasks,
          activeFilter: filter,
        ),
      );
    } on Exception catch (e) {
      emit(
        TaskError(
          message: 'Failed to load overdue tasks: ${e.toString()}',
          tasks: currentState.tasks,
        ),
      );
    }
  }

  /// Handles loading tasks with streaks
  Future<void> _onLoadTasksWithStreaks(
    LoadTasksWithStreaks event,
    Emitter<TaskState> emit,
  ) async {
    final currentState = state;
    if (currentState is! TaskLoaded) return;

    try {
      final tasksWithStreaks = await _taskRepository.getTasksWithStreaks(
        event.userId,
      );

      const filter = TaskFilter(hasStreak: true);

      emit(
        currentState.copyWith(
          filteredTasks: tasksWithStreaks,
          activeFilter: filter,
        ),
      );
    } on Exception catch (e) {
      emit(
        TaskError(
          message: 'Failed to load tasks with streaks: ${e.toString()}',
          tasks: currentState.tasks,
        ),
      );
    }
  }

  /// Handles updating task difficulty
  Future<void> _onUpdateTaskDifficulty(
    UpdateTaskDifficulty event,
    Emitter<TaskState> emit,
  ) async {
    final currentState = state;
    if (currentState is! TaskLoaded) return;

    emit(
      TaskUpdating(
        tasks: currentState.tasks,
        updateType: TaskUpdateType.difficultyUpdate,
        updatingTaskId: event.taskId,
      ),
    );

    try {
      final success = await _taskRepository.updateTaskDifficulty(
        event.taskId,
        event.newDifficulty,
      );

      if (!success) {
        emit(
          TaskError(
            message: 'Failed to update task difficulty',
            tasks: currentState.tasks,
          ),
        );
        return;
      }

      // Get updated task
      final updatedTask = await _taskRepository.getTaskById(event.taskId);
      if (updatedTask == null) {
        emit(
          TaskError(
            message: 'Failed to refresh task after difficulty update',
            tasks: currentState.tasks,
          ),
        );
        return;
      }

      final updatedTasks = currentState.tasks
          .map((task) => task.id == updatedTask.id ? updatedTask : task)
          .toList();

      emit(currentState.copyWith(tasks: updatedTasks));
    } on Exception catch (e) {
      emit(
        TaskError(
          message: 'Failed to update task difficulty: ${e.toString()}',
          tasks: currentState.tasks,
        ),
      );
    }
  }

  /// Handles breaking task streak
  Future<void> _onBreakTaskStreak(
    BreakTaskStreak event,
    Emitter<TaskState> emit,
  ) async {
    final currentState = state;
    if (currentState is! TaskLoaded) return;

    emit(
      TaskUpdating(
        tasks: currentState.tasks,
        updateType: TaskUpdateType.streakBreak,
        updatingTaskId: event.taskId,
      ),
    );

    try {
      final success = await _taskRepository.breakTaskStreak(event.taskId);

      if (!success) {
        emit(
          TaskError(
            message: 'Failed to break task streak',
            tasks: currentState.tasks,
            errorType: TaskErrorType.streakBroken,
          ),
        );
        return;
      }

      // Get updated task
      final updatedTask = await _taskRepository.getTaskById(event.taskId);
      if (updatedTask == null) {
        emit(
          TaskError(
            message: 'Failed to refresh task after streak break',
            tasks: currentState.tasks,
          ),
        );
        return;
      }

      final updatedTasks = currentState.tasks
          .map((task) => task.id == updatedTask.id ? updatedTask : task)
          .toList();

      emit(currentState.copyWith(tasks: updatedTasks));
    } on Exception catch (e) {
      emit(
        TaskError(
          message: 'Failed to break task streak: ${e.toString()}',
          tasks: currentState.tasks,
        ),
      );
    }
  }

  /// Handles sorting tasks
  Future<void> _onSortTasks(SortTasks event, Emitter<TaskState> emit) async {
    final currentState = state;
    if (currentState is! TaskLoaded) return;

    final sortedTasks = _sortTasks(currentState.displayTasks, event.sortType);

    if (currentState.filteredTasks != null) {
      emit(
        currentState.copyWith(
          filteredTasks: sortedTasks,
          sortType: event.sortType,
        ),
      );
    } else {
      emit(currentState.copyWith(tasks: sortedTasks, sortType: event.sortType));
    }
  }

  /// Handles searching tasks
  Future<void> _onSearchTasks(
    SearchTasks event,
    Emitter<TaskState> emit,
  ) async {
    final currentState = state;
    if (currentState is! TaskLoaded) return;

    if (event.query.isEmpty) {
      emit(currentState.copyWith(searchQuery: ''));
      return;
    }

    final searchResults = currentState.tasks.where((task) {
      final query = event.query.toLowerCase();
      return task.title.toLowerCase().contains(query) ||
          task.description.toLowerCase().contains(query) ||
          task.category.displayName.toLowerCase().contains(query) ||
          task.type.displayName.toLowerCase().contains(query);
    }).toList();

    emit(
      currentState.copyWith(
        filteredTasks: searchResults,
        searchQuery: event.query,
      ),
    );
  }

  /// Handles refreshing tasks
  Future<void> _onRefreshTasks(
    RefreshTasks event,
    Emitter<TaskState> emit,
  ) async {
    try {
      final tasks = await _taskRepository.getTasksByUserId(event.userId);

      final currentState = state;
      if (currentState is TaskLoaded) {
        emit(currentState.copyWith(tasks: tasks));
      } else {
        emit(TaskLoaded(tasks: tasks));
      }
    } on Exception catch (e) {
      emit(TaskError(message: 'Failed to refresh tasks: ${e.toString()}'));
    }
  }

  /// Handles task completion animation completion
  Future<void> _onTaskCompletionAnimationCompleted(
    TaskCompletionAnimationCompleted event,
    Emitter<TaskState> emit,
  ) async {
    final currentState = state;
    if (currentState is! TaskLoaded) return;

    emit(currentState.clearCompletionAnimation());
  }

  /// Handles scheduling task reminders
  Future<void> _onScheduleTaskReminders(
    ScheduleTaskReminders event,
    Emitter<TaskState> emit,
  ) async {
    try {
      await _taskRepository.scheduleTaskReminders(
        event.task,
        event.userPreferences,
      );
    } on Exception {
      // Don't emit error state for reminder scheduling failures
      // as it's not critical to the main task functionality
    }
  }

  /// Handles clearing task filters
  Future<void> _onClearTaskFilters(
    ClearTaskFilters event,
    Emitter<TaskState> emit,
  ) async {
    final currentState = state;
    if (currentState is! TaskLoaded) return;

    emit(currentState.clearFilters());
  }

  // Private helper methods

  /// Checks if task completion qualifies for consistency bonus
  bool _isConsistencyBonus(Task task) {
    // Simple heuristic: if task has a streak > 3, it's consistent
    return task.streakCount > 3;
  }

  /// Sorts tasks based on the specified sort type
  List<Task> _sortTasks(List<Task> tasks, TaskSortType sortType) {
    final sortedTasks = List<Task>.from(tasks);

    switch (sortType) {
      case TaskSortType.dueDate:
        sortedTasks.sort((a, b) {
          if (a.dueDate == null && b.dueDate == null) return 0;
          if (a.dueDate == null) return 1;
          if (b.dueDate == null) return -1;
          return a.dueDate!.compareTo(b.dueDate!);
        });
        break;

      case TaskSortType.difficulty:
        sortedTasks.sort((a, b) => b.difficulty.compareTo(a.difficulty));
        break;

      case TaskSortType.xpReward:
        sortedTasks.sort((a, b) => b.xpReward.compareTo(a.xpReward));
        break;

      case TaskSortType.streakCount:
        sortedTasks.sort((a, b) => b.streakCount.compareTo(a.streakCount));
        break;

      case TaskSortType.createdDate:
        sortedTasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;

      case TaskSortType.alphabetical:
        sortedTasks.sort((a, b) => a.title.compareTo(b.title));
        break;

      case TaskSortType.category:
        sortedTasks.sort((a, b) => a.category.name.compareTo(b.category.name));
        break;

      case TaskSortType.type:
        sortedTasks.sort((a, b) => a.type.name.compareTo(b.type.name));
        break;
    }

    return sortedTasks;
  }

  @override
  Future<void> close() {
    _taskRepository.dispose();
    return super.close();
  }
}

// FirstOrNull extension removed to avoid conflicts with repository extensions
