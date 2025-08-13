import 'package:flutter/material.dart';

import '../models/task.dart';
import '../services/accessibility_service.dart';

/// Accessible task card with comprehensive screen reader support
class AccessibleTaskCard extends StatelessWidget {

  const AccessibleTaskCard({
    required this.task, super.key,
    this.onTap,
    this.onComplete,
    this.onEdit,
    this.onDelete,
    this.showActions = true,
    this.compact = false,
  });
  final Task task;
  final VoidCallback? onTap;
  final VoidCallback? onComplete;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool showActions;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accessibilityService = AccessibilityService();
    
    final semanticLabel = accessibilityService.createTaskCardLabel(
      title: task.title,
      category: task.category.name,
      difficulty: _getDifficultyText(task.difficulty),
      isCompleted: task.isCompleted,
      xpReward: task.xpReward,
      streakCount: task.streakCount,
      dueDate: task.dueDate,
    );
    
    final categoryColor = _getCategoryColor(context, task.category);
    
    return Semantics(
      label: semanticLabel,
      hint: task.isCompleted 
          ? 'Task completed' 
          : accessibilityService.createInteractionHint('view task details'),
      button: onTap != null,
      enabled: true,
      child: Card(
        margin: compact 
            ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4)
            : const EdgeInsets.all(8),
        elevation: task.isCompleted ? 1 : 2,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: compact 
                ? const EdgeInsets.all(12)
                : const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: categoryColor.withValues(alpha: 0.3),
                width: 2,
              ),
              color: task.isCompleted
                  ? theme.colorScheme.surfaceContainerHighest
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  children: [
                    // Completion checkbox
                    Semantics(
                      label: task.isCompleted 
                          ? 'Task completed' 
                          : 'Mark task as complete',
                      hint: 'Double tap to ${task.isCompleted ? 'mark incomplete' : 'complete task'}',
                      button: true,
                      child: Checkbox(
                        value: task.isCompleted,
                        onChanged: onComplete != null 
                            ? (_) => onComplete!() 
                            : null,
                        activeColor: categoryColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Task title
                    Expanded(
                      child: Semantics(
                        header: true,
                        child: Text(
                          task.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            decoration: task.isCompleted 
                                ? TextDecoration.lineThrough 
                                : null,
                            color: task.isCompleted
                                ? theme.colorScheme.onSurface.withValues(alpha: 0.6)
                                : null,
                          ),
                        ),
                      ),
                    ),
                    // XP reward
                    Semantics(
                      label: '${task.xpReward} experience points reward',
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: categoryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: categoryColor.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          '${task.xpReward} XP',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: categoryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                
                if (!compact && task.description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Semantics(
                    label: 'Task description: ${task.description}',
                    child: Text(
                      task.description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ],
                
                const SizedBox(height: 12),
                
                // Task metadata
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    // Category chip
                    Semantics(
                      label: 'Category: ${task.category.name}',
                      child: Chip(
                        label: Text(
                          task.category.name.toUpperCase(),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: categoryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        backgroundColor: categoryColor.withValues(alpha: 0.1),
                        side: BorderSide(
                          color: categoryColor.withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                    
                    // Difficulty chip
                    Semantics(
                      label: 'Difficulty: ${_getDifficultyText(task.difficulty)}',
                      child: Chip(
                        label: Text(
                          _getDifficultyText(task.difficulty),
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        backgroundColor: _getDifficultyColor(task.difficulty).withValues(alpha: 0.1),
                        side: BorderSide(
                          color: _getDifficultyColor(task.difficulty).withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                    
                    // Streak indicator
                    if (task.streakCount > 0)
                      Semantics(
                        label: 'Streak: ${task.streakCount} days',
                        child: Chip(
                          avatar: const Icon(Icons.local_fire_department, size: 16),
                          label: Text(
                            '${task.streakCount}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          backgroundColor: Colors.orange.withValues(alpha: 0.1),
                          side: BorderSide(
                            color: Colors.orange.withValues(alpha: 0.3),
                          ),
                        ),
                      ),
                    
                    // Due date indicator
                    if (task.dueDate != null && !task.isCompleted)
                      _buildDueDateChip(context, task.dueDate!),
                  ],
                ),
                
                // Action buttons
                if (showActions && (onEdit != null || onDelete != null)) ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (onEdit != null)
                        Semantics(
                          label: 'Edit task',
                          hint: accessibilityService.createInteractionHint('edit'),
                          button: true,
                          child: IconButton(
                            onPressed: onEdit,
                            icon: const Icon(Icons.edit),
                            tooltip: 'Edit task',
                          ),
                        ),
                      if (onDelete != null)
                        Semantics(
                          label: 'Delete task',
                          hint: accessibilityService.createInteractionHint('delete'),
                          button: true,
                          child: IconButton(
                            onPressed: onDelete,
                            icon: const Icon(Icons.delete),
                            tooltip: 'Delete task',
                            color: theme.colorScheme.error,
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDueDateChip(BuildContext context, DateTime dueDate) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final difference = dueDate.difference(now);
    
    Color chipColor;
    String label;
    String semanticLabel;
    
    if (difference.isNegative) {
      chipColor = theme.colorScheme.error;
      label = 'OVERDUE';
      semanticLabel = 'Task is overdue';
    } else if (difference.inDays == 0) {
      chipColor = Colors.orange;
      label = 'DUE TODAY';
      semanticLabel = 'Task is due today';
    } else if (difference.inDays == 1) {
      chipColor = Colors.amber;
      label = 'DUE TOMORROW';
      semanticLabel = 'Task is due tomorrow';
    } else {
      chipColor = theme.colorScheme.primary;
      label = 'DUE IN ${difference.inDays}D';
      semanticLabel = 'Task is due in ${difference.inDays} days';
    }
    
    return Semantics(
      label: semanticLabel,
      child: Chip(
        label: Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: chipColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: chipColor.withValues(alpha: 0.1),
        side: BorderSide(
          color: chipColor.withValues(alpha: 0.3),
        ),
      ),
    );
  }

  String _getDifficultyText(int difficulty) {
    if (difficulty <= 3) return 'Easy';
    if (difficulty <= 6) return 'Medium';
    return 'Hard';
  }

  Color _getDifficultyColor(int difficulty) {
    if (difficulty <= 3) return Colors.green;
    if (difficulty <= 6) return Colors.orange;
    return Colors.red;
  }

  Color _getCategoryColor(BuildContext context, TaskCategory category) {
    final theme = Theme.of(context);
    
    switch (category) {
      case TaskCategory.health:
        return Colors.green;
      case TaskCategory.fitness:
        return Colors.blue;
      case TaskCategory.learning:
        return Colors.purple;
      case TaskCategory.work:
        return Colors.indigo;
      case TaskCategory.finance:
        return Colors.teal;
      case TaskCategory.social:
        return Colors.pink;
      case TaskCategory.creative:
        return Colors.orange;
      case TaskCategory.mindfulness:
        return Colors.deepPurple;
      case TaskCategory.custom:
        return theme.colorScheme.primary;
    }
  }
}

/// Accessible task list with proper focus management
class AccessibleTaskList extends StatelessWidget {

  const AccessibleTaskList({
    required this.tasks, super.key,
    this.onTaskTap,
    this.onTaskComplete,
    this.onTaskEdit,
    this.onTaskDelete,
    this.compact = false,
    this.emptyMessage,
  });
  final List<Task> tasks;
  final Function(Task)? onTaskTap;
  final Function(Task)? onTaskComplete;
  final Function(Task)? onTaskEdit;
  final Function(Task)? onTaskDelete;
  final bool compact;
  final String? emptyMessage;

  @override
  Widget build(BuildContext context) {
    final accessibilityService = AccessibilityService();
    
    if (tasks.isEmpty) {
      return Semantics(
        label: emptyMessage ?? 'No tasks available',
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.task_alt,
                  size: 64,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  emptyMessage ?? 'No tasks yet',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    return accessibilityService.createAccessibleList(
      semanticLabel: '${tasks.length} tasks',
      children: tasks.asMap().entries.map((entry) {
        final index = entry.key;
        final task = entry.value;
        
        return Semantics(
          sortKey: OrdinalSortKey(index.toDouble()),
          child: AccessibleTaskCard(
            task: task,
            onTap: onTaskTap != null ? () => onTaskTap!(task) : null,
            onComplete: onTaskComplete != null ? () => onTaskComplete!(task) : null,
            onEdit: onTaskEdit != null ? () => onTaskEdit!(task) : null,
            onDelete: onTaskDelete != null ? () => onTaskDelete!(task) : null,
            compact: compact,
          ),
        );
      }).toList(),
    );
  }
}