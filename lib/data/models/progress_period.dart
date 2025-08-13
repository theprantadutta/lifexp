/// Enum representing different time periods for progress tracking
enum ProgressPeriod {
  day,
  week,
  month,
  year,
}

/// Extension to provide display names for progress periods
extension ProgressPeriodExtension on ProgressPeriod {
  String get displayName {
    switch (this) {
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

  String get shortName {
    switch (this) {
      case ProgressPeriod.day:
        return 'Day';
      case ProgressPeriod.week:
        return 'Week';
      case ProgressPeriod.month:
        return 'Month';
      case ProgressPeriod.year:
        return 'Year';
    }
  }
}