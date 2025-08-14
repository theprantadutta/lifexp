import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../services/accessibility_service.dart';

/// Accessible line chart with comprehensive screen reader support
class AccessibleLineChart extends StatelessWidget {

  const AccessibleLineChart({
    required this.spots, required this.title, required this.xAxisLabel, required this.yAxisLabel, super.key,
    this.lineColor,
    this.showGrid = true,
    this.showTooltips = true,
    this.minY,
    this.maxY,
    this.xLabels,
  });
  final List<FlSpot> spots;
  final String title;
  final String xAxisLabel;
  final String yAxisLabel;
  final Color? lineColor;
  final bool showGrid;
  final bool showTooltips;
  final double? minY;
  final double? maxY;
  final List<String>? xLabels;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accessibilityService = AccessibilityService();
    
    final values = spots.map((spot) => spot.y).toList();
    final chartLabel = accessibilityService.createChartLabel(
      chartType: 'Line chart',
      timeRange: title,
      values: values,
    );
    
    return Semantics(
      label: chartLabel,
      hint: 'Chart showing $yAxisLabel over $xAxisLabel',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Chart title
          Semantics(
            header: true,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          
          // Chart container
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: showGrid),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      axisNameWidget: Semantics(
                        label: 'Y axis: $yAxisLabel',
                        child: Text(
                          yAxisLabel,
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) => Semantics(
                            label: 'Y value: ${value.toInt()}',
                            child: Text(
                              value.toInt().toString(),
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      axisNameWidget: Semantics(
                        label: 'X axis: $xAxisLabel',
                        child: Text(
                          xAxisLabel,
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (xLabels != null && index >= 0 && index < xLabels!.length) {
                            return Semantics(
                              label: 'X value: ${xLabels![index]}',
                              child: Text(
                                xLabels![index],
                                style: theme.textTheme.bodySmall,
                              ),
                            );
                          }
                          return Semantics(
                            label: 'X value: ${value.toInt()}',
                            child: Text(
                              value.toInt().toString(),
                              style: theme.textTheme.bodySmall,
                            ),
                          );
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(),
                    topTitles: const AxisTitles(),
                  ),
                  borderData: FlBorderData(show: true),
                  minY: minY,
                  maxY: maxY,
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: lineColor ?? theme.colorScheme.primary,
                      barWidth: 3,
                      belowBarData: BarAreaData(
                        show: true,
                        color: (lineColor ?? theme.colorScheme.primary).withValues(alpha: 0.1),
                      ),
                    ),
                  ],
                  lineTouchData: showTooltips
                      ? LineTouchData(
                          touchTooltipData: LineTouchTooltipData(
                            getTooltipItems: (touchedSpots) => touchedSpots.map((spot) {
                                final xValue = xLabels != null && spot.x.toInt() < xLabels!.length
                                    ? xLabels![spot.x.toInt()]
                                    : spot.x.toInt().toString();
                                return LineTooltipItem(
                                  '$xValue: ${spot.y.toInt()}',
                                  theme.textTheme.bodySmall!,
                                );
                              }).toList(),
                          ),
                        )
                      : const LineTouchData(enabled: false),
                ),
              ),
            ),
          ),
          
          // Data summary for screen readers
          Semantics(
            label: _createDataSummary(values),
            child: const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  String _createDataSummary(List<double> values) {
    if (values.isEmpty) return 'No data points';
    
    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);
    final avg = values.reduce((a, b) => a + b) / values.length;
    
    return 'Data summary: ${values.length} points, minimum ${min.toInt()}, maximum ${max.toInt()}, average ${avg.toInt()}';
  }
}

/// Accessible bar chart with comprehensive screen reader support
class AccessibleBarChart extends StatelessWidget {

  const AccessibleBarChart({
    required this.barGroups, required this.title, required this.xAxisLabel, required this.yAxisLabel, super.key,
    this.xLabels,
    this.barColor,
    this.showGrid = true,
    this.maxY,
  });
  final List<BarChartGroupData> barGroups;
  final String title;
  final String xAxisLabel;
  final String yAxisLabel;
  final List<String>? xLabels;
  final Color? barColor;
  final bool showGrid;
  final double? maxY;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accessibilityService = AccessibilityService();
    
    final values = barGroups.map((group) => 
        group.barRods.isNotEmpty ? group.barRods.first.toY : 0.0).toList();
    
    final chartLabel = accessibilityService.createChartLabel(
      chartType: 'Bar chart',
      timeRange: title,
      values: values,
    );
    
