import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../data/models/progress.dart';
import '../../../data/models/task.dart';

/// Widget for displaying category breakdown using a pie chart
class CategoryBreakdownChart extends StatefulWidget {
  const CategoryBreakdownChart({
    required this.progressEntries,
    super.key,
  });

  final List<ProgressEntry> progressEntries;

  @override
  State<CategoryBreakdownChart> createState() => _CategoryBreakdownChartState();
}

class _CategoryBreakdownChartState extends State<CategoryBreakdownChart> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final categoryData = _calculateCategoryData();

    if (categoryData.isEmpty) {
      return _buildEmptyChart(context);
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'XP by Category',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 200,
                    child: PieChart(
                      PieChartData(
                        pieTouchData: PieTouchData(
                          touchCallback: (event, pieTouchResponse) {
                            setState(() {
                              if (!event.isInterestedForInteractions ||
                                  pieTouchResponse == null ||
                                  pieTouchResponse.touchedSection == null) {
                                touchedIndex = -1;
                                return;
                              }
                              touchedIndex = pieTouchResponse
                                  .touchedSection!.touchedSectionIndex;
                            });
                          },
                        ),
                        borderData: FlBorderData(show: false),
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                        sections: _buildPieChartSections(categoryData),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildLegend(categoryData),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyChart(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                'XP by Category',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 32),
              Icon(
                Icons.pie_chart,
                size: 48,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'No category data available',
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

  Map<TaskCategory, int> _calculateCategoryData() {
    final categoryXp = <TaskCategory, int>{};

    for (final entry in widget.progressEntries) {
      if (entry.category != null) {
        try {
          final category = TaskCategory.values.byName(entry.category!);
          categoryXp[category] = 
              (categoryXp[category] ?? 0) + entry.xpGained;
        } catch (e) {
          // Skip invalid category names
          continue;
        }
      }
    }

    // Remove categories with 0 XP
    categoryXp.removeWhere((key, value) => value == 0);

    return categoryXp;
  }

  List<PieChartSectionData> _buildPieChartSections(
    Map<TaskCategory, int> categoryData,
  ) {
    final totalXp = categoryData.values.fold<int>(0, (sum, xp) => sum + xp);
    final sections = <PieChartSectionData>[];

    var index = 0;
    for (final entry in categoryData.entries) {
      final category = entry.key;
      final xp = entry.value;
      final percentage = xp / totalXp * 100;
      final isTouched = index == touchedIndex;

      sections.add(
        PieChartSectionData(
          color: _getCategoryColor(category),
          value: xp.toDouble(),
          title: isTouched ? '${percentage.toStringAsFixed(1)}%' : '',
          radius: isTouched ? 60 : 50,
          titleStyle: TextStyle(
            fontSize: isTouched ? 16 : 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          titlePositionPercentageOffset: 0.6,
        ),
      );
      index++;
    }

    return sections;
  }

  Widget _buildLegend(Map<TaskCategory, int> categoryData) {
    final totalXp = categoryData.values.fold<int>(0, (sum, xp) => sum + xp);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: categoryData.entries.map((entry) {
        final category = entry.key;
        final xp = entry.value;
        final percentage = xp / totalXp * 100;

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: _getCategoryColor(category),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.displayName,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    Text(
                      '$xp XP (${percentage.toStringAsFixed(1)}%)',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.7),
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
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