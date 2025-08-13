import 'package:equatable/equatable.dart';

/// Represents an achievement that users can unlock
class Achievement extends Equatable {
  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.iconPath,
    required this.type,
    required this.criteria,
    required this.isUnlocked,
    required this.progress,
    required this.createdAt,
    required this.updatedAt,
    this.unlockedAt,
  });

  /// Creates a new achievement with default values
  factory Achievement.create({
    required String id,
    required String title,
    required String description,
    required String iconPath,
    required AchievementType type,
    required AchievementCriteria criteria,
  }) {
    final now = DateTime.now();
    return Achievement(
      id: id,
      title: title,
      description: description,
      iconPath: iconPath,
      type: type,
      criteria: criteria,
      isUnlocked: false,
      progress: 0,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Creates from JSON
  factory Achievement.fromJson(Map<String, dynamic> json) => Achievement(
    id: json['id'] as String,
    title: json['title'] as String,
    description: json['description'] as String,
    iconPath: json['iconPath'] as String,
    type: AchievementType.values.byName(json['type'] as String),
    criteria: AchievementCriteria.fromJson(
      json['criteria'] as Map<String, dynamic>,
    ),
    isUnlocked: json['isUnlocked'] as bool,
    unlockedAt: json['unlockedAt'] != null
        ? DateTime.parse(json['unlockedAt'] as String)
        : null,
    progress: json['progress'] as int,
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );
  final String id;
  final String title;
  final String description;
  final String iconPath;
  final AchievementType type;
  final AchievementCriteria criteria;
  final bool isUnlocked;
  final DateTime? unlockedAt;
  final int progress;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Maximum progress value
  static const int maxProgress = 999999;

  /// Calculates progress percentage (0.0 to 1.0)
  double get progressPercentage {
    if (criteria.targetValue <= 0) {
      return 0;
    }
    return (progress / criteria.targetValue).clamp(0.0, 1.0);
  }

  /// Checks if achievement is ready to be unlocked
  bool get canUnlock => !isUnlocked && _meetsUnlockCriteria();

  /// Validates achievement data
  bool get isValid =>
      _validateTitle() &&
      _validateDescription() &&
      _validateIconPath() &&
      _validateProgress() &&
      _validateUnlockState() &&
      _validateCriteria();

  /// Validates achievement title
  bool _validateTitle() => title.isNotEmpty && title.length <= 100;

  /// Validates achievement description
  bool _validateDescription() =>
      description.isNotEmpty && description.length <= 500;

  /// Validates icon path
  bool _validateIconPath() => iconPath.isNotEmpty;

  /// Validates progress bounds
  bool _validateProgress() => progress >= 0 && progress <= maxProgress;

  /// Validates unlock state consistency
  bool _validateUnlockState() {
    if (isUnlocked && unlockedAt == null) {
      return false;
    }
    if (!isUnlocked && unlockedAt != null) {
      return false;
    }
    return true;
  }

  /// Validates criteria
  bool _validateCriteria() => criteria.isValid;

  /// Checks if criteria are met for unlocking
  bool _meetsUnlockCriteria() {
    switch (type) {
      case AchievementType.streak:
        return progress >= criteria.targetValue;
      case AchievementType.total:
        return progress >= criteria.targetValue;
      case AchievementType.milestone:
        return progress >= criteria.targetValue;
      case AchievementType.category:
        return progress >= criteria.targetValue;
      case AchievementType.level:
        return progress >= criteria.targetValue;
      case AchievementType.special:
        return _checkSpecialCriteria();
    }
  }

  /// Checks special achievement criteria
  /// Special achievements may have complex criteria
  /// This would be implemented based on specific requirements
  bool _checkSpecialCriteria() => progress >= criteria.targetValue;

  /// Updates progress towards achievement
  Achievement updateProgress(int newProgress) {
    if (isUnlocked || newProgress < 0) {
      return this;
    }

    final clampedProgress = newProgress.clamp(0, maxProgress);
    final shouldUnlock = !isUnlocked && clampedProgress >= criteria.targetValue;

    return copyWith(
      progress: clampedProgress,
      isUnlocked: shouldUnlock ? true : null,
      unlockedAt: shouldUnlock ? DateTime.now() : null,
      updatedAt: DateTime.now(),
    );
  }

  /// Increments progress by specified amount
  Achievement incrementProgress(int amount) {
    if (amount <= 0) {
      return this;
    }
    return updateProgress(progress + amount);
  }

  /// Unlocks the achievement manually
  Achievement unlock() {
    if (isUnlocked) {
      return this;
    }

    return copyWith(
      isUnlocked: true,
      unlockedAt: DateTime.now(),
      progress:
          criteria.targetValue, // Set progress to target when manually unlocked
      updatedAt: DateTime.now(),
    );
  }

  /// Resets achievement to locked state (for testing or admin purposes)
  Achievement reset() {
    if (!isUnlocked) {
      return this;
    }

    return Achievement(
      id: id,
      title: title,
      description: description,
      iconPath: iconPath,
      type: type,
      criteria: criteria,
      isUnlocked: false,
      progress: 0,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  /// Gets the badge tier based on achievement type and criteria
  BadgeTier get badgeTier {
    switch (type) {
      case AchievementType.streak:
        if (criteria.targetValue >= 100) {
          return BadgeTier.legendary;
        }
        if (criteria.targetValue >= 50) {
          return BadgeTier.epic;
        }
        if (criteria.targetValue >= 20) {
          return BadgeTier.rare;
        }
        if (criteria.targetValue >= 7) {
          return BadgeTier.common;
        }
        return BadgeTier.bronze;

      case AchievementType.total:
        if (criteria.targetValue >= 1000) {
          return BadgeTier.legendary;
        }
        if (criteria.targetValue >= 500) {
          return BadgeTier.epic;
        }
        if (criteria.targetValue >= 100) {
          return BadgeTier.rare;
        }
        if (criteria.targetValue >= 50) {
          return BadgeTier.common;
        }
        return BadgeTier.bronze;

      case AchievementType.milestone:
      case AchievementType.level:
        if (criteria.targetValue >= 50) {
          return BadgeTier.legendary;
        }
        if (criteria.targetValue >= 25) {
          return BadgeTier.epic;
        }
        if (criteria.targetValue >= 10) {
          return BadgeTier.rare;
        }
        if (criteria.targetValue >= 5) {
          return BadgeTier.common;
        }
        return BadgeTier.bronze;

      case AchievementType.category:
        return BadgeTier.rare; // Category achievements are typically rare

      case AchievementType.special:
        return BadgeTier.legendary; // Special achievements are legendary
    }
  }

  /// Creates a copy with updated fields
  Achievement copyWith({
    String? id,
    String? title,
    String? description,
    String? iconPath,
    AchievementType? type,
    AchievementCriteria? criteria,
    bool? isUnlocked,
    DateTime? unlockedAt,
    int? progress,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Achievement(
    id: id ?? this.id,
    title: title ?? this.title,
    description: description ?? this.description,
    iconPath: iconPath ?? this.iconPath,
    type: type ?? this.type,
    criteria: criteria ?? this.criteria,
    isUnlocked: isUnlocked ?? this.isUnlocked,
    unlockedAt: unlockedAt ?? this.unlockedAt,
    progress: progress ?? this.progress,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  /// Converts to JSON
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'iconPath': iconPath,
    'type': type.name,
    'criteria': criteria.toJson(),
    'isUnlocked': isUnlocked,
    'unlockedAt': unlockedAt?.toIso8601String(),
    'progress': progress,
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
    iconPath,
    type,
    criteria,
    isUnlocked,
    unlockedAt,
    progress,
    createdAt,
    updatedAt,
  ];

  @override
  String toString() =>
      'Achievement(id: $id, title: $title, type: $type, '
      'progress: $progress/${criteria.targetValue}, unlocked: $isUnlocked)';
}

/// Enum for achievement types
enum AchievementType {
  streak, // Based on consecutive completions
  total, // Based on total count
  milestone, // Based on reaching specific milestones
  category, // Based on category-specific achievements
  level, // Based on avatar level
  special, // Special achievements with custom criteria
}

/// Enum for badge tiers
enum BadgeTier { bronze, common, rare, epic, legendary }

/// Represents the criteria for unlocking an achievement
class AchievementCriteria extends Equatable {
  // For complex criteria

  const AchievementCriteria({
    required this.targetValue,
    this.category,
    this.taskType,
    this.customCriteria = const {},
  });

  /// Creates criteria for streak achievements
  factory AchievementCriteria.streak(int streakLength) =>
      AchievementCriteria(targetValue: streakLength);

  /// Creates criteria for total count achievements
  factory AchievementCriteria.total(int totalCount, {String? category}) =>
      AchievementCriteria(targetValue: totalCount, category: category);

  /// Creates criteria for milestone achievements
  factory AchievementCriteria.milestone(int milestoneValue) =>
      AchievementCriteria(targetValue: milestoneValue);

  /// Creates criteria for level achievements
  factory AchievementCriteria.level(int levelRequired) =>
      AchievementCriteria(targetValue: levelRequired);

  /// Creates criteria for category achievements
  factory AchievementCriteria.category(String category, int targetValue) =>
      AchievementCriteria(targetValue: targetValue, category: category);

  /// Creates criteria for special achievements
  factory AchievementCriteria.special(
    int targetValue,
    Map<String, dynamic> customCriteria,
  ) => AchievementCriteria(
    targetValue: targetValue,
    customCriteria: customCriteria,
  );

  /// Creates from JSON
  factory AchievementCriteria.fromJson(Map<String, dynamic> json) =>
      AchievementCriteria(
        targetValue: json['targetValue'] as int,
        category: json['category'] as String?,
        taskType: json['taskType'] as String?,
        customCriteria: Map<String, dynamic>.from(
          json['customCriteria'] as Map? ?? {},
        ),
      );
  final int targetValue;
  final String? category; // For category-specific achievements
  final String? taskType; // For task-type specific achievements
  final Map<String, dynamic> customCriteria;

  /// Validates criteria data
  bool get isValid => targetValue > 0 && targetValue <= Achievement.maxProgress;

  /// Creates a copy with updated fields
  AchievementCriteria copyWith({
    int? targetValue,
    String? category,
    String? taskType,
    Map<String, dynamic>? customCriteria,
  }) => AchievementCriteria(
    targetValue: targetValue ?? this.targetValue,
    category: category ?? this.category,
    taskType: taskType ?? this.taskType,
    customCriteria: customCriteria ?? this.customCriteria,
  );

  /// Converts to JSON
  Map<String, dynamic> toJson() => {
    'targetValue': targetValue,
    'category': category,
    'taskType': taskType,
    'customCriteria': customCriteria,
  };

  @override
  List<Object?> get props => [targetValue, category, taskType, customCriteria];

  @override
  String toString() =>
      'AchievementCriteria(target: $targetValue, category: $category, '
      'taskType: $taskType, custom: $customCriteria)';
}

/// Extension to get display names for achievement types
extension AchievementTypeExtension on AchievementType {
  String get displayName {
    switch (this) {
      case AchievementType.streak:
        return 'Streak';
      case AchievementType.total:
        return 'Total';
      case AchievementType.milestone:
        return 'Milestone';
      case AchievementType.category:
        return 'Category';
      case AchievementType.level:
        return 'Level';
      case AchievementType.special:
        return 'Special';
    }
  }
}

/// Extension to get display names and colors for badge tiers
extension BadgeTierExtension on BadgeTier {
  String get displayName {
    switch (this) {
      case BadgeTier.bronze:
        return 'Bronze';
      case BadgeTier.common:
        return 'Common';
      case BadgeTier.rare:
        return 'Rare';
      case BadgeTier.epic:
        return 'Epic';
      case BadgeTier.legendary:
        return 'Legendary';
    }
  }

  String get colorHex {
    switch (this) {
      case BadgeTier.bronze:
        return '#CD7F32';
      case BadgeTier.common:
        return '#808080';
      case BadgeTier.rare:
        return '#0070DD';
      case BadgeTier.epic:
        return '#A335EE';
      case BadgeTier.legendary:
        return '#FF8000';
    }
  }
}
