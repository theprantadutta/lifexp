import 'package:equatable/equatable.dart';

import '../../../data/models/achievement.dart';
import 'achievement_event.dart';

/// Base class for all achievement states
abstract class AchievementState extends Equatable {
  const AchievementState();

  @override
  List<Object?> get props => [];
}

/// Initial state when no achievements are loaded
class AchievementInitial extends AchievementState {
  const AchievementInitial();
}

/// State when achievements are being loaded
class AchievementLoading extends AchievementState {
  const AchievementLoading();
}

/// State when achievements are successfully loaded
class AchievementLoaded extends AchievementState {
  const AchievementLoaded({
    required this.achievements,
    this.filteredAchievements,
    this.activeFilter,
    this.sortType = AchievementSortType.createdDate,
    this.searchQuery = '',
    this.showUnlockNotification = false,
    this.unlockedAchievement,
    this.showCelebration = false,
    this.celebratingAchievement,
    this.recentUnlocks = const [],
    this.progressUpdates = const {},
  });

  final List<Achievement> achievements;
  final List<Achievement>? filteredAchievements;
  final AchievementFilter? activeFilter;
  final AchievementSortType sortType;
  final String searchQuery;
  final bool showUnlockNotification;
  final Achievement? unlockedAchievement;
  final bool showCelebration;
  final Achievement? celebratingAchievement;
  final List<Achievement> recentUnlocks;
  final Map<String, int> progressUpdates; // achievementId -> new progress

  /// Gets the achievements to display (filtered or all)
  List<Achievement> get displayAchievements =>
      filteredAchievements ?? achievements;

  /// Gets unlocked achievements
  List<Achievement> get unlockedAchievements => displayAchievements
      .where((achievement) => achievement.isUnlocked)
      .toList();

  /// Gets locked achievements
  List<Achievement> get lockedAchievements => displayAchievements
      .where((achievement) => !achievement.isUnlocked)
      .toList();

  /// Gets achievements that can be unlocked
  List<Achievement> get unlockableAchievements => displayAchievements
      .where((achievement) => achievement.canUnlock)
      .toList();

  /// Gets achievements by type
  Map<AchievementType, List<Achievement>> get achievementsByType {
    final Map<AchievementType, List<Achievement>> typedAchievements = {};
    for (final type in AchievementType.values) {
      typedAchievements[type] = displayAchievements
          .where((achievement) => achievement.type == type)
          .toList();
    }
    return typedAchievements;
  }

  /// Gets achievements by badge tier
  Map<BadgeTier, List<Achievement>> get achievementsByTier {
    final Map<BadgeTier, List<Achievement>> tieredAchievements = {};
    for (final tier in BadgeTier.values) {
      tieredAchievements[tier] = displayAchievements
          .where((achievement) => achievement.badgeTier == tier)
          .toList();
    }
    return tieredAchievements;
  }

  /// Gets achievement statistics
  AchievementStats get stats {
    final total = achievements.length;
    final unlocked = unlockedAchievements.length;
    final locked = lockedAchievements.length;
    final unlockable = unlockableAchievements.length;

    return AchievementStats(
      total: total,
      unlocked: unlocked,
      locked: locked,
      unlockable: unlockable,
      completionRate: total > 0 ? unlocked / total : 0.0,
    );
  }

  @override
  List<Object?> get props => [
    achievements,
    filteredAchievements,
    activeFilter,
    sortType,
    searchQuery,
    showUnlockNotification,
    unlockedAchievement,
    showCelebration,
    celebratingAchievement,
    recentUnlocks,
    progressUpdates,
  ];

  /// Creates a copy with updated fields
  AchievementLoaded copyWith({
    List<Achievement>? achievements,
    List<Achievement>? filteredAchievements,
    AchievementFilter? activeFilter,
    AchievementSortType? sortType,
    String? searchQuery,
    bool? showUnlockNotification,
    Achievement? unlockedAchievement,
    bool? showCelebration,
    Achievement? celebratingAchievement,
    List<Achievement>? recentUnlocks,
    Map<String, int>? progressUpdates,
  }) => AchievementLoaded(
    achievements: achievements ?? this.achievements,
    filteredAchievements: filteredAchievements ?? this.filteredAchievements,
    activeFilter: activeFilter ?? this.activeFilter,
    sortType: sortType ?? this.sortType,
    searchQuery: searchQuery ?? this.searchQuery,
    showUnlockNotification:
        showUnlockNotification ?? this.showUnlockNotification,
    unlockedAchievement: unlockedAchievement ?? this.unlockedAchievement,
    showCelebration: showCelebration ?? this.showCelebration,
    celebratingAchievement:
        celebratingAchievement ?? this.celebratingAchievement,
    recentUnlocks: recentUnlocks ?? this.recentUnlocks,
    progressUpdates: progressUpdates ?? this.progressUpdates,
  );

  /// Clears unlock notification state
  AchievementLoaded clearUnlockNotification() =>
      copyWith(showUnlockNotification: false, unlockedAchievement: null);

  /// Clears celebration state
  AchievementLoaded clearCelebration() =>
      copyWith(showCelebration: false, celebratingAchievement: null);

  /// Clears filters
  AchievementLoaded clearFilters() =>
      copyWith(filteredAchievements: null, activeFilter: null, searchQuery: '');

  /// Clears progress updates
  AchievementLoaded clearProgressUpdates() =>
      copyWith(progressUpdates: const {});
}

/// State when achievement operation fails
class AchievementError extends AchievementState {
  const AchievementError({
    required this.message,
    this.achievements,
    this.errorType = AchievementErrorType.general,
  });

  final String message;
  final List<Achievement>?
  achievements; // Keep current achievements if available
  final AchievementErrorType errorType;

  @override
  List<Object?> get props => [message, achievements, errorType];
}

/// State when achievement is being updated
class AchievementUpdating extends AchievementState {
  const AchievementUpdating({
    required this.achievements,
    required this.updateType,
    this.updatingAchievementId,
  });

  final List<Achievement> achievements;
  final AchievementUpdateType updateType;
  final String? updatingAchievementId;

  @override
  List<Object?> get props => [achievements, updateType, updatingAchievementId];
}

/// State when achievement is being created
class AchievementCreating extends AchievementState {
  const AchievementCreating({required this.achievements});

  final List<Achievement> achievements;

  @override
  List<Object?> get props => [achievements];
}

/// State when checking achievement criteria
class AchievementChecking extends AchievementState {
  const AchievementChecking({
    required this.achievements,
    required this.checkingType,
  });

  final List<Achievement> achievements;
  final AchievementCheckingType checkingType;

  @override
  List<Object?> get props => [achievements, checkingType];
}

/// Data class for achievement statistics
class AchievementStats extends Equatable {
  const AchievementStats({
    required this.total,
    required this.unlocked,
    required this.locked,
    required this.unlockable,
    required this.completionRate,
  });

  final int total;
  final int unlocked;
  final int locked;
  final int unlockable;
  final double completionRate;

  @override
  List<Object?> get props => [
    total,
    unlocked,
    locked,
    unlockable,
    completionRate,
  ];
}

/// Data class for achievement unlock notification
class AchievementUnlockNotification extends Equatable {
  const AchievementUnlockNotification({
    required this.achievement,
    required this.timestamp,
    this.celebrationDuration = const Duration(seconds: 3),
  });

  final Achievement achievement;
  final DateTime timestamp;
  final Duration celebrationDuration;

  @override
  List<Object?> get props => [achievement, timestamp, celebrationDuration];
}

/// Data class for achievement progress update
class AchievementProgressUpdate extends Equatable {
  const AchievementProgressUpdate({
    required this.achievementId,
    required this.previousProgress,
    required this.newProgress,
    required this.timestamp,
  });

  final String achievementId;
  final int previousProgress;
  final int newProgress;
  final DateTime timestamp;

  /// Gets the progress difference
  int get progressDifference => newProgress - previousProgress;

  /// Checks if this update resulted in an unlock
  bool get resultedInUnlock => newProgress >= 100 && previousProgress < 100;

  @override
  List<Object?> get props => [
    achievementId,
    previousProgress,
    newProgress,
    timestamp,
  ];
}

/// Enum for different types of achievement errors
enum AchievementErrorType {
  general,
  network,
  validation,
  notFound,
  unauthorized,
  criteriaEvaluation,
}

/// Enum for different types of achievement updates
enum AchievementUpdateType {
  creation,
  progressUpdate,
  unlock,
  criteriaCheck,
  batchUpdate,
}

/// Enum for different types of achievement checking
enum AchievementCheckingType { single, batch, criteria, progress }
