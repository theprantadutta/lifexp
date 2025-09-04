import 'package:equatable/equatable.dart';

/// Represents a long-term goal that users can work toward
///
/// Goals are larger objectives that can be broken down into milestones and tasks.
/// They track progress over time and can be categorized similar to tasks and habits.
/// Goals have deadlines, priority levels, and can be linked to habits and tasks for
/// holistic progress tracking.
class Goal extends Equatable {
  const Goal({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.category,
    required this.priority,
    required this.status,
    required this.progress,
    required this.deadline,
    required this.createdAt,
    required this.updatedAt,
    this.startDate,
    this.completedAt,
    this.parentGoalId,
    this.subGoals = const [],
    this.associatedTasks = const [],
    this.associatedHabits = const [],
  });

  /// Creates a new goal with default values
  factory Goal.create({
    required String id,
    required String userId,
    required String title,
    required GoalCategory category,
    required DateTime deadline,
    String description = '',
    GoalPriority priority = GoalPriority.medium,
    DateTime? startDate,
  }) {
    final now = DateTime.now();

    return Goal(
      id: id,
      userId: userId,
      title: title,
      description: description,
      category: category,
      priority: priority,
      status: GoalStatus.notStarted,
      progress: 0.0,
      startDate: startDate,
      deadline: deadline,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Creates from JSON
  factory Goal.fromJson(Map<String, dynamic> json) => Goal(
        id: json['id'] as String,
        userId: json['userId'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        category: GoalCategory.values.byName(json['category'] as String),
        priority: GoalPriority.values.byName(json['priority'] as String),
        status: GoalStatus.values.byName(json['status'] as String),
        progress: (json['progress'] as num).toDouble(),
        startDate: json['startDate'] != null
            ? DateTime.parse(json['startDate'] as String)
            : null,
        deadline: DateTime.parse(json['deadline'] as String),
        completedAt: json['completedAt'] != null
            ? DateTime.parse(json['completedAt'] as String)
            : null,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        parentGoalId: json['parentGoalId'] as String?,
        subGoals: List<String>.from(json['subGoals'] as List<dynamic>),
        associatedTasks: List<String>.from(json['associatedTasks'] as List<dynamic>),
        associatedHabits: List<String>.from(json['associatedHabits'] as List<dynamic>),
      );

  final String id;
  final String userId;
  final String title;
  final String description;
  final GoalCategory category;
  final GoalPriority priority;
  final GoalStatus status;
  final double progress; // 0.0 to 1.0
  final DateTime? startDate;
  final DateTime deadline;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? parentGoalId;
  final List<String> subGoals;
  final List<String> associatedTasks;
  final List<String> associatedHabits;

  /// Maximum progress value
  static const double maxProgress = 1.0;

  /// Minimum progress value
  static const double minProgress = 0.0;

  /// Validates goal data
  bool get isValid =>
      _validateTitle() &&
      _validateDescription() &&
      _validateDates() &&
      _validateProgress();

  /// Validates goal title
  bool _validateTitle() => title.isNotEmpty && title.length <= 100;

  /// Validates goal description
  bool _validateDescription() => description.length <= 1000;

  /// Validates date consistency
  bool _validateDates() {
    if (startDate != null && startDate!.isAfter(deadline)) {
      return false;
    }
    if (completedAt != null && completedAt!.isAfter(DateTime.now())) {
      return false;
    }
    return true;
  }

  /// Validates progress bounds
  bool _validateProgress() =>
      progress >= minProgress && progress <= maxProgress;

  /// Updates goal progress and status
  Goal updateProgress(double newProgress) {
    if (newProgress < minProgress || newProgress > maxProgress) {
      return this;
    }

    final newStatus = newProgress >= maxProgress
        ? GoalStatus.completed
        : newProgress > minProgress
            ? GoalStatus.inProgress
            : GoalStatus.notStarted;

    final completedAt = newStatus == GoalStatus.completed ? DateTime.now() : this.completedAt;

    return copyWith(
      progress: newProgress,
      status: newStatus,
      completedAt: completedAt,
      updatedAt: DateTime.now(),
    );
  }

  /// Adds a sub-goal to this goal
  Goal addSubGoal(String subGoalId) => copyWith(
        subGoals: [...subGoals, subGoalId],
        updatedAt: DateTime.now(),
      );

  /// Removes a sub-goal from this goal
  Goal removeSubGoal(String subGoalId) => copyWith(
        subGoals: subGoals.where((id) => id != subGoalId).toList(),
        updatedAt: DateTime.now(),
      );

  /// Associates a task with this goal
  Goal associateTask(String taskId) => copyWith(
        associatedTasks: [...associatedTasks, taskId],
        updatedAt: DateTime.now(),
      );

  /// Removes task association from this goal
  Goal removeTaskAssociation(String taskId) => copyWith(
        associatedTasks: associatedTasks.where((id) => id != taskId).toList(),
        updatedAt: DateTime.now(),
      );

  /// Associates a habit with this goal
  Goal associateHabit(String habitId) => copyWith(
        associatedHabits: [...associatedHabits, habitId],
        updatedAt: DateTime.now(),
      );

  /// Removes habit association from this goal
  Goal removeHabitAssociation(String habitId) => copyWith(
        associatedHabits: associatedHabits.where((id) => id != habitId).toList(),
        updatedAt: DateTime.now(),
      );

  /// Updates goal status
  Goal updateStatus(GoalStatus newStatus) => copyWith(
        status: newStatus,
        completedAt: newStatus == GoalStatus.completed ? DateTime.now() : null,
        updatedAt: DateTime.now(),
      );

  /// Updates goal priority
  Goal updatePriority(GoalPriority newPriority) => copyWith(
        priority: newPriority,
        updatedAt: DateTime.now(),
      );

  /// Gets estimated XP reward for completing this goal
  int get xpReward {
    // Base XP based on priority and progress
    final baseXP = priority.index * 100;
    final progressBonus = (progress * 500).round();

    return baseXP + progressBonus;
  }

  /// Gets attribute type that this goal primarily affects
  AttributeType get primaryAttribute {
    switch (category) {
      case GoalCategory.health:
        return AttributeType.strength;
      case GoalCategory.fitness:
        return AttributeType.strength;
      case GoalCategory.mindfulness:
        return AttributeType.wisdom;
      case GoalCategory.learning:
        return AttributeType.intelligence;
      case GoalCategory.career:
        return AttributeType.intelligence;
      case GoalCategory.financial:
        return AttributeType.intelligence;
      case GoalCategory.relationships:
        return AttributeType.wisdom;
      case GoalCategory.personal:
        return AttributeType.strength;
      case GoalCategory.custom:
        // Default to intelligence for custom goals
        return AttributeType.intelligence;
    }
  }

  /// Creates a copy with updated fields
  Goal copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    GoalCategory? category,
    GoalPriority? priority,
    GoalStatus? status,
    double? progress,
    DateTime? startDate,
    DateTime? deadline,
    DateTime? completedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? parentGoalId,
    List<String>? subGoals,
    List<String>? associatedTasks,
    List<String>? associatedHabits,
  }) =>
      Goal(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        title: title ?? this.title,
        description: description ?? this.description,
        category: category ?? this.category,
        priority: priority ?? this.priority,
        status: status ?? this.status,
        progress: progress ?? this.progress,
        startDate: startDate ?? this.startDate,
        deadline: deadline ?? this.deadline,
        completedAt: completedAt ?? this.completedAt,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        parentGoalId: parentGoalId ?? this.parentGoalId,
        subGoals: subGoals ?? this.subGoals,
        associatedTasks: associatedTasks ?? this.associatedTasks,
        associatedHabits: associatedHabits ?? this.associatedHabits,
      );

  /// Converts to JSON
  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'title': title,
        'description': description,
        'category': category.name,
        'priority': priority.name,
        'status': status.name,
        'progress': progress,
        'startDate': startDate?.toIso8601String(),
        'deadline': deadline.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'parentGoalId': parentGoalId,
        'subGoals': subGoals,
        'associatedTasks': associatedTasks,
        'associatedHabits': associatedHabits,
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
        priority,
        status,
        progress,
        startDate,
        deadline,
        completedAt,
        createdAt,
        updatedAt,
        parentGoalId,
        subGoals,
        associatedTasks,
        associatedHabits,
      ];

