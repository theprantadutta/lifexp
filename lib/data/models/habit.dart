import 'package:equatable/equatable.dart';

/// Represents a recurring habit that users can track for consistency
///
/// Habits are similar to tasks but focus on building consistent behaviors over time.
/// They track streaks, completion rates, and provide insights into user behavior patterns.
/// Unlike tasks, habits are typically recurring on a daily or specific schedule basis.
///
/// Habits can be categorized, have difficulty levels, and contribute to overall XP gains
/// when completed consistently.
class Habit extends Equatable {
  const Habit({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.category,
    required this.frequency,
    required this.difficulty,
    required this.isCompletedToday,
    required this.streakCount,
    required this.longestStreak,
    required this.completionRate,
    required this.totalCompletions,
    required this.createdAt,
    required this.updatedAt,
    this.reminderTime,
    this.lastCompletedDate,
  });

  /// Creates a new habit with default values
  factory Habit.create({
    required String id,
    required String userId,
    required String title,
    required HabitCategory category,
    required HabitFrequency frequency,
    String description = '',
    int? difficulty,
    DateTime? reminderTime,
  }) {
    final now = DateTime.now();
    final habitDifficulty = difficulty ?? 3; // Default medium difficulty

    return Habit(
      id: id,
      userId: userId,
      title: title,
      description: description,
      category: category,
      frequency: frequency,
      difficulty: habitDifficulty,
      isCompletedToday: false,
      streakCount: 0,
      longestStreak: 0,
      completionRate: 0.0,
      totalCompletions: 0,
      reminderTime: reminderTime,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Creates from JSON
  factory Habit.fromJson(Map<String, dynamic> json) => Habit(
        id: json['id'] as String,
        userId: json['userId'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        category: HabitCategory.values.byName(json['category'] as String),
        frequency: HabitFrequency.values.byName(json['frequency'] as String),
        difficulty: json['difficulty'] as int,
        isCompletedToday: json['isCompletedToday'] as bool,
        streakCount: json['streakCount'] as int,
        longestStreak: json['longestStreak'] as int,
        completionRate: (json['completionRate'] as num).toDouble(),
        totalCompletions: json['totalCompletions'] as int,
        reminderTime: json['reminderTime'] != null
            ? DateTime.parse(json['reminderTime'] as String)
            : null,
        lastCompletedDate: json['lastCompletedDate'] != null
            ? DateTime.parse(json['lastCompletedDate'] as String)
            : null,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );

  final String id;
  final String userId;
  final String title;
  final String description;
  final HabitCategory category;
  final HabitFrequency frequency;
  final int difficulty;
  final bool isCompletedToday;
  final int streakCount;
  final int longestStreak;
  final double completionRate;
  final int totalCompletions;
  final DateTime? reminderTime;
  final DateTime? lastCompletedDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Maximum difficulty level
  static const int maxDifficulty = 10;

  /// Minimum difficulty level
  static const int minDifficulty = 1;

  /// Maximum streak count
  static const int maxStreakCount = 9999;

  /// Grace period for maintaining streaks (in hours)
  static const int streakGracePeriodHours = 6;

  /// Validates habit data
  bool get isValid =>
      _validateTitle() &&
      _validateDescription() &&
      _validateDifficulty() &&
      _validateStreakData() &&
      _validateDates();

  /// Validates habit title
  bool _validateTitle() => title.isNotEmpty && title.length <= 100;

  /// Validates habit description
  bool _validateDescription() => description.length <= 500;

  /// Validates difficulty bounds
  bool _validateDifficulty() =>
      difficulty >= minDifficulty && difficulty <= maxDifficulty;

  /// Validates streak data consistency
  bool _validateStreakData() =>
      streakCount >= 0 &&
      longestStreak >= 0 &&
      streakCount <= longestStreak &&
      completionRate >= 0.0 &&
      completionRate <= 1.0 &&
      totalCompletions >= 0;

  /// Validates date consistency
  bool _validateDates() {
    if (lastCompletedDate != null && !isCompletedToday) {
      return false;
    }
    return true;
  }

  /// Marks the habit as completed for today and updates streak
  Habit complete() {
    if (isCompletedToday) {
      return this;
    }

    final now = DateTime.now();
    final newStreakCount = _calculateNewStreakCount(now);
    final newLongestStreak =
        newStreakCount > longestStreak ? newStreakCount : longestStreak;
    final newTotalCompletions = totalCompletions + 1;
    // In a real implementation, this would be calculated based on actual history
    final newCompletionRate = ((completionRate * totalCompletions) + 1) /
        (totalCompletions + 1);

    return copyWith(
      isCompletedToday: true,
      streakCount: newStreakCount,
      longestStreak: newLongestStreak,
      totalCompletions: newTotalCompletions,
      completionRate: newCompletionRate,
      lastCompletedDate: now,
      updatedAt: now,
    );
  }

  /// Calculates new streak count based on completion timing
  int _calculateNewStreakCount(DateTime completionDate) {
    if (lastCompletedDate == null) {
      return 1; // First completion
    }

    final daysSinceLastCompletion = completionDate
        .difference(lastCompletedDate!)
        .inDays;

    // For habits, we're more lenient with streaks
    // if completed within 1 day + grace period
    if (daysSinceLastCompletion <= 1) {
      return streakCount + 1;
    } else if (daysSinceLastCompletion == 2 &&
        _isWithinGracePeriod(completionDate)) {
      return streakCount + 1;
    } else {
      return 1; // Streak broken, start over
    }
  }

  /// Checks if completion is within grace period
  bool _isWithinGracePeriod(DateTime completionDate) {
    if (lastCompletedDate == null) {
      return false;
    }

    final hoursSinceLastCompletion = completionDate
        .difference(lastCompletedDate!)
        .inHours;

    return hoursSinceLastCompletion <= 24 + streakGracePeriodHours;
  }

  /// Resets habit to incomplete state (for new day)
  Habit resetForNewDay() {
    if (!isCompletedToday) {
      return this;
    }

    return copyWith(
      isCompletedToday: false,
      updatedAt: DateTime.now(),
    );
  }

  /// Updates habit difficulty and recalculates any related values
  Habit updateDifficulty(int newDifficulty) {
    if (newDifficulty < minDifficulty || newDifficulty > maxDifficulty) {
      return this;
    }

    return copyWith(
      difficulty: newDifficulty,
      updatedAt: DateTime.now(),
    );
  }

  /// Updates reminder time
  Habit updateReminderTime(DateTime? newReminderTime) => copyWith(
        reminderTime: newReminderTime,
        updatedAt: DateTime.now(),
      );

  /// Gets XP reward for completing this habit
  int get xpReward {
    // Base XP based on difficulty
    final baseXP = difficulty * 10;

    // Streak bonus: +5% per streak level, capped at 50%
    final streakBonus = (streakCount * 0.05).clamp(0.0, 0.5);
    return (baseXP * (1 + streakBonus)).round();
  }

  /// Gets attribute type that this habit primarily affects
  AttributeType get primaryAttribute {
    switch (category) {
      case HabitCategory.health:
        return AttributeType.strength;
      case HabitCategory.fitness:
        return AttributeType.strength;
      case HabitCategory.mindfulness:
        return AttributeType.wisdom;
      case HabitCategory.learning:
        return AttributeType.intelligence;
      case HabitCategory.creative:
        return AttributeType.intelligence;
      case HabitCategory.social:
        return AttributeType.wisdom;
      case HabitCategory.productivity:
        return AttributeType.intelligence;
      case HabitCategory.custom:
        // Default to intelligence for custom habits
        return AttributeType.intelligence;
    }
  }

  /// Creates a copy with updated fields
  Habit copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    HabitCategory? category,
    HabitFrequency? frequency,
    int? difficulty,
    bool? isCompletedToday,
    int? streakCount,
    int? longestStreak,
    double? completionRate,
    int? totalCompletions,
    DateTime? reminderTime,
    DateTime? lastCompletedDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      Habit(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        title: title ?? this.title,
        description: description ?? this.description,
        category: category ?? this.category,
        frequency: frequency ?? this.frequency,
        difficulty: difficulty ?? this.difficulty,
        isCompletedToday: isCompletedToday ?? this.isCompletedToday,
        streakCount: streakCount ?? this.streakCount,
        longestStreak: longestStreak ?? this.longestStreak,
        completionRate: completionRate ?? this.completionRate,
        totalCompletions: totalCompletions ?? this.totalCompletions,
        reminderTime: reminderTime ?? this.reminderTime,
        lastCompletedDate: lastCompletedDate ?? this.lastCompletedDate,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  /// Converts to JSON
  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'title': title,
        'description': description,
        'category': category.name,
        'frequency': frequency.name,
        'difficulty': difficulty,
        'isCompletedToday': isCompletedToday,
        'streakCount': streakCount,
        'longestStreak': longestStreak,
        'completionRate': completionRate,
        'totalCompletions': totalCompletions,
        'reminderTime': reminderTime?.toIso8601String(),
        'lastCompletedDate': lastCompletedDate?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  /// Converts to Map (alias for toJson for repository compatibility)
  Map<String, dynamic> toMap() => toJson();

  @override
  List<Object?> get props => [
        id,
        userId,
        title,
        description,
        category,
        frequency,
        difficulty,
        isCompletedToday,
        streakCount,
        longestStreak,
        completionRate,
        totalCompletions,
        reminderTime,
        lastCompletedDate,
        createdAt,
        updatedAt,
      ];

  @override
  String toString() =>
      'Habit(id: $id, title: $title, category: $category, '
      'frequency: $frequency, difficulty: $difficulty, '
      'streak: $streakCount, longestStreak: $longestStreak, '
      'completedToday: $isCompletedToday)';
}

/// Enum for habit categories
enum HabitCategory {
  health,
  fitness,
  mindfulness,
  learning,
  creative,
  social,
  productivity,
  custom,
}

/// Extension to get display names for habit categories
extension HabitCategoryExtension on HabitCategory {
  String get displayName {
    switch (this) {
      case HabitCategory.health:
        return 'Health';
      case HabitCategory.fitness:
        return 'Fitness';
      case HabitCategory.mindfulness:
        return 'Mindfulness';
      case HabitCategory.learning:
        return 'Learning';
      case HabitCategory.creative:
        return 'Creative';
      case HabitCategory.social:
        return 'Social';
      case HabitCategory.productivity:
        return 'Productivity';
      case HabitCategory.custom:
        return 'Custom';
    }
  }

  String get icon {
    switch (this) {
      case HabitCategory.health:
        return '💪';
      case HabitCategory.fitness:
        return '🏃';
      case HabitCategory.mindfulness:
        return '🧘';
      case HabitCategory.learning:
        return '📚';
      case HabitCategory.creative:
        return '🎨';
      case HabitCategory.social:
        return '👥';
      case HabitCategory.productivity:
        return '📈';
      case HabitCategory.custom:
        return '⭐';
    }
  }
}

/// Enum for habit frequency
enum HabitFrequency {
  daily,
  weekly,
  weekdays,
  weekends,
  custom,
}

/// Extension to get display names for habit frequencies
extension HabitFrequencyExtension on HabitFrequency {
  String get displayName {
    switch (this) {
      case HabitFrequency.daily:
        return 'Daily';
      case HabitFrequency.weekly:
        return 'Weekly';
      case HabitFrequency.weekdays:
        return 'Weekdays';
      case HabitFrequency.weekends:
        return 'Weekends';
      case HabitFrequency.custom:
        return 'Custom';
    }
  }
}

/// Import AttributeType from avatar.dart to avoid circular dependency
enum AttributeType { strength, wisdom, intelligence }