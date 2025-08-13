import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/task.dart';
import '../../../shared/blocs/task/task_bloc_exports.dart';
import '../../../shared/providers/user_context.dart';
import '../../../shared/widgets/task_card.dart';
import '../widgets/add_task_dialog.dart';

/// Tasks screen for managing daily, weekly, and long-term tasks
class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  TaskCategory? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Load tasks will be called in didChangeDependencies when user context is available
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = context.currentUserOrNull;
    if (user != null) {
      context.read<TaskBloc>().add(LoadTasks(userId: user.id));
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Tasks'),
      centerTitle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      elevation: 0,
      automaticallyImplyLeading: false,
      bottom: TabBar(
        controller: _tabController,
        tabs: const [
          Tab(text: 'Daily', icon: Icon(Icons.today)),
          Tab(text: 'Weekly', icon: Icon(Icons.view_week)),
          Tab(text: 'Long-term', icon: Icon(Icons.flag)),
        ],
      ),
    ),
    body: Column(
      children: [
        _buildFilterChips(),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildTaskList(TaskType.daily),
              _buildTaskList(TaskType.weekly),
              _buildTaskList(TaskType.longTerm),
            ],
          ),
        ),
      ],
    ),
    floatingActionButton: FloatingActionButton(
      onPressed: _showAddTaskDialog,
      child: const Icon(Icons.add),
    ),
  );

  Widget _buildFilterChips() => Container(
    padding: const EdgeInsets.all(16),
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          FilterChip(
            label: const Text('All'),
            selected: _selectedCategory == null,
            onSelected: (selected) {
              setState(() {
                _selectedCategory = null;
              });
              context.read<TaskBloc>().add(
                ClearTaskFilters(userId: context.currentUser.id),
              );
            },
          ),
          const SizedBox(width: 8),
          ...TaskCategory.values.map(
            (category) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(category.displayName),
                selected: _selectedCategory == category,
                onSelected: (selected) {
                  setState(() {
                    _selectedCategory = selected ? category : null;
                  });
                  if (selected) {
                    context.read<TaskBloc>().add(
                      FilterTasksByCategory(
                        userId: context.currentUser.id,
                        category: category,
                      ),
                    );
                  } else {
                    context.read<TaskBloc>().add(
                      ClearTaskFilters(userId: context.currentUser.id),
                    );
                  }
                },
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildTaskList(TaskType type) => BlocBuilder<TaskBloc, TaskState>(
    builder: (context, state) {
      if (state is TaskLoading) {
        return const Center(child: CircularProgressIndicator());
      }

      if (state is TaskError) {
        return Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 12),
                Text(
                  'Error loading tasks',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  state.message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => context.read<TaskBloc>().add(
                    LoadTasks(userId: context.currentUser.id),
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        );
      }

      if (state is TaskLoaded) {
        final tasks = state.tasks.where((task) => task.type == type).toList();

        if (tasks.isEmpty) {
          return _buildEmptyState(type);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            final task = tasks[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: TaskCard(
                title: task.title,
                description: task.description,
                category: task.category.displayName,
                xpReward: task.xpReward,
                difficulty: task.difficulty,
                streakCount: task.streakCount,
                isCompleted: task.isCompleted,
                dueDate: task.dueDate,
                onComplete: () => _completeTask(task),
                onEdit: () => _editTask(task),
                onDelete: () => _deleteTask(task),
              ),
            );
          },
        );
      }

      return const SizedBox.shrink();
    },
  );

  Widget _buildEmptyState(TaskType type) {
    String message;
    IconData icon;

    switch (type) {
      case TaskType.daily:
        message = 'No daily tasks yet.\nAdd some to build your routine!';
        icon = Icons.today;
        break;
      case TaskType.weekly:
        message = 'No weekly tasks yet.\nSet some goals for the week!';
        icon = Icons.view_week;
        break;
      case TaskType.longTerm:
        message = 'No long-term tasks yet.\nPlan your big achievements!';
        icon = Icons.flag;
        break;
    }

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 48,
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _showAddTaskDialog(type),
              icon: const Icon(Icons.add),
              label: Text('Add ${type.displayName} Task'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddTaskDialog([TaskType? type]) {
    showDialog(
      context: context,
      builder: (context) => AddTaskDialog(
        initialType: type ?? TaskType.daily,
        onTaskAdded:
            (title, description, taskType, category, difficulty, dueDate) {
              context.read<TaskBloc>().add(
                CreateTask(
                  userId: context.currentUser.id,
                  title: title,
                  type: taskType,
                  category: category,
                  description: description,
                  difficulty: difficulty,
                  dueDate: dueDate,
                ),
              );
            },
      ),
    );
  }

  void _editTask(Task task) {
    showDialog(
      context: context,
      builder: (context) => AddTaskDialog(
        initialType: task.type,
        task: task,
        onTaskAdded:
            (title, description, taskType, category, difficulty, dueDate) {
              final updatedTask = task.copyWith(
                title: title,
                description: description,
                type: taskType,
                category: category,
                difficulty: difficulty,
                dueDate: dueDate,
              );
              context.read<TaskBloc>().add(
                UpdateTask(task: updatedTask, userId: context.currentUser.id),
              );
            },
      ),
    );
  }

  void _completeTask(Task task) {
    context.read<TaskBloc>().add(CompleteTask(taskId: task.id));
  }

  void _deleteTask(Task task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: Text('Are you sure you want to delete "${task.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<TaskBloc>().add(
                DeleteTask(taskId: task.id, userId: context.currentUser.id),
              );
              Navigator.of(context).pop();
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