  @override
  String toString() =>
      'Goal(id: $id, title: $title, category: $category, '
      'priority: $priority, status: $status, progress: $progress, '
      'deadline: $deadline)';
}

/// Enum for goal categories
enum GoalCategory {
  health,
  fitness,
  mindfulness,
  learning,
  career,
  financial,
  relationships,
  personal,
  custom,
}

/// Extension to get display names for goal categories
extension GoalCategoryExtension on GoalCategory {
  String get displayName {
    switch (this) {
      case GoalCategory.health:
        return 'Health';
      case GoalCategory.fitness:
        return 'Fitness';
      case GoalCategory.mindfulness:
        return 'Mindfulness';
      case GoalCategory.learning:
        return 'Learning';
      case GoalCategory.career:
        return 'Career';
      case GoalCategory.financial:
        return 'Financial';
      case GoalCategory.relationships:
        return 'Relationships';
      case GoalCategory.personal:
        return 'Personal';
      case GoalCategory.custom:
        return 'Custom';
    }
  }

  String get icon {
    switch (this) {
      case GoalCategory.health:
        return '🏥';
      case GoalCategory.fitness:
        return '💪';
      case GoalCategory.mindfulness:
        return '🧘';
      case GoalCategory.learning:
        return '📚';
      case GoalCategory.career:
        return '💼';
      case GoalCategory.financial:
        return '💰';
      case GoalCategory.relationships:
        return '👥';
      case GoalCategory.personal:
        return '🌟';
      case GoalCategory.custom:
        return '⭐';
    }
  }
}

/// Enum for goal priorities
enum GoalPriority { low, medium, high, critical }

/// Extension to get display names for goal priorities
extension GoalPriorityExtension on GoalPriority {
  String get displayName {
    switch (this) {
      case GoalPriority.low:
        return 'Low';
      case GoalPriority.medium:
        return 'Medium';
      case GoalPriority.high:
        return 'High';
      case GoalPriority.critical:
        return 'Critical';
    }
  }

  int get value {
    switch (this) {
      case GoalPriority.low:
        return 1;
      case GoalPriority.medium:
        return 2;
      case GoalPriority.high:
        return 3;
      case GoalPriority.critical:
        return 4;
    }
  }
}

/// Enum for goal statuses
enum GoalStatus { notStarted, inProgress, onHold, completed, cancelled }

/// Extension to get display names for goal statuses
extension GoalStatusExtension on GoalStatus {
  String get displayName {
    switch (this) {
      case GoalStatus.notStarted:
        return 'Not Started';
      case GoalStatus.inProgress:
        return 'In Progress';
      case GoalStatus.onHold:
        return 'On Hold';
      case GoalStatus.completed:
        return 'Completed';
      case GoalStatus.cancelled:
        return 'Cancelled';
    }
  }
}

/// Import AttributeType from avatar.dart to avoid circular dependency
enum AttributeType { strength, wisdom, intelligence }