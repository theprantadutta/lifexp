import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../data/models/progress.dart';
import '../../../data/models/progress_period.dart';

/// Widget for displaying comparative analytics using bar charts
class ComparativeAnalyticsChart extends StatelessWidget {
  const ComparativeAnalyticsChart({
    required this.currentPeriodEntries,
    required this.previousPeriodEntries,
    required this.currentPeriod,
    super.key,
  });

  final List<ProgressEntry> currentPeriodEntries;
  final List<ProgressEntry> previousPeriodEntries;
  final ProgressPeriod currentPeriod;

  @override
  Widget build(BuildContext context) {
    if (currentPeriodEntries.isEmpty && previousPeriodEntries.isEmpty) {
      return _buildEmptyChart(context);
    }

    final currentStats = _calculateStats(currentPeriodEntries);
    final previousStats = _calculateStats(previousPeriodEntries);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Period Comparison',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Text(
              _getComparisonInsight(currentStats, previousStats),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: _getComparisonColor(currentStats.totalXp, previousStats.totalXp),
                    fontWeight: FontWeight.w500,
                  ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  gridData: FlGridData(
                    horizontalInterval: _getHorizontalInterval(currentStats, previousStats),
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
                  barGroups: _buildBarGroups(context, currentStats, previousStats),
                  maxY: _getMaxY(currentStats, previousStats),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildComparisonLegend(context),
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
                'Period Comparison',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 32),
              Icon(
                Icons.compare,
                size: 48,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'No comparison data available',
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

  PeriodStats _calculateStats(List<ProgressEntry> entries) {
    if (entries.isEmpty) {
      return const PeriodStats(
        totalXp: 0,
        totalTasks: 0,
        averageXpPerDay: 0.0,
        bestDayXp: 0,
        streakDays: 0,
      );
    }

    final totalXp = entries.fold<int>(0, (sum, entry) => sum + entry.xpGained);
    final totalTasks = entries.fold<int>(
        0, (sum, entry) => sum + entry.tasksCompleted);
    final averageXpPerDay = entries.isNotEmpty ? totalXp / entries.length : 0.0;
    final bestDayXp = entries.fold<int>(
        0, (max, entry) => entry.xpGained > max ? entry.xpGained : max);

    // Calculate streak days (consecutive days with activity)
    var streakDays = 0;
    var currentStreak = 0;
    DateTime? lastDate;

    for (final entry in entries) {
      if (lastDate == null) {
        currentStreak = 1;
      } else {
        final difference = entry.date.difference(lastDate).inDays;
        if (difference == 1) {
          currentStreak++;
        } else if (difference > 1) {
          if (currentStreak > streakDays) {
            streakDays = currentStreak;
          }
          currentStreak = 1;
        }
      }
      lastDate = entry.date;
    }

    if (currentStreak > streakDays) {
      streakDays = currentStreak;
    }

    return PeriodStats(
      totalXp: totalXp,
      totalTasks: totalTasks,
      averageXpPerDay: averageXpPerDay,
      bestDayXp: bestDayXp,
      streakDays: streakDays,
    );
  }

  List<BarChartGroupData> _buildBarGroups(
    BuildContext context,
    PeriodStats currentStats,
    PeriodStats previousStats,
  ) {
    return [
      BarChartGroupData(
        x: 0,
        barRods: [
          BarChartRodData(
            toY: currentStats.totalXp.toDouble(),
            color: Theme.of(context).colorScheme.primary,
            width: 16,
            borderRadius: BorderRadius.zero,
            rodStackItems: [],
          ),
        ],
      ),
      BarChartGroupData(
        x: 1,
        barRods: [
          BarChartRodData(
            toY: previousStats.totalXp.toDouble(),
            color: Theme.of(context).colorScheme.secondary,
            width: 16,
            borderRadius: BorderRadius.zero,
            rodStackItems: [],
          ),
        ],
      ),
      BarChartGroupData(
        x: 2,
        barRods: [
          BarChartRodData(
            toY: currentStats.totalTasks.toDouble(),
            color: Theme.of(context).colorScheme.primary,
            width: 16,
            borderRadius: BorderRadius.zero,
            rodStackItems: [],
          ),
        ],
      ),
      BarChartGroupData(
        x: 3,
        barRods: [
          BarChartRodData(
            toY: previousStats.totalTasks.toDouble(),
            color: Theme.of(context).colorScheme.secondary,
            width: 16,
            borderRadius: BorderRadius.zero,
            rodStackItems: [],
          ),
        ],
      ),
      BarChartGroupData(
        x: 4,
        barRods: [
          BarChartRodData(
            toY: currentStats.averageXpPerDay.toDouble(),
            color: Theme.of(context).colorScheme.primary,
            width: 16,
            borderRadius: BorderRadius.zero,
            rodStackItems: [],
          ),
        ],
      ),
      BarChartGroupData(
        x: 5,
        barRods: [
          BarChartRodData(
            toY: previousStats.averageXpPerDay.toDouble(),
            color: Theme.of(context).colorScheme.secondary,
            width: 16,
            borderRadius: BorderRadius.zero,
            rodStackItems: [],
          ),
        ],
      ),
    ];
  }

  double _getMaxY(PeriodStats currentStats, PeriodStats previousStats) {
    final maxCurrent = [
      currentStats.totalXp.toDouble(),
      currentStats.totalTasks.toDouble(),
      currentStats.averageXpPerDay.toDouble(),
    ].reduce(math.max);

    final maxPrevious = [
      previousStats.totalXp.toDouble(),
      previousStats.totalTasks.toDouble(),
      previousStats.averageXpPerDay.toDouble(),
    ].reduce(math.max);

    final max = math.max(maxCurrent, maxPrevious);
    return (max * 1.1).ceilToDouble(); // Add 10% padding
  }

  double _getHorizontalInterval(PeriodStats currentStats, PeriodStats previousStats) {
    final maxY = _getMaxY(currentStats, previousStats);
    if (maxY <= 100) return 20;
    if (maxY <= 500) return 100;
    if (maxY <= 1000) return 200;
    return 500;
  }

  Widget _buildBottomTitle(BuildContext context, double value, TitleMeta meta) {
    switch (value.toInt()) {
      case 0:
        return SideTitleWidget(
          meta: meta,
          space: 8,
          child: Text(
            'XP',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.7),
                ),
          ),
        );
      case 1:
        return SideTitleWidget(
          meta: meta,
          space: 8,
          child: Text(
            'Tasks',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.7),
                ),
          ),
        );
      case 2:
        return SideTitleWidget(
          meta: meta,
          space: 8,
          child: Text(
            'Avg XP',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.7),
                ),
          ),
        );
      case 3:
        return SideTitleWidget(
          meta: meta,
          space: 8,
          child: Text(
            'Streak',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.7),
                ),
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildLeftTitle(BuildContext context, double value, TitleMeta meta) =>
      SideTitleWidget(
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

  Widget _buildComparisonLegend(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 4),
              Text(
                'Current',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                color: Theme.of(context).colorScheme.secondary,
              ),
              const SizedBox(width: 4),
              Text(
                'Previous',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ],
      );

  String _getComparisonInsight(PeriodStats currentStats, PeriodStats previousStats) {
    if (previousStats.totalXp == 0) {
      return 'This is your first period of data!';
    }

    final xpChange = ((currentStats.totalXp - previousStats.totalXp) / previousStats.totalXp) * 100;
    
    if (xpChange > 10) {
      return 'Great improvement! ${xpChange.toStringAsFixed(1)}% more XP than last period.';
    } else if (xpChange > 0) {
      return 'Good progress! ${xpChange.toStringAsFixed(1)}% more XP than last period.';
    } else if (xpChange < -10) {
      return 'Productivity dip detected. ${(-xpChange).toStringAsFixed(1)}% less XP than last period.';
    } else if (xpChange < 0) {
      return 'Slight decrease in productivity. ${(-xpChange).toStringAsFixed(1)}% less XP than last period.';
    } else {
      return 'Consistent productivity maintained.';
    }
  }

  Color _getComparisonColor(int currentXp, int previousXp) {
    if (previousXp == 0) return Colors.blue;
    
    final change = ((currentXp - previousXp) / previousXp) * 100;
    
    if (change > 0) return Colors.green;
    if (change < 0) return Colors.red;
    return Colors.blue;
  }
}

/// Data class for period statistics
class PeriodStats {
  const PeriodStats({
    required this.totalXp,
    required this.totalTasks,
    required this.averageXpPerDay,
    required this.bestDayXp,
    required this.streakDays,
  });

  final int totalXp;
  final int totalTasks;
  final double averageXpPerDay;
  final int bestDayXp;
  final int streakDays;
}