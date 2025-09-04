import 'package:flutter/material.dart';

import '../../../data/models/habit.dart';

/// Widget for displaying a list of habits
class HabitListWidget extends StatelessWidget {
  const HabitListWidget({
    super.key,
    required this.habits,
    required this.onHabitComplete,
    required this.onHabitReset,
  });

  final List<Habit> habits;
  final Function(String) onHabitComplete;
  final Function(String) onHabitReset;

  @override
  Widget build(BuildContext context) {
    if (habits.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.self_improvement, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No habits yet',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Add your first habit to get started',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: habits.length,
      itemBuilder: (context, index) {
        final habit = habits[index];
        return HabitCard(
          habit: habit,
          onHabitComplete: onHabitComplete,
          onHabitReset: onHabitReset,
        );
      },
    );
  }
}

/// Widget for displaying a single habit card
class HabitCard extends StatelessWidget {
  const HabitCard({
    super.key,
    required this.habit,
    required this.onHabitComplete,
    required this.onHabitReset,
  });

  final Habit habit;
  final Function(String) onHabitComplete;
  final Function(String) onHabitReset;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        habit.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${habit.category.displayName} • ${habit.frequency.displayName}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getDifficultyColor(habit.difficulty, colorScheme),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Level ${habit.difficulty}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (habit.description.isNotEmpty)
              Text(
                habit.description,
                style: theme.textTheme.bodyMedium,
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: habit.isCompletedToday
                        ? colorScheme.primary.withValues(alpha: 0.1)
                        : colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: habit.isCompletedToday
                          ? colorScheme.primary
                          : colorScheme.outline,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        habit.isCompletedToday
                            ? Icons.check_circle
                            : Icons.circle_outlined,
                        size: 16,
                        color: habit.isCompletedToday
                            ? colorScheme.primary
                            : colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        habit.isCompletedToday ? 'Completed' : 'Not completed',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: habit.isCompletedToday
                              ? colorScheme.primary
                              : colorScheme.onSurface.withValues(alpha: 0.6),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                if (habit.streakCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: colorScheme.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: colorScheme.error),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.local_fire_department, size: 16, color: Colors.orange),
                        const SizedBox(width: 6),
                        Text(
                          '${habit.streakCount} day streak',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.error,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  'Completion Rate: ${(habit.completionRate * 100).toStringAsFixed(1)}%',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const Spacer(),
                if (habit.isCompletedToday)
                  OutlinedButton(
                    onPressed: () => onHabitReset(habit.id),
                    child: const Text('Reset'),
                  )
                else
                  ElevatedButton(
                    onPressed: () => onHabitComplete(habit.id),
                    child: const Text('Complete'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Gets color based on habit difficulty
  Color _getDifficultyColor(int difficulty, ColorScheme colorScheme) {
    if (difficulty <= 3) return Colors.green;
    if (difficulty <= 6) return Colors.orange;
    return Colors.red;
  }
}