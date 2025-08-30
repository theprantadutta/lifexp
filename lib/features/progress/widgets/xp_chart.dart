import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../data/models/progress.dart';
import '../../../data/models/progress_period.dart';

/// Widget for displaying XP progress over time using a line chart
class XPChart extends StatelessWidget {
  const XPChart({
    required this.progressEntries,
    required this.period,
    super.key,
  });

  final List<ProgressEntry> progressEntries;
  final ProgressPeriod period;

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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'XP Over Time',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(
                  _getPeriodLabel(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    horizontalInterval: _getHorizontalInterval(),
                    verticalInterval: _getVerticalInterval(),
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Theme.of(context)
                          .colorScheme
                          .outline
                          .withValues(alpha: 0.3),
                      strokeWidth: 1,
                    ),
                    getDrawingVerticalLine: (value) => FlLine(
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
                        reservedSize: 30,
                        interval: _getBottomTitleInterval(),
                        getTitlesWidget: (value, meta) => _buildBottomTitle(
                          context,
                          value,
                          meta,
                        ),
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: _getLeftTitleInterval(),
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
                  minX: 0,
                  maxX: (progressEntries.length - 1).toDouble(),
                  minY: 0,
                  maxY: _getMaxY(),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _buildSpots(),
                      isCurved: true,
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.secondary,
                        ],
                      ),
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        getDotPainter: (spot, percent, barData, index) =>
                            FlDotCirclePainter(
                          radius: 4,
                          color: Theme.of(context).colorScheme.primary,
                          strokeWidth: 2,
                          strokeColor: Theme.of(context).colorScheme.surface,
                        ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.3),
                            Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.1),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (touchedSpot) => Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest,
                      getTooltipItems: (touchedSpots) => touchedSpots
                          .map((spot) => LineTooltipItem(
                                '${spot.y.toInt()} XP',
                                TextStyle(
                                  color: Theme.of(context).colorScheme.onSurface,
                                  fontWeight: FontWeight.bold,
                                ),
                              ))
                          .toList(),
                    ),
                  ),
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
                'XP Over Time',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 32),
              Icon(
                Icons.show_chart,
                size: 48,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'No XP data available',
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

  List<FlSpot> _buildSpots() {
    final spots = <FlSpot>[];
    var cumulativeXp = 0;

    for (var i = 0; i < progressEntries.length; i++) {
      cumulativeXp += progressEntries[i].xpGained;
      spots.add(FlSpot(i.toDouble(), cumulativeXp.toDouble()));
    }

    return spots;
  }

  double _getMaxY() {
    if (progressEntries.isEmpty) return 100;

    var maxXp = 0;
    var cumulativeXp = 0;

    for (final entry in progressEntries) {
      cumulativeXp += entry.xpGained;
      if (cumulativeXp > maxXp) {
        maxXp = cumulativeXp;
      }
    }

    // Add some padding to the top
    return (maxXp * 1.1).ceilToDouble();
  }

  double _getHorizontalInterval() {
    final maxY = _getMaxY();
    if (maxY <= 100) return 20;
    if (maxY <= 500) return 100;
    if (maxY <= 1000) return 200;
    return 500;
  }

  double _getVerticalInterval() {
    final length = progressEntries.length;
    if (length <= 7) return 1;
    if (length <= 14) return 2;
    if (length <= 30) return 5;
    return 10;
  }

  double _getBottomTitleInterval() => _getVerticalInterval();

  double _getLeftTitleInterval() => _getHorizontalInterval();

  Widget _buildBottomTitle(BuildContext context, double value, TitleMeta meta) {
    final index = value.toInt();
    if (index < 0 || index >= progressEntries.length) {
      return const SizedBox.shrink();
    }

    final entry = progressEntries[index];
    final date = entry.date;

    String text;
    switch (period) {
      case ProgressPeriod.day:
        text = '${date.hour}:00';
        break;
      case ProgressPeriod.week:
        text = _getDayAbbreviation(date.weekday);
        break;
      case ProgressPeriod.month:
        text = '${date.day}';
        break;
      case ProgressPeriod.year:
        text = '${date.month}';
        break;
    }

    return SideTitleWidget(
      meta: meta,
      space: 8,
      child: Text(
        text,
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

  String _getPeriodLabel() {
    switch (period) {
      case ProgressPeriod.day:
        return 'Today';
      case ProgressPeriod.week:
        return 'This Week';
      case ProgressPeriod.month:
        return 'This Month';
      case ProgressPeriod.year:
        return 'This Year';
    }
  }

  String _getDayAbbreviation(int weekday) {
    switch (weekday) {
      case 1:
        return 'Mon';
      case 2:
        return 'Tue';
      case 3:
        return 'Wed';
      case 4:
        return 'Thu';
      case 5:
        return 'Fri';
      case 6:
        return 'Sat';
      case 7:
        return 'Sun';
      default:
        return '';
    }
  }
}