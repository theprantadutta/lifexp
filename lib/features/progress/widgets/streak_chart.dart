import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../data/models/progress.dart';

/// Widget for displaying streak data using a bar chart
class StreakChart extends StatelessWidget {
  const StreakChart({
    required this.progressEntries,
    super.key,
  });

  final List<ProgressEntry> progressEntries;

  @override
  Widget build(BuildContext context) {
    if (progressEntries.isEmpty) {
      return _buildEmptyChart(context);
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Activity Streak',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  gridData: FlGridData(
                    horizontalInterval: 1,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Theme.of(context)
                          .colorScheme
                          .outline
                          .withValues(alpha: 0.3),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) => _buildBottomTitle(
                          context,
                          value,
                          meta,
                        ),
                        reservedSize: 30,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 42,
                        getTitlesWidget: (value, meta) => _buildLeftTitle(
                          context,
                          value,
                          meta,
                        ),
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(
                      color: Theme.of(context)
                          .colorScheme
                          .outline
                          .withValues(alpha: 0.3),
                    ),
                  ),
                  barGroups: _buildBarGroups(context),
                  maxY: _getMaxY(),
                ),
              ),
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
                'Activity Streak',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 32),
              Icon(
                Icons.bar_chart,
                size: 48,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'No streak data available',
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

  List<BarChartGroupData> _buildBarGroups(BuildContext context) {
    final groups = <BarChartGroupData>[];
    
    for (var i = 0; i < progressEntries.length; i++) {
      final entry = progressEntries[i];
      final hasActivity = entry.xpGained > 0 || entry.tasksCompleted > 0;
      
      groups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: hasActivity ? 1 : 0,
              color: hasActivity 
                  ? Theme.of(context).colorScheme.primary 
                  : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
              width: 16,
              borderRadius: BorderRadius.zero,
            ),
          ],
        ),
      );
    }
    
    return groups;
  }

  double _getMaxY() => 1.5;

  Widget _buildBottomTitle(BuildContext context, double value, TitleMeta meta) {
    final index = value.toInt();
    if (index < 0 || index >= progressEntries.length) {
      return const SizedBox.shrink();
    }

    final entry = progressEntries[index];
    final date = entry.date;

    return SideTitleWidget(
      meta: meta,
      space: 8,
      child: Text(
        '${date.month}/${date.day}',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.7),
            ),
      ),
    );
  }

  Widget _buildLeftTitle(BuildContext context, double value, TitleMeta meta) => SideTitleWidget(
        meta: meta,
        space: 8,
        child: Text(
          value.toInt().toString(),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.7),
              ),
        ),
      );
}