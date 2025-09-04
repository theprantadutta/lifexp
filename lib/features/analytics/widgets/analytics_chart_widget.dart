import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../data/models/analytics_data.dart';

/// Widget to display analytics charts
class AnalyticsChartWidget extends StatelessWidget {
  const AnalyticsChartWidget({
    super.key,
    required this.title,
    required this.data,
  });

  final String title;
  final List<ChartData> data;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: _buildChart(),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the chart based on data type
  Widget _buildChart() {
    if (data.isEmpty) {
      return const Center(child: Text('No data available'));
    }

    // Check if this is a pie chart (category data) or line/bar chart (trend data)
    final isCategoryData = data.length <= 5 && data.every((d) => d.value < 100);

    if (isCategoryData) {
      return _buildPieChart();
    } else {
      return _buildBarChart();
    }
  }

  /// Builds a pie chart for category data
  Widget _buildPieChart() {
    return PieChart(
      PieChartData(
        sections: data
            .asMap()
            .map((index, d) => MapEntry(
                  index,
                  PieChartSectionData(
                    value: d.value,
                    title: '${d.value.toInt()}%',
                    color: _getColor(index),
                    showTitle: true,
                    radius: 50,
                  ),
                ))
            .values
            .toList(),
        centerSpaceRadius: 40,
        sectionsSpace: 2,
      ),
    );
  }

  /// Builds a bar chart for trend data
  Widget _buildBarChart() {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: data.map((d) => d.value).reduce((a, b) => a > b ? a : b) * 1.2,
        barTouchData: BarTouchData(enabled: true),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < data.length) {
                  return Text(
                    data[index].label,
                    style: const TextStyle(
                      fontSize: 10,
                    ),
                  );
                }
                return const Text('');
              },
              reservedSize: 30,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
            ),
          ),
          topTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: data
            .asMap()
            .map((index, d) => MapEntry(
                  index,
                  BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: d.value,
                        color: _getColor(index),
                        width: 16,
                        borderRadius: BorderRadius.zero,
                      ),
                    ],
                  ),
                ))
            .values
            .toList(),
      ),
    );
  }

  /// Gets a color for chart sections
  Color _getColor(int index) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.pink,
    ];
    return colors[index % colors.length];
  }
}