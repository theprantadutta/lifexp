import 'package:flutter/material.dart';

import '../../../data/models/progress.dart';

/// Widget for tracking goal progress with visual indicators
class GoalProgressTracker extends StatelessWidget {
  const GoalProgressTracker({
    required this.progressEntries,
    super.key,
  });

  final List<ProgressEntry> progressEntries;

  @override
  Widget build(BuildContext context) {
    final goals = _calculateGoals();
    
    if (goals.isEmpty) {
      return _buildEmptyGoals(context);
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Goal Progress',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ...goals.map((goal) => _buildGoalItem(context, goal)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyGoals(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                'Goal Progress',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 32),
              Icon(
                Icons.flag,
                size: 48,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'No goals set yet',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.7),
                    ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      );

  List<GoalProgress> _calculateGoals() {
    // This is a simplified example - in a real app, goals would come from a database
    // For now, we'll create some example goals based on the progress data
    
    if (progressEntries.isEmpty) return [];
    
    final totalXp = progressEntries.fold<int>(0, (sum, entry) => sum + entry.xpGained);
    final totalTasks = progressEntries.fold<int>(0, (sum, entry) => sum + entry.tasksCompleted);
    
    return [
      GoalProgress(
        id: 'xp_goal',
        title: 'XP Target',
        description: 'Earn 1000 XP this week',
        currentValue: totalXp.toDouble(),
        targetValue: 1000,
        unit: 'XP',
        color: Colors.blue,
      ),
      GoalProgress(
        id: 'task_goal',
        title: 'Task Completion',
        description: 'Complete 50 tasks this week',
        currentValue: totalTasks.toDouble(),
        targetValue: 50,
        unit: 'tasks',
        color: Colors.green,
      ),
    ];
  }

  Widget _buildGoalItem(BuildContext context, GoalProgress goal) {
    final progress = goal.currentValue / goal.targetValue;
    final percentage = (progress * 100).clamp(0.0, 100.0);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    goal.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    goal.description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.7),
                        ),
                  ),
                ],
              ),
              Text(
                '${goal.currentValue.toInt()}/${goal.targetValue.toInt()} ${goal.unit}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: goal.color,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(goal.color),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${percentage.toStringAsFixed(1)}% complete',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.7),
                    ),
              ),
              if (progress >= 1.0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: goal.color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 16,
                        color: goal.color,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Completed!',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: goal.color,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Data class for goal progress tracking
class GoalProgress {
  const GoalProgress({
    required this.id,
    required this.title,
    required this.description,
    required this.currentValue,
    required this.targetValue,
    required this.unit,
    required this.color,
  });

  final String id;
  final String title;
  final String description;
  final double currentValue;
  final int targetValue;
  final String unit;
  final Color color;
}