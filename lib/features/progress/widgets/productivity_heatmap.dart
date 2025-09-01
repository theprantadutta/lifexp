import 'package:flutter/material.dart';

import '../../../data/models/progress.dart';

/// Widget for displaying productivity data using a heatmap
class ProductivityHeatmap extends StatelessWidget {
  const ProductivityHeatmap({
    required this.progressEntries,
    super.key,
  });

  final List<ProgressEntry> progressEntries;

  @override
  Widget build(BuildContext context) {
    if (progressEntries.isEmpty) {
      return _buildEmptyHeatmap(context);
    }

    // Group entries by day of week and hour
    final productivityData = _calculateProductivityData();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Productivity Heatmap',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Text(
              'Most productive times (XP earned)',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.7),
                  ),
            ),
            const SizedBox(height: 16),
            _buildHeatmapGrid(context, productivityData),
            const SizedBox(height: 16),
            _buildLegend(context),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyHeatmap(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                'Productivity Heatmap',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 32),
              Icon(
                Icons.grid_on,
                size: 48,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'No productivity data available',
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

  Map<String, Map<int, int>> _calculateProductivityData() {
    final data = <String, Map<int, int>>{};
    
    // Initialize data structure
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    for (final day in days) {
      data[day] = {};
      for (var hour = 0; hour < 24; hour++) {
        data[day]![hour] = 0;
      }
    }
    
    // Populate with actual data
    for (final entry in progressEntries) {
      final dayOfWeek = _getDayOfWeek(entry.date.weekday);
      final hour = entry.date.hour;
      data[dayOfWeek]![hour] = (data[dayOfWeek]![hour] ?? 0) + entry.xpGained;
    }
    
    return data;
  }

  Widget _buildHeatmapGrid(BuildContext context, Map<String, Map<int, int>> data) {
    final maxValue = _getMaxValue(data);
    
    return Column(
      children: [
        // Hour labels
        Row(
          children: [
            const SizedBox(width: 40), // Space for day labels
            ...List.generate(24, (hour) {
              return Expanded(
                child: Text(
                  hour.toString(),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.7),
                      ),
                ),
              );
            }),
          ],
        ),
        const SizedBox(height: 8),
        // Data grid
        ...data.entries.map((dayEntry) {
          final day = dayEntry.key;
          final hoursData = dayEntry.value;
          
          return Row(
            children: [
              SizedBox(
                width: 40,
                child: Text(
                  day,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.7),
                      ),
                ),
              ),
              ...List.generate(24, (hour) {
                final value = hoursData[hour] ?? 0;
                final intensity = maxValue > 0 ? value.toDouble() / maxValue : 0.0;
                final color = _getColorForIntensity(context, intensity);
                
                return Expanded(
                  child: Container(
                    height: 20,
                    margin: const EdgeInsets.all(1),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: value > 0
                        ? Tooltip(
                            message: '$day $hour:00\n$value XP',
                            child: Container(),
                          )
                        : null,
                  ),
                );
              }),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildLegend(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Low',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.7),
              ),
        ),
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: _getColorForIntensity(context, 0.2),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: _getColorForIntensity(context, 0.5),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: _getColorForIntensity(context, 0.8),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Text(
          'High',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.7),
              ),
        ),
      ],
    );
  }

  int _getMaxValue(Map<String, Map<int, int>> data) {
    var max = 0;
    for (final dayData in data.values) {
      for (final value in dayData.values) {
        if (value > max) max = value;
      }
    }
    return max;
  }

  Color _getColorForIntensity(BuildContext context, double intensity) {
    if (intensity <= 0) {
      return Theme.of(context).colorScheme.surfaceContainerHighest;
    } else if (intensity <= 0.25) {
      return Theme.of(context).colorScheme.primary.withValues(alpha: 0.3);
    } else if (intensity <= 0.5) {
      return Theme.of(context).colorScheme.primary.withValues(alpha: 0.5);
    } else if (intensity <= 0.75) {
      return Theme.of(context).colorScheme.primary.withValues(alpha: 0.7);
    } else {
      return Theme.of(context).colorScheme.primary;
    }
  }

  String _getDayOfWeek(int weekday) {
    switch (weekday) {
      case 1: return 'Mon';
      case 2: return 'Tue';
      case 3: return 'Wed';
      case 4: return 'Thu';
      case 5: return 'Fri';
      case 6: return 'Sat';
      case 7: return 'Sun';
      default: return '';
    }
  }
}