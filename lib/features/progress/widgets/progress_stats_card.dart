import 'package:flutter/material.dart';

import '../../../data/models/progress.dart';
import '../../../data/models/progress_period.dart';
import '../../../data/models/task.dart';

/// Widget for displaying detailed statistics for a specific category
class ProgressStatsCard extends StatelessWidget {
  const ProgressStatsCard({
    required this.category,
    required this.progressEntries,
    required this.period,
    super.key,
  });

  final TaskCategory category;
  final List<ProgressEntry> progressEntries;
  final ProgressPeriod period;

  @override
  Widget build(BuildContext context) {
    final stats = _calculateStats();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  category.icon,
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    category.displayName,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getCategoryColor(category).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${stats.totalXp} XP',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: _getCategoryColor(category),
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Tasks',
                    stats.totalTasks.toString(),
                    Icons.task_alt,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Avg XP',
                    stats.averageXp.toStringAsFixed(1),
                    Icons.trending_up,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Best Day',
                    stats.bestDayXp.toString(),
                    Icons.star,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildProgressBar(context, stats),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Consistency',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.7),
                      ),
                ),
                Text(
                  '${stats.consistencyPercentage.toStringAsFixed(0)}%',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: _getCategoryColor(category),
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) => Column(
        children: [
          Icon(
            icon,
            size: 20,
            color: _getCategoryColor(category),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.7),
                ),
          ),
        ],
      );

  Widget _buildProgressBar(BuildContext context, CategoryStats stats) {
    final progress = stats.consistencyPercentage / 100;
    
    return LinearProgressIndicator(
      value: progress,
      backgroundColor: Theme.of(context)
          .colorScheme
          .surfaceContainerHighest,
      valueColor: AlwaysStoppedAnimation<Color>(
        _getCategoryColor(category),
      ),
    );
  }

  CategoryStats _calculateStats() {
    if (progressEntries.isEmpty) {
      return const CategoryStats(
        totalXp: 0,
        totalTasks: 0,
        averageXp: 0,
        bestDayXp: 0,
        consistencyPercentage: 0,
      );
    }

    final totalXp = progressEntries.fold<int>(
      0,
      (sum, entry) => sum + entry.xpGained,
    );

    final totalTasks = progressEntries.fold<int>(
      0,
      (sum, entry) => sum + entry.tasksCompleted,
    );

    final averageXp = totalXp / progressEntries.length;

    final bestDayXp = progressEntries.fold<int>(
      0,
      (max, entry) => entry.xpGained > max ? entry.xpGained : max,
    );

    // Calculate consistency as percentage of days with activity
    final daysWithActivity = progressEntries.where((entry) => 
        entry.xpGained > 0 || entry.tasksCompleted > 0).length;
    final consistencyPercentage = (daysWithActivity / progressEntries.length) * 100;

    return CategoryStats(
      totalXp: totalXp,
      totalTasks: totalTasks,
      averageXp: averageXp,
      bestDayXp: bestDayXp,
      consistencyPercentage: consistencyPercentage,
    );
  }

  Color _getCategoryColor(TaskCategory category) {
    switch (category) {
      case TaskCategory.health:
        return Colors.green;
      case TaskCategory.finance:
        return Colors.blue;
      case TaskCategory.work:
        return Colors.orange;
      case TaskCategory.learning:
        return Colors.purple;
      case TaskCategory.social:
        return Colors.pink;
      case TaskCategory.creative:
        return Colors.teal;
      case TaskCategory.fitness:
        return Colors.red;
      case TaskCategory.mindfulness:
        return Colors.indigo;
      case TaskCategory.custom:
        return Colors.grey;
    }
  }
}

/// Data class for category statistics
class CategoryStats {
  const CategoryStats({
    required this.totalXp,
    required this.totalTasks,
    required this.averageXp,
    required this.bestDayXp,
    required this.consistencyPercentage,
  });

  final int totalXp;
  final int totalTasks;
  final double averageXp;
  final int bestDayXp;
  final double consistencyPercentage;
}