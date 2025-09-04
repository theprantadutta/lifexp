import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/goal.dart';
import '../../../shared/blocs/goal/goal_bloc.dart';
import '../../../shared/blocs/goal/goal_event.dart';

/// Widget to display a list of goals
class GoalListWidget extends StatelessWidget {
  const GoalListWidget({
    super.key,
    required this.goals,
    required this.onGoalUpdated,
  });

  final List<Goal> goals;
  final VoidCallback onGoalUpdated;

  @override
  Widget build(BuildContext context) {
    if (goals.isEmpty) {
      return const Center(
        child: Text('No goals found. Create your first goal!'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: goals.length,
      itemBuilder: (context, index) {
        return GoalCard(
          goal: goals[index],
          onGoalUpdated: onGoalUpdated,
        );
      },
    );
  }
}

/// Widget to display a single goal card
class GoalCard extends StatelessWidget {
  const GoalCard({
    super.key,
    required this.goal,
    required this.onGoalUpdated,
  });

  final Goal goal;
  final VoidCallback onGoalUpdated;

  @override
  Widget build(BuildContext context) {
    final goalBloc = context.read<GoalBloc>();
    final daysUntilDeadline = goal.deadline.difference(DateTime.now()).inDays;

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    goal.title,
                    style: Theme.of(context).textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 4.0,
                  ),
                  decoration: BoxDecoration(
                    color: _getPriorityColor(goal.priority),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Text(
                    goal.priority.displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12.0,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8.0),
            if (goal.description.isNotEmpty)
              Text(
                goal.description,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 12.0),
            LinearProgressIndicator(
              value: goal.progress,
              minHeight: 8.0,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                _getProgressColor(goal.progress),
              ),
            ),
            const SizedBox(height: 8.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${(goal.progress * 100).round()}% complete',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  _getStatusText(goal.status),
                  style: TextStyle(
                    color: _getStatusColor(goal.status),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  goal.category.displayName,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  _getDeadlineText(daysUntilDeadline),
                  style: TextStyle(
                    color: _getDeadlineColor(daysUntilDeadline),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    // TODO: Implement edit functionality
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    _confirmDelete(context, goalBloc, goal);
                  },
                ),
                IconButton(
                  icon: Icon(
                    goal.status == GoalStatus.completed
                        ? Icons.undo
                        : Icons.check,
                  ),
                  onPressed: () {
                    if (goal.status == GoalStatus.completed) {
                      // Mark as in progress
                      goalBloc.add(
                        UpdateGoalStatus(
                          goal.id,
                          GoalStatus.inProgress,
                        ),
                      );
                    } else {
                      // Mark as completed
                      goalBloc.add(
                        UpdateGoalStatus(
                          goal.id,
                          GoalStatus.completed,
                        ),
                      );
                    }
                    onGoalUpdated();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Gets color based on priority
  Color _getPriorityColor(GoalPriority priority) {
    switch (priority) {
      case GoalPriority.low:
        return Colors.green;
      case GoalPriority.medium:
        return Colors.orange;
      case GoalPriority.high:
        return Colors.red;
      case GoalPriority.critical:
        return Colors.purple;
    }
  }

  /// Gets color based on progress
  Color _getProgressColor(double progress) {
    if (progress < 0.3) return Colors.red;
    if (progress < 0.7) return Colors.orange;
    return Colors.green;
  }

  /// Gets status text
  String _getStatusText(GoalStatus status) {
    return status.displayName;
  }

  /// Gets color based on status
  Color _getStatusColor(GoalStatus status) {
    switch (status) {
      case GoalStatus.notStarted:
        return Colors.grey;
      case GoalStatus.inProgress:
        return Colors.blue;
      case GoalStatus.onHold:
        return Colors.orange;
      case GoalStatus.completed:
        return Colors.green;
      case GoalStatus.cancelled:
        return Colors.red;
    }
  }

  /// Gets deadline text
  String _getDeadlineText(int daysUntilDeadline) {
    if (daysUntilDeadline < 0) {
      return 'Overdue by ${daysUntilDeadline.abs()} days';
    } else if (daysUntilDeadline == 0) {
      return 'Due today';
    } else if (daysUntilDeadline == 1) {
      return 'Due tomorrow';
    } else {
      return 'Due in $daysUntilDeadline days';
    }
  }

  /// Gets color based on deadline
  Color _getDeadlineColor(int daysUntilDeadline) {
    if (daysUntilDeadline < 0) return Colors.red;
    if (daysUntilDeadline <= 3) return Colors.orange;
    return Colors.green;
  }

  /// Shows confirmation dialog for deleting a goal
  void _confirmDelete(
    BuildContext context,
    GoalBloc goalBloc,
    Goal goal,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Goal'),
          content: Text('Are you sure you want to delete "${goal.title}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                goalBloc.add(DeleteGoal(goal.id, goal.userId));
                Navigator.pop(context);
                onGoalUpdated();
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}