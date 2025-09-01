import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../data/models/progress.dart';
import '../../../data/models/progress_period.dart';

/// Widget for displaying trend analysis using a line chart with trend indicators
class TrendAnalysisChart extends StatelessWidget {
  const TrendAnalysisChart({
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

    final trendData = _calculateTrendData();
    final (trendLine, rSquared) = _calculateTrendLine(trendData);

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
                  'Trend Analysis',
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
            Text(
              'Productivity Trend: ${_getTrendDescription(rSquared)}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: _getTrendColor(rSquared),
                    fontWeight: FontWeight.w500,
                  ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    horizontalInterval: _getHorizontalInterval(trendData),
                    verticalInterval: _getVerticalInterval(trendData),
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
                        interval: _getBottomTitleInterval(trendData),
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
                        interval: _getLeftTitleInterval(trendData),
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
                  maxX: (trendData.length - 1).toDouble(),
                  minY: 0,
                  maxY: _getMaxY(trendData),
                  lineBarsData: [
                    // Actual data line
                    LineChartBarData(
                      spots: _buildActualSpots(trendData),
                      isCurved: true,
                      color: Theme.of(context).colorScheme.primary,
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
                    ),
                    // Trend line
                    LineChartBarData(
                      spots: _buildTrendSpots(trendData, trendLine),
                      isCurved: false,
                      color: _getTrendColor(rSquared),
                      barWidth: 2,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
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
            const SizedBox(height: 16),
            _buildTrendLegend(context, rSquared),
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
                'Trend Analysis',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 32),
              Icon(
                Icons.trending_up,
                size: 48,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'No trend data available',
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

  List<(DateTime, int)> _calculateTrendData() {
    final trendData = <(DateTime, int)>[];

    for (final entry in progressEntries) {
      trendData.add((entry.date, entry.xpGained));
    }

    return trendData;
  }

  (List<double>, double) _calculateTrendLine(List<(DateTime, int)> data) {
    if (data.isEmpty) return (<double>[], 0.0);

    // Simple linear regression
    final n = data.length.toDouble();
    var sumX = 0.0;
    var sumY = 0.0;
    var sumXY = 0.0;
    var sumXX = 0.0;

    for (var i = 0; i < data.length; i++) {
      final x = i.toDouble();
      final y = data[i].$2.toDouble();
      sumX += x;
      sumY += y;
      sumXY += x * y;
      sumXX += x * x;
    }

    final slope = (n * sumXY - sumX * sumY) / (n * sumXX - sumX * sumX);
    final intercept = (sumY - slope * sumX) / n;

    // Calculate R-squared (coefficient of determination)
    var ssTot = 0.0; // Total sum of squares
    var ssRes = 0.0; // Residual sum of squares
    final meanY = sumY / n;

    for (var i = 0; i < data.length; i++) {
      final y = data[i].$2.toDouble();
      final yPred = slope * i + intercept;
      ssTot += (y - meanY) * (y - meanY);
      ssRes += (y - yPred) * (y - yPred);
    }

    final rSquared = 1.0 - (ssRes / ssTot);

    return ([slope, intercept], rSquared);
  }

  List<FlSpot> _buildActualSpots(List<(DateTime, int)> data) {
    final spots = <FlSpot>[];

    for (var i = 0; i < data.length; i++) {
      spots.add(FlSpot(i.toDouble(), data[i].$2.toDouble()));
    }

    return spots;
  }

  List<FlSpot> _buildTrendSpots(
      List<(DateTime, int)> data, List<double> trendLine) {
    if (trendLine.length < 2) return [];

    final spots = <FlSpot>[];
    final slope = trendLine[0];
    final intercept = trendLine[1];

    for (var i = 0; i < data.length; i++) {
      final y = slope * i + intercept;
      spots.add(FlSpot(i.toDouble(), y));
    }

    return spots;
  }

  double _getMaxY(List<(DateTime, int)> data) {
    if (data.isEmpty) return 100;

    var maxY = 0;
    for (final entry in data) {
      if (entry.$2 > maxY) {
        maxY = entry.$2;
      }
    }

    // Add some padding to the top
    return (maxY * 1.2).ceilToDouble();
  }

  double _getHorizontalInterval(List<(DateTime, int)> data) {
    final maxY = _getMaxY(data);
    if (maxY <= 100) return 20;
    if (maxY <= 500) return 100;
    if (maxY <= 1000) return 200;
    return 500;
  }

  double _getVerticalInterval(List<(DateTime, int)> data) {
    final length = data.length;
    if (length <= 7) return 1;
    if (length <= 14) return 2;
    if (length <= 30) return 5;
    return 10;
  }

  double _getBottomTitleInterval(List<(DateTime, int)> data) =>
      _getVerticalInterval(data);

  double _getLeftTitleInterval(List<(DateTime, int)> data) =>
      _getHorizontalInterval(data);

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

  Widget _buildTrendLegend(BuildContext context, double rSquared) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 3,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 4),
              Text(
                'Actual',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          Row(
            children: [
              Container(
                width: 12,
                height: 2,
                color: _getTrendColor(rSquared),
              ),
              const SizedBox(width: 4),
              Text(
                'Trend',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          Text(
            'R²: ${rSquared.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
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

  String _getTrendDescription(double rSquared) {
    if (rSquared >= 0.7) return 'Strong';
    if (rSquared >= 0.4) return 'Moderate';
    if (rSquared >= 0.2) return 'Weak';
    return 'Very Weak';
  }

  Color _getTrendColor(double rSquared) {
    if (rSquared >= 0.7) return Colors.green;
    if (rSquared >= 0.4) return Colors.orange;
    return Colors.red;
  }
}