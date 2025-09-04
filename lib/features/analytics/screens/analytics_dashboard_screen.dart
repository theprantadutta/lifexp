import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/analytics_data.dart';
import '../../../shared/blocs/analytics/analytics_bloc.dart';
import '../../../shared/blocs/analytics/analytics_event.dart';
import '../../../shared/blocs/analytics/analytics_state.dart';
import '../widgets/analytics_chart_widget.dart';
import '../widgets/metric_card_widget.dart';

/// Main screen for the analytics dashboard
class AnalyticsDashboardScreen extends StatefulWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  State<AnalyticsDashboardScreen> createState() =>
      _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen> {
  late AnalyticsBloc _analyticsBloc;
  final _userId = 'user123'; // In a real app, this would come from auth context

  @override
  void initState() {
    super.initState();
    _analyticsBloc = context.read<AnalyticsBloc>();
    _loadAnalyticsData();
  }

  void _loadAnalyticsData() {
    _analyticsBloc.add(LoadAnalyticsData(userId: _userId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnalyticsData,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showDashboardSettings,
          ),
        ],
      ),
      body: BlocBuilder<AnalyticsBloc, AnalyticsState>(
        builder: (context, state) {
          if (state is AnalyticsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is AnalyticsError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${state.message}'),
                  ElevatedButton(
                    onPressed: _loadAnalyticsData,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is AnalyticsLoaded) {
            return _buildDashboard(state.analyticsData);
          }

          return const Center(child: Text('No analytics data available'));
        },
      ),
    );
  }

  /// Builds the dashboard with analytics data
  Widget _buildDashboard(AnalyticsData data) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary metrics
          const Text(
            'Summary',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              MetricCardWidget(
                title: 'Total XP',
                value: data.totalXp.toString(),
                icon: Icons.star,
                color: Colors.amber,
              ),
              MetricCardWidget(
                title: 'Level',
                value: data.currentLevel.toString(),
                icon: Icons.trending_up,
                color: Colors.blue,
              ),
              MetricCardWidget(
                title: 'Habits',
                value: data.totalHabits.toString(),
                icon: Icons.check_circle,
                color: Colors.green,
              ),
              MetricCardWidget(
                title: 'Goals',
                value: data.completedGoals.toString(),
                icon: Icons.flag,
                color: Colors.purple,
              ),
            ],
          ),
          const SizedBox(height: 32),
          
          // Charts section
          const Text(
            'Progress Over Time',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          AnalyticsChartWidget(
            title: 'XP Gain Over Time',
            data: data.xpTrend,
          ),
          const SizedBox(height: 24),
          AnalyticsChartWidget(
            title: 'Habit Completion Rate',
            data: data.habitCompletionTrend,
          ),
          const SizedBox(height: 24),
          AnalyticsChartWidget(
            title: 'Goal Completion Rate',
            data: data.goalCompletionTrend,
          ),
          const SizedBox(height: 32),
          
          // Category breakdown
          const Text(
            'Category Breakdown',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          AnalyticsChartWidget(
            title: 'Habits by Category',
            data: data.habitsByCategory,
          ),
          const SizedBox(height: 24),
          AnalyticsChartWidget(
            title: 'Goals by Category',
            data: data.goalsByCategory,
          ),
        ],
      ),
    );
  }

  /// Shows dashboard settings
  void _showDashboardSettings() {
    // TODO: Implement dashboard settings
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Dashboard settings coming soon')),
    );
  }
}