    return Semantics(
      label: chartLabel,
      hint: 'Bar chart showing $yAxisLabel by $xAxisLabel',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Chart title
          Semantics(
            header: true,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          
          // Chart container
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: BarChart(
                BarChartData(
                  gridData: FlGridData(show: showGrid),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      axisNameWidget: Semantics(
                        label: 'Y axis: $yAxisLabel',
                        child: Text(
                          yAxisLabel,
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) => Semantics(
                            label: 'Y value: ${value.toInt()}',
                            child: Text(
                              value.toInt().toString(),
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      axisNameWidget: Semantics(
                        label: 'X axis: $xAxisLabel',
                        child: Text(
                          xAxisLabel,
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (xLabels != null && index >= 0 && index < xLabels!.length) {
                            return Semantics(
                              label: 'Category: ${xLabels![index]}',
                              child: Text(
                                xLabels![index],
                                style: theme.textTheme.bodySmall,
                              ),
                            );
                          }
                          return Semantics(
                            label: 'Category: ${value.toInt()}',
                            child: Text(
                              value.toInt().toString(),
                              style: theme.textTheme.bodySmall,
                            ),
                          );
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(),
                    topTitles: const AxisTitles(),
                  ),
                  borderData: FlBorderData(show: true),
                  maxY: maxY,
                  barGroups: barGroups.asMap().entries.map((entry) {
                    final index = entry.key;
                    final group = entry.value;
                    
                    return BarChartGroupData(
                      x: group.x,
                      barRods: group.barRods.map((rod) {
                        final categoryName = xLabels != null && index < xLabels!.length
                            ? xLabels![index]
                            : 'Category ${index + 1}';
                        
                        return BarChartRodData(
                          toY: rod.toY,
                          color: barColor ?? theme.colorScheme.primary,
                          width: rod.width,
                          borderRadius: rod.borderRadius,
                        );
                      }).toList(),
                    );
                  }).toList(),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final categoryName = xLabels != null && groupIndex < xLabels!.length
                            ? xLabels![groupIndex]
                            : 'Category ${groupIndex + 1}';
                        return BarTooltipItem(
                          '$categoryName: ${rod.toY.toInt()}',
                          theme.textTheme.bodySmall!,
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // Data summary for screen readers
          Semantics(
            label: _createBarDataSummary(values, xLabels),
            child: const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  String _createBarDataSummary(List<double> values, List<String>? labels) {
    if (values.isEmpty) return 'No data bars';
    
    final buffer = StringBuffer('Bar data: ');
    for (var i = 0; i < values.length; i++) {
      final label = labels != null && i < labels.length ? labels[i] : 'Bar ${i + 1}';
      buffer.write('$label: ${values[i].toInt()}');
      if (i < values.length - 1) buffer.write(', ');
    }
    
    return buffer.toString();
  }
}

/// Accessible pie chart with comprehensive screen reader support
class AccessiblePieChart extends StatelessWidget {

  const AccessiblePieChart({
    required this.sections, required this.title, super.key,
    this.showPercentages = true,
    this.centerSpaceRadius,
  });
  final List<PieChartSectionData> sections;
  final String title;
  final bool showPercentages;
  final double? centerSpaceRadius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accessibilityService = AccessibilityService();
    
    final total = sections.fold(0.0, (sum, section) => sum + section.value);
    final chartLabel = 'Pie chart: $title with ${sections.length} sections, total value: ${total.toInt()}';
    
    return Semantics(
      label: chartLabel,
      hint: 'Pie chart showing distribution of data',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Chart title
          Semantics(
            header: true,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          
          // Chart and legend
          Expanded(
            child: Row(
              children: [
                // Pie chart
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: PieChart(
                      PieChartData(
                        sections: sections,
                        centerSpaceRadius: centerSpaceRadius ?? 0,
                        sectionsSpace: 2,
                        pieTouchData: PieTouchData(
                          touchCallback: (event, response) {
                            if (response?.touchedSection != null) {
                              final section = response!.touchedSection!;
                              final sectionIndex = section.touchedSectionIndex;
                              if (sectionIndex >= 0 && sectionIndex < sections.length) {
                                final sectionData = sections[sectionIndex];
                                final percentage = ((sectionData.value / total) * 100).round();
                                accessibilityService.announce(
                                  '${sectionData.title}: ${sectionData.value.toInt()}, $percentage percent'
                                );
                              }
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                
                // Legend
                Expanded(
                  child: Semantics(
                    label: 'Chart legend',
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: sections.asMap().entries.map((entry) {
                        final index = entry.key;
                        final section = entry.value;
                        final percentage = ((section.value / total) * 100).round();
                        
                        return Semantics(
                          label: '${section.title}: ${section.value.toInt()}, $percentage percent',
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: section.color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        section.title ?? 'Section ${index + 1}',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      if (showPercentages)
                                        Text(
                                          '$percentage%',
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Data summary for screen readers
          Semantics(
            label: _createPieDataSummary(sections, total),
            child: const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  String _createPieDataSummary(List<PieChartSectionData> sections, double total) {
    final buffer = StringBuffer('Pie chart data: ');
    for (var i = 0; i < sections.length; i++) {
      final section = sections[i];
      final percentage = ((section.value / total) * 100).round();
      final title = section.title ?? 'Section ${i + 1}';
      buffer.write('$title: ${section.value.toInt()} ($percentage%)');
      if (i < sections.length - 1) buffer.write(', ');
    }
    return buffer.toString();
  }
}