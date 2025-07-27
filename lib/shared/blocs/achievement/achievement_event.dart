import 'package:equatable/equatable.dart';

import '../../../data/models/achievement.dart';

/// Base class for all achievement events
abstract class AchievementEvent extends Equatable {
  const AchievementEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load achievements for a user
class LoadAchievements extends AchievementEvent {
  const LoadAchievements({required this.userId});

  final String userId;

  @override
  List<Object?> get props => [userId];
}

/// Event to load unlocked achievements
class LoadUnlockedAchievements extends AchievementEvent {
  const LoadUnlockedAchievements({required this.userId});

  final String userId;

  @override
  List<Object?> get props => [userId];
}

/// Event to load locked achievements
class LoadLockedAchievements extends AchievementEvent {
  const LoadLockedAchievements({required this.userId});

  final String userId;

  @override
  List<Object?> get props => [userId];
}

/// Event to load achievements by type
class LoadAchievementsByType extends AchievementEvent {
  const LoadAchievementsByType({required this.userId, required this.type});

  final String userId;
  final AchievementType type;

  @override
  List<Object?> get props => [userId, type];
}

/// Event to create a new achievement
class CreateAchievement extends AchievementEvent {
  const CreateAchievement({
    required this.userId,
    required this.title,
    required this.description,
    required this.iconPath,
    required this.type,
    required this.criteria,
  });

  final String userId;
  final String title;
  final String description;
  final String iconPath;
  final AchievementType type;
  final AchievementCriteria criteria;

  @override
  List<Object?> get props => [
    userId,
    title,
    description,
    iconPath,
    type,
    criteria,
  ];
}

/// Event to update achievement progress
class UpdateAchievementProgress extends AchievementEvent {
  const UpdateAchievementProgress({
    required this.achievementId,
    required this.newProgress,
  });

  final String achievementId;
  final int newProgress;

  @override
  List<Object?> get props => [achievementId, newProgress];
}

/// Event to increment achievement progress
class IncrementAchievementProgress extends AchievementEvent {
  const IncrementAchievementProgress({
    required this.achievementId,
    required this.amount,
  });

  final String achievementId;
  final int amount;

  @override
  List<Object?> get props => [achievementId, amount];
}

/// Event to unlock achievement manually
class UnlockAchievement extends AchievementEvent {
  const UnlockAchievement({required this.achievementId});

  final String achievementId;

  @override
  List<Object?> get props => [achievementId];
}

/// Event to check and update achievements based on user stats
class CheckAndUpdateAchievements extends AchievementEvent {
  const CheckAndUpdateAchievements({
    required this.userId,
    required this.userStats,
  });

  final String userId;
  final Map<String, dynamic> userStats;

  @override
  List<Object?> get props => [userId, userStats];
}

/// Event to batch check criteria for multiple achievements
class BatchCheckCriteria extends AchievementEvent {
  const BatchCheckCriteria({required this.userId, required this.userStats});

  final String userId;
  final Map<String, dynamic> userStats;

  @override
  List<Object?> get props => [userId, userStats];
}

/// Event to evaluate specific achievement criteria
class EvaluateAchievementCriteria extends AchievementEvent {
  const EvaluateAchievementCriteria({
    required this.achievement,
    required this.userStats,
  });

  final Achievement achievement;
  final Map<String, dynamic> userStats;

  @override
  List<Object?> get props => [achievement, userStats];
}

/// Event to calculate achievement progress
class CalculateAchievementProgress extends AchievementEvent {
  const CalculateAchievementProgress({
    required this.achievement,
    required this.userStats,
  });

  final Achievement achievement;
  final Map<String, dynamic> userStats;

  @override
  List<Object?> get props => [achievement, userStats];
}

/// Event to load recent achievement unlocks
class LoadRecentUnlocks extends AchievementEvent {
  const LoadRecentUnlocks({required this.userId, this.days = 7});

  final String userId;
  final int days;

  @override
  List<Object?> get props => [userId, days];
}

/// Event to load unlockable achievements
class LoadUnlockableAchievements extends AchievementEvent {
  const LoadUnlockableAchievements({required this.userId});

  final String userId;

  @override
  List<Object?> get props => [userId];
}

/// Event to create default achievements for new user
class CreateDefaultAchievements extends AchievementEvent {
  const CreateDefaultAchievements({required this.userId});

  final String userId;

  @override
  List<Object?> get props => [userId];
}

/// Event to refresh achievements
class RefreshAchievements extends AchievementEvent {
  const RefreshAchievements({required this.userId});

  final String userId;

  @override
  List<Object?> get props => [userId];
}

/// Event to handle achievement unlock notification completion
class AchievementUnlockNotificationCompleted extends AchievementEvent {
  const AchievementUnlockNotificationCompleted({required this.achievementId});

  final String achievementId;

  @override
  List<Object?> get props => [achievementId];
}

/// Event to handle achievement celebration completion
class AchievementCelebrationCompleted extends AchievementEvent {
  const AchievementCelebrationCompleted({required this.achievementId});

  final String achievementId;

  @override
  List<Object?> get props => [achievementId];
}

/// Event to filter achievements
class FilterAchievements extends AchievementEvent {
  const FilterAchievements({required this.filter});

  final AchievementFilter filter;

  @override
  List<Object?> get props => [filter];
}

/// Event to sort achievements
class SortAchievements extends AchievementEvent {
  const SortAchievements({required this.sortType});

  final AchievementSortType sortType;

  @override
  List<Object?> get props => [sortType];
}

/// Event to search achievements
class SearchAchievements extends AchievementEvent {
  const SearchAchievements({required this.userId, required this.query});

  final String userId;
  final String query;

  @override
  List<Object?> get props => [userId, query];
}

/// Event to clear achievement filters
class ClearAchievementFilters extends AchievementEvent {
  const ClearAchievementFilters({required this.userId});

  final String userId;

  @override
  List<Object?> get props => [userId];
}

/// Data class for achievement filters
class AchievementFilter extends Equatable {
  const AchievementFilter({
    this.type,
    this.isUnlocked,
    this.badgeTier,
    this.canUnlock,
    this.minProgress,
    this.maxProgress,
  });

  final AchievementType? type;
  final bool? isUnlocked;
  final BadgeTier? badgeTier;
  final bool? canUnlock;
  final int? minProgress;
  final int? maxProgress;

  @override
  List<Object?> get props => [
    type,
    isUnlocked,
    badgeTier,
    canUnlock,
    minProgress,
    maxProgress,
  ];

  /// Creates a copy with updated fields
  AchievementFilter copyWith({
    AchievementType? type,
    bool? isUnlocked,
    BadgeTier? badgeTier,
    bool? canUnlock,
    int? minProgress,
    int? maxProgress,
  }) => AchievementFilter(
    type: type ?? this.type,
    isUnlocked: isUnlocked ?? this.isUnlocked,
    badgeTier: badgeTier ?? this.badgeTier,
    canUnlock: canUnlock ?? this.canUnlock,
    minProgress: minProgress ?? this.minProgress,
    maxProgress: maxProgress ?? this.maxProgress,
  );

  /// Checks if an achievement matches this filter
  bool matches(Achievement achievement) {
    if (type != null && achievement.type != type) return false;
    if (isUnlocked != null && achievement.isUnlocked != isUnlocked) {
      return false;
    }
    if (badgeTier != null && achievement.badgeTier != badgeTier) return false;
    if (canUnlock != null && achievement.canUnlock != canUnlock) return false;
    if (minProgress != null && achievement.progress < minProgress!) {
      return false;
    }
    if (maxProgress != null && achievement.progress > maxProgress!) {
      return false;
    }

    return true;
  }
}

/// Enum for achievement sorting options
enum AchievementSortType {
  title,
  type,
  progress,
  unlockedDate,
  createdDate,
  badgeTier,
  canUnlock,
}
