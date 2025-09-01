import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../data/models/progress.dart';

/// Widget for displaying productivity patterns using a radar chart
class ProductivityPatternsChart extends StatelessWidget {
  const ProductivityPatternsChart({
    required this.progressEntries,
    super.key,
  });

  final List<ProgressEntry> progressEntries;

  @override
  Widget build(BuildContext context) {
    if (progressEntries.isEmpty) {
      return _buildEmptyChart(context);
    }

    final patternData = _calculatePatternData();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Productivity Patterns',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Text(
              _getPatternInsight(patternData),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
              child: RadarChart(
                RadarChartData(
                  dataSets: [
                    RadarDataSet(
                      dataEntries: patternData.values
                          .map((value) => RadarEntry(value: value))
                          .toList(),
                      fillColor: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.3),
                      borderColor: Theme.of(context).colorScheme.primary,
                      borderWidth: 2,
                      entryRadius: 4,
                    ),
                  ],
                  radarShape: RadarShape.circle,
                  tickCount: 5,
                  ticksTextStyle: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.7),
                    fontSize: 10,
                  ),
                  tickBorderData: BorderSide(
                    color: Theme.of(context)
                        .colorScheme
                        .outline
                        .withValues(alpha: 0.3),
                  ),
                  getTitle: (index, angle) => RadarChartTitle(
                    text: _getTitleForIndex(index),
                  ),
                  titlePositionPercentageOffset: 0.1,
                ),
                duration: const Duration(milliseconds: 150),
                curve: Curves.linear,
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
                'Productivity Patterns',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 32),
              Icon(
                Icons.radar,
                size: 48,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'No pattern data available',
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

  Map<String, double> _calculatePatternData() {
    final patternData = <String, int>{};

    // Initialize all pattern categories
    final categories = [
      'Morning',
      'Afternoon',
      'Evening',
      'Weekdays',
      'Weekends',
      'Short Tasks',
      'Long Tasks',
      'Easy Tasks',
      'Hard Tasks'
    ];

    for (final category in categories) {
      patternData[category] = 0;
    }

    // Calculate patterns based on progress entries
    for (final entry in progressEntries) {
      // Time of day patterns
      if (entry.date.hour >= 6 && entry.date.hour < 12) {
        patternData['Morning'] = patternData['Morning']! + entry.xpGained;
      } else if (entry.date.hour >= 12 && entry.date.hour < 18) {
        patternData['Afternoon'] = patternData['Afternoon']! + entry.xpGained;
      } else {
        patternData['Evening'] = patternData['Evening']! + entry.xpGained;
      }

      // Day of week patterns
      if (entry.date.weekday <= 5) {
        // Monday to Friday
        patternData['Weekdays'] = patternData['Weekdays']! + entry.xpGained;
      } else {
        // Saturday and Sunday
        patternData['Weekends'] = patternData['Weekends']! + entry.xpGained;
      }

      // Task duration patterns (assuming average task duration)
      if (entry.tasksCompleted > 0) {
        final avgXpPerTask = entry.xpGained / entry.tasksCompleted;
        if (avgXpPerTask < 30) {
          patternData['Short Tasks'] = patternData['Short Tasks']! + entry.xpGained;
        } else if (avgXpPerTask > 70) {
          patternData['Long Tasks'] = patternData['Long Tasks']! + entry.xpGained;
        } else {
          patternData['Easy Tasks'] = patternData['Easy Tasks']! + entry.xpGained;
        }
      }

      // Task difficulty patterns (based on XP per task)
      if (entry.tasksCompleted > 0) {
        final avgXpPerTask = entry.xpGained / entry.tasksCompleted;
        if (avgXpPerTask < 20) {
          patternData['Easy Tasks'] = patternData['Easy Tasks']! + entry.xpGained;
        } else if (avgXpPerTask > 60) {
          patternData['Hard Tasks'] = patternData['Hard Tasks']! + entry.xpGained;
        }
      }
    }

    // Normalize data to 0-100 scale for radar chart
    final maxValue = patternData.values.fold<int>(
        0, (max, value) => value > max ? value : max);

    if (maxValue == 0) {
      return {
        'Morning': 0.0,
        'Afternoon': 0.0,
        'Evening': 0.0,
        'Weekdays': 0.0,
        'Weekends': 0.0,
        'Short Tasks': 0.0,
        'Long Tasks': 0.0,
        'Easy Tasks': 0.0,
        'Hard Tasks': 0.0,
      };
    }

    return patternData.map((key, value) => MapEntry(key, (value / maxValue) * 100));
  }

  String _getTitleForIndex(int index) {
    switch (index) {
      case 0:
        return 'Morning';
      case 1:
        return 'Afternoon';
      case 2:
        return 'Evening';
      case 3:
        return 'Weekdays';
      case 4:
        return 'Weekends';
      case 5:
        return 'Short';
      case 6:
        return 'Long';
      case 7:
        return 'Easy';
      case 8:
        return 'Hard';
      default:
        return '';
    }
  }

  String _getPatternInsight(Map<String, double> patternData) {
    // Find the strongest pattern
    var maxKey = '';
    var maxValue = 0.0;

    patternData.forEach((key, value) {
      if (value > maxValue) {
        maxValue = value;
        maxKey = key;
      }
    });

    if (maxValue == 0) {
      return 'No clear productivity patterns detected yet.';
    }

    switch (maxKey) {
      case 'Morning':
        return 'You are most productive in the morning!';
      case 'Afternoon':
        return 'You hit your peak productivity in the afternoon.';
      case 'Evening':
        return 'You are a night owl with evening productivity peaks.';
      case 'Weekdays':
        return 'You are more productive on weekdays.';
      case 'Weekends':
        return 'You are more productive on weekends.';
      case 'Short Tasks':
        return 'You excel at completing short, quick tasks.';
      case 'Long Tasks':
        return 'You have strong focus for long, complex tasks.';
      case 'Easy Tasks':
        return 'You consistently complete easy tasks.';
      case 'Hard Tasks':
        return 'You tackle challenging tasks with determination.';
      default:
        return 'You have consistent productivity patterns.';
    }
  }
}