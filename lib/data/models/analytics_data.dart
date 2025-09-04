/// Data model for analytics dashboard
class AnalyticsData {
  final int totalXp;
  final int currentLevel;
  final int totalHabits;
  final int completedGoals;
  final List<ChartData> xpTrend;
  final List<ChartData> habitCompletionTrend;
  final List<ChartData> goalCompletionTrend;
  final List<ChartData> habitsByCategory;
  final List<ChartData> goalsByCategory;

  AnalyticsData({
    required this.totalXp,
    required this.currentLevel,
    required this.totalHabits,
    required this.completedGoals,
    required this.xpTrend,
    required this.habitCompletionTrend,
    required this.goalCompletionTrend,
    required this.habitsByCategory,
    required this.goalsByCategory,
  });

  /// Creates a sample analytics data for demonstration
  factory AnalyticsData.sample() {
    return AnalyticsData(
      totalXp: 12500,
      currentLevel: 15,
      totalHabits: 24,
      completedGoals: 8,
      xpTrend: [
        ChartData('Mon', 150),
        ChartData('Tue', 200),
        ChartData('Wed', 180),
        ChartData('Thu', 220),
        ChartData('Fri', 190),
        ChartData('Sat', 250),
        ChartData('Sun', 210),
      ],
      habitCompletionTrend: [
        ChartData('Mon', 85),
        ChartData('Tue', 92),
        ChartData('Wed', 78),
        ChartData('Thu', 95),
        ChartData('Fri', 88),
        ChartData('Sat', 90),
        ChartData('Sun', 87),
      ],
      goalCompletionTrend: [
        ChartData('Week 1', 2),
        ChartData('Week 2', 3),
        ChartData('Week 3', 1),
        ChartData('Week 4', 4),
      ],
      habitsByCategory: [
        ChartData('Health', 8),
        ChartData('Fitness', 6),
        ChartData('Mindfulness', 4),
        ChartData('Learning', 3),
        ChartData('Other', 3),
      ],
      goalsByCategory: [
        ChartData('Career', 3),
        ChartData('Health', 2),
        ChartData('Learning', 2),
        ChartData('Personal', 1),
      ],
    );
  }
}

/// Data point for charts
class ChartData {
  final String label;
  final double value;

  ChartData(this.label, this.value);
}