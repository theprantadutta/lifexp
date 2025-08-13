import 'package:equatable/equatable.dart';

/// Represents a task that users can complete to gain XP
class Task extends Equatable {
  const Task({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.category,
    required this.xpReward,
    required this.difficulty,
    required this.isCompleted,
    required this.streakCount,
    required this.createdAt,
    required this.updatedAt,
    this.dueDate,
    this.lastCompletedDate,
  });

  /// Creates a new task with default values
  factory Task.create({
    required String id,
    required String title,
    required TaskType type,
    required TaskCategory category,
    String description = '',
    int? difficulty,
    DateTime? dueDate,
  }) {
    final now = DateTime.now();
    final taskDifficulty = difficulty ?? _calculateDefaultDifficulty(type);

    return Task(
      id: id,
      title: title,
      description: description,
      type: type,
      category: category,
      xpReward: _calculateXPReward(taskDifficulty, type),
      difficulty: taskDifficulty,
      dueDate: dueDate,
      isCompleted: false,
      streakCount: 0,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Creates from JSON
  factory Task.fromJson(Map<String, dynamic> json) => Task(
    id: json['id'] as String,
    title: json['title'] as String,
    description: json['description'] as String,
    type: TaskType.values.byName(json['type'] as String),
    category: TaskCategory.values.byName(json['category'] as String),
    xpReward: json['xpReward'] as int,
    difficulty: json['difficulty'] as int,
    dueDate: json['dueDate'] != null
        ? DateTime.parse(json['dueDate'] as String)
        : null,
    isCompleted: json['isCompleted'] as bool,
    streakCount: json['streakCount'] as int,
    lastCompletedDate: json['lastCompletedDate'] != null
        ? DateTime.parse(json['lastCompletedDate'] as String)
        : null,
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );
  final String id;
  final String title;
  final String description;
  final TaskType type;
  final TaskCategory category;
  final int xpReward;
  final int difficulty;
  final DateTime? dueDate;
  final bool isCompleted;
  final int streakCount;
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

  /// Calculates default difficulty based on task type
  static int _calculateDefaultDifficulty(TaskType type) {
    switch (type) {
      case TaskType.daily:
        return 3;
      case TaskType.weekly:
        return 5;
      case TaskType.longTerm:
        return 8;
    }
  }

  /// Calculates XP reward based on difficulty and type
  static int _calculateXPReward(int difficulty, TaskType type) {
    final baseXP = difficulty * 10;

    switch (type) {
      case TaskType.daily:
        return baseXP;
      case TaskType.weekly:
        return (baseXP * 1.5).round();
      case TaskType.longTerm:
        return baseXP * 2;
    }
  }

  /// Calculates XP reward with streak bonus
  int get xpRewardWithStreak {
    if (streakCount <= 1) {
      return xpReward;
    }

    // Streak bonus: +10% per streak level, capped at 100%
    final streakBonus = (streakCount * 0.1).clamp(0.0, 1.0);
    return (xpReward * (1 + streakBonus)).round();
  }

  /// Checks if task is overdue
  bool get isOverdue {
    if (dueDate == null || isCompleted) {
      return false;
    }
    return DateTime.now().isAfter(dueDate!);
  }

  /// Checks if task is due today
  bool get isDueToday {
    if (dueDate == null) {
      return false;
    }
    final now = DateTime.now();
    final due = dueDate!;
    return now.year == due.year && now.month == due.month && now.day == due.day;
  }

  /// Checks if task is due this week
  bool get isDueThisWeek {
    if (dueDate == null) {
      return false;
    }
    final now = DateTime.now();
    final startOfWeek = DateTime(
      now.year,
      now.month,
      now.day - now.weekday + 1,
    );
    final endOfWeek = startOfWeek.add(
      const Duration(days: 6, hours: 23, minutes: 59, seconds: 59),
    );
    return dueDate!.isAfter(startOfWeek.subtract(const Duration(seconds: 1))) &&
        dueDate!.isBefore(endOfWeek.add(const Duration(seconds: 1)));
  }

  /// Gets days until due date
  int? get daysUntilDue {
    if (dueDate == null) {
      return null;
    }
    final now = DateTime.now();
    final difference = dueDate!.difference(now).inDays;
    return difference;
  }

  /// Validates task data
  bool get isValid =>
      _validateTitle() &&
      _validateDescription() &&
      _validateDifficulty() &&
      _validateXPReward() &&
      _validateStreakCount() &&
      _validateDates();

  /// Validates task title
  bool _validateTitle() => title.isNotEmpty && title.length <= 100;

  /// Validates task description
  bool _validateDescription() => description.length <= 500;

  /// Validates difficulty bounds
  bool _validateDifficulty() =>
      difficulty >= minDifficulty && difficulty <= maxDifficulty;

  /// Validates XP reward is positive
  bool _validateXPReward() => xpReward > 0;

  /// Validates streak count bounds
  bool _validateStreakCount() =>
      streakCount >= 0 && streakCount <= maxStreakCount;

  /// Validates date consistency
  bool _validateDates() {
    if (lastCompletedDate != null && !isCompleted) {
      return false;
    }
    if (dueDate != null && dueDate!.isBefore(createdAt)) {
      return false;
    }
    return true;
  }

  /// Completes the task and updates streak
  Task complete() {
    if (isCompleted) {
      return this;
    }

    final now = DateTime.now();
    final newStreakCount = _calculateNewStreakCount(now);

    return copyWith(
      isCompleted: true,
      streakCount: newStreakCount,
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

    switch (type) {
      case TaskType.daily:
        // Daily tasks: streak continues
        // if completed within 1 day + grace period
        if (daysSinceLastCompletion <= 1) {
          return streakCount + 1;
        } else if (daysSinceLastCompletion == 2 &&
            _isWithinGracePeriod(completionDate)) {
          return streakCount + 1;
        } else {
          return 1; // Streak broken, start over
        }

      case TaskType.weekly:
        // Weekly tasks: streak continues
        // if completed within 7 days + grace period
        if (daysSinceLastCompletion <= 7) {
          return streakCount + 1;
        } else if (daysSinceLastCompletion <= 7 + 1 &&
            _isWithinGracePeriod(completionDate)) {
          return streakCount + 1;
        } else {
          return 1; // Streak broken, start over
        }

      case TaskType.longTerm:
        // Long-term tasks don't have streaks in the traditional sense
        return streakCount + 1;
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

    final maxHours = switch (type) {
      TaskType.daily => 24 + streakGracePeriodHours,
      TaskType.weekly => (7 * 24) + streakGracePeriodHours,
      TaskType.longTerm => double.infinity.toInt(),
    };

    return hoursSinceLastCompletion <= maxHours;
  }

  /// Resets task to incomplete state (for recurring tasks)
  Task reset() {
    if (!isCompleted) {
      return this;
    }

    return copyWith(isCompleted: false, updatedAt: DateTime.now());
  }

  /// Updates task difficulty and recalculates XP reward
  Task updateDifficulty(int newDifficulty) {
    if (newDifficulty < minDifficulty || newDifficulty > maxDifficulty) {
      return this;
    }

    final newXPReward = _calculateXPReward(newDifficulty, type);

    return copyWith(
      difficulty: newDifficulty,
      xpReward: newXPReward,
      updatedAt: DateTime.now(),
    );
  }

  /// Updates due date
  Task updateDueDate(DateTime? newDueDate) =>
      copyWith(dueDate: newDueDate, updatedAt: DateTime.now());

  /// Breaks the current streak (for missed tasks)
  Task breakStreak() {
    if (streakCount == 0) {
      return this;
    }

    return copyWith(streakCount: 0, updatedAt: DateTime.now());
  }

  /// Gets attribute type that this task primarily affects
  AttributeType get primaryAttribute {
    switch (category) {
      case TaskCategory.health:
        return AttributeType.strength;
      case TaskCategory.fitness:
        return AttributeType.strength;
      case TaskCategory.mindfulness:
        return AttributeType.wisdom;
      case TaskCategory.finance:
        return AttributeType.wisdom;
      case TaskCategory.work:
        return AttributeType.intelligence;
      case TaskCategory.learning:
        return AttributeType.intelligence;
      case TaskCategory.social:
        return AttributeType.wisdom;
      case TaskCategory.creative:
        return AttributeType.intelligence;
      case TaskCategory.custom:
        // Default to intelligence for custom tasks
        return AttributeType.intelligence;
    }
  }

  /// Creates a copy with updated fields
  Task copyWith({
    String? id,
    String? title,
    String? description,
    TaskType? type,
    TaskCategory? category,
    int? xpReward,
    int? difficulty,
    DateTime? dueDate,
    bool? isCompleted,
    int? streakCount,
    DateTime? lastCompletedDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Task(
    id: id ?? this.id,
    title: title ?? this.title,
    description: description ?? this.description,
    type: type ?? this.type,
    category: category ?? this.category,
    xpReward: xpReward ?? this.xpReward,
    difficulty: difficulty ?? this.difficulty,
    dueDate: dueDate ?? this.dueDate,
    isCompleted: isCompleted ?? this.isCompleted,
    streakCount: streakCount ?? this.streakCount,
    lastCompletedDate: lastCompletedDate ?? this.lastCompletedDate,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  /// Converts to JSON
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'type': type.name,
    'category': category.name,
    'xpReward': xpReward,
    'difficulty': difficulty,
    'dueDate': dueDate?.toIso8601String(),
    'isCompleted': isCompleted,
    'streakCount': streakCount,
    'lastCompletedDate': lastCompletedDate?.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  /// Converts to Map (alias for toJson for repository compatibility)
  Map<String, dynamic> toMap() => toJson();

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    type,
    category,
    xpReward,
    difficulty,
    dueDate,
    isCompleted,
    streakCount,
    lastCompletedDate,
    createdAt,
    updatedAt,
  ];

  @override
  String toString() =>
      'Task(id: $id, title: $title, type: $type, category: $category, '
      'difficulty: $difficulty, xp: $xpReward, streak: $streakCount, '
      'completed: $isCompleted)';
}

/// Enum for task types
enum TaskType { daily, weekly, longTerm }

/// Enum for task categories
enum TaskCategory { 
  health, 
  finance, 
  work, 
  custom,
  learning,
  social,
  creative,
  fitness,
  mindfulness,
}

/// Extension to get display names for task types
extension TaskTypeExtension on TaskType {
  String get displayName {
    switch (this) {
      case TaskType.daily:
        return 'Daily';
      case TaskType.weekly:
        return 'Weekly';
      case TaskType.longTerm:
        return 'Long-term';
    }
  }
}

/// Extension to get display names for task categories
extension TaskCategoryExtension on TaskCategory {
  String get displayName {
    switch (this) {
      case TaskCategory.health:
        return 'Health';
      case TaskCategory.fitness:
        return 'Fitness';
      case TaskCategory.mindfulness:
        return 'Mindfulness';
      case TaskCategory.finance:
        return 'Finance';
      case TaskCategory.work:
        return 'Work';
      case TaskCategory.learning:
        return 'Learning';
      case TaskCategory.social:
        return 'Social';
      case TaskCategory.creative:
        return 'Creative';
      case TaskCategory.custom:
        return 'Custom';
    }
  }

  String get icon {
    switch (this) {
      case TaskCategory.health:
        return '💪';
      case TaskCategory.fitness:
        return '🏃';
      case TaskCategory.mindfulness:
        return '🧘';
      case TaskCategory.finance:
        return '💰';
      case TaskCategory.work:
        return '💼';
      case TaskCategory.learning:
        return '📚';
      case TaskCategory.social:
        return '👥';
      case TaskCategory.creative:
        return '🎨';
      case TaskCategory.custom:
        return '⭐';
    }
  }
}

/// Import AttributeType from avatar.dart to avoid circular dependency
enum AttributeType { strength, wisdom, intelligence }
