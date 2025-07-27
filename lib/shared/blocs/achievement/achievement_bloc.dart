import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/achievement.dart';
import '../../../data/repositories/achievement_repository.dart';
import 'achievement_event.dart';
import 'achievement_state.dart';

/// BLoC for managing achievement progress, unlock notifications, and celebration animations
class AchievementBloc extends Bloc<AchievementEvent, AchievementState> {
  AchievementBloc({required AchievementRepository achievementRepository})
    : _achievementRepository = achievementRepository,
      super(const AchievementInitial()) {
    on<LoadAchievements>(_onLoadAchievements);
    on<LoadUnlockedAchievements>(_onLoadUnlockedAchievements);
    on<LoadLockedAchievements>(_onLoadLockedAchievements);
    on<LoadAchievementsByType>(_onLoadAchievementsByType);
    on<CreateAchievement>(_onCreateAchievement);
    on<UpdateAchievementProgress>(_onUpdateAchievementProgress);
    on<IncrementAchievementProgress>(_onIncrementAchievementProgress);
    on<UnlockAchievement>(_onUnlockAchievement);
    on<CheckAndUpdateAchievements>(_onCheckAndUpdateAchievements);
    on<BatchCheckCriteria>(_onBatchCheckCriteria);
    on<EvaluateAchievementCriteria>(_onEvaluateAchievementCriteria);
    on<CalculateAchievementProgress>(_onCalculateAchievementProgress);
    on<LoadRecentUnlocks>(_onLoadRecentUnlocks);
    on<LoadUnlockableAchievements>(_onLoadUnlockableAchievements);
    on<CreateDefaultAchievements>(_onCreateDefaultAchievements);
    on<RefreshAchievements>(_onRefreshAchievements);
    on<AchievementUnlockNotificationCompleted>(
      _onAchievementUnlockNotificationCompleted,
    );
    on<AchievementCelebrationCompleted>(_onAchievementCelebrationCompleted);
    on<FilterAchievements>(_onFilterAchievements);
    on<SortAchievements>(_onSortAchievements);
    on<SearchAchievements>(_onSearchAchievements);
    on<ClearAchievementFilters>(_onClearAchievementFilters);

    // Achievement unlock notifications are handled through events
  }

  final AchievementRepository _achievementRepository;
  StreamSubscription<Achievement>? _achievementUnlockSubscription;

  /// Handles loading achievements for a user
  Future<void> _onLoadAchievements(
    LoadAchievements event,
    Emitter<AchievementState> emit,
  ) async {
    emit(const AchievementLoading());

    try {
      final achievements = await _achievementRepository.getAchievementsByUserId(
        event.userId,
      );
      emit(AchievementLoaded(achievements: achievements));
    } on Exception catch (e) {
      emit(
        AchievementError(
          message: 'Failed to load achievements: ${e.toString()}',
          errorType: AchievementErrorType.general,
        ),
      );
    }
  }

  /// Handles loading unlocked achievements
  Future<void> _onLoadUnlockedAchievements(
    LoadUnlockedAchievements event,
    Emitter<AchievementState> emit,
  ) async {
    final currentState = state;
    if (currentState is! AchievementLoaded) return;

    try {
      final unlockedAchievements = await _achievementRepository
          .getUnlockedAchievements(event.userId);

      final filter = const AchievementFilter(isUnlocked: true);

      emit(
        currentState.copyWith(
          filteredAchievements: unlockedAchievements,
          activeFilter: filter,
        ),
      );
    } on Exception catch (e) {
      emit(
        AchievementError(
          message: 'Failed to load unlocked achievements: ${e.toString()}',
          achievements: currentState.achievements,
          errorType: AchievementErrorType.general,
        ),
      );
    }
  }

  /// Handles loading locked achievements
  Future<void> _onLoadLockedAchievements(
    LoadLockedAchievements event,
    Emitter<AchievementState> emit,
  ) async {
    final currentState = state;
    if (currentState is! AchievementLoaded) return;

    try {
      final lockedAchievements = await _achievementRepository
          .getLockedAchievements(event.userId);

      final filter = const AchievementFilter(isUnlocked: false);

      emit(
        currentState.copyWith(
          filteredAchievements: lockedAchievements,
          activeFilter: filter,
        ),
      );
    } on Exception catch (e) {
      emit(
        AchievementError(
          message: 'Failed to load locked achievements: ${e.toString()}',
          achievements: currentState.achievements,
          errorType: AchievementErrorType.general,
        ),
      );
    }
  }

  /// Handles loading achievements by type
  Future<void> _onLoadAchievementsByType(
    LoadAchievementsByType event,
    Emitter<AchievementState> emit,
  ) async {
    final currentState = state;
    if (currentState is! AchievementLoaded) return;

    try {
      final achievementsByType = await _achievementRepository
          .getAchievementsByType(event.userId, event.type);

      final filter = AchievementFilter(type: event.type);

      emit(
        currentState.copyWith(
          filteredAchievements: achievementsByType,
          activeFilter: filter,
        ),
      );
    } on Exception catch (e) {
      emit(
        AchievementError(
          message: 'Failed to load achievements by type: ${e.toString()}',
          achievements: currentState.achievements,
          errorType: AchievementErrorType.general,
        ),
      );
    }
  }

  /// Handles creating a new achievement
  Future<void> _onCreateAchievement(
    CreateAchievement event,
    Emitter<AchievementState> emit,
  ) async {
    final currentState = state;
    List<Achievement> currentAchievements = [];

    if (currentState is AchievementLoaded) {
      currentAchievements = currentState.achievements;
      emit(AchievementCreating(achievements: currentAchievements));
    } else {
      emit(const AchievementLoading());
    }

    try {
      final newAchievement = await _achievementRepository.createAchievement(
        userId: event.userId,
        title: event.title,
        description: event.description,
        iconPath: event.iconPath,
        type: event.type,
        criteria: event.criteria,
      );

      final updatedAchievements = [...currentAchievements, newAchievement];
      emit(AchievementLoaded(achievements: updatedAchievements));
    } on Exception catch (e) {
      emit(
        AchievementError(
          message: 'Failed to create achievement: ${e.toString()}',
          achievements: currentAchievements,
          errorType: AchievementErrorType.general,
        ),
      );
    }
  }

  /// Handles updating achievement progress
  Future<void> _onUpdateAchievementProgress(
    UpdateAchievementProgress event,
    Emitter<AchievementState> emit,
  ) async {
    final currentState = state;
    if (currentState is! AchievementLoaded) return;

    // Find the achievement being updated
    final achievementToUpdate = currentState.achievements
        .where((achievement) => achievement.id == event.achievementId)
        .firstOrNull;

    if (achievementToUpdate == null) return;

    // Track previous progress for potential future use

    emit(
      AchievementUpdating(
        achievements: currentState.achievements,
        updateType: AchievementUpdateType.progressUpdate,
        updatingAchievementId: event.achievementId,
      ),
    );

    try {
      final updatedAchievement = await _achievementRepository.updateProgress(
        event.achievementId,
        event.newProgress,
      );

      if (updatedAchievement == null) {
        emit(
          AchievementError(
            message: 'Failed to update achievement progress',
            achievements: currentState.achievements,
            errorType: AchievementErrorType.general,
          ),
        );
        return;
      }

      // Update achievements list
      final updatedAchievements = currentState.achievements
          .map(
            (achievement) => achievement.id == updatedAchievement.id
                ? updatedAchievement
                : achievement,
          )
          .toList();

      // Check if achievement was just unlocked
      final wasJustUnlocked =
          !achievementToUpdate.isUnlocked && updatedAchievement.isUnlocked;

      emit(
        AchievementLoaded(
          achievements: updatedAchievements,
          filteredAchievements: currentState.filteredAchievements,
          activeFilter: currentState.activeFilter,
          sortType: currentState.sortType,
          searchQuery: currentState.searchQuery,
          showUnlockNotification: wasJustUnlocked,
          unlockedAchievement: wasJustUnlocked ? updatedAchievement : null,
          showCelebration: wasJustUnlocked,
          celebratingAchievement: wasJustUnlocked ? updatedAchievement : null,
          recentUnlocks: currentState.recentUnlocks,
          progressUpdates: {event.achievementId: event.newProgress},
        ),
      );
    } on Exception catch (e) {
      emit(
        AchievementError(
          message: 'Failed to update achievement progress: ${e.toString()}',
          achievements: currentState.achievements,
          errorType: AchievementErrorType.general,
        ),
      );
    }
  }

  /// Handles incrementing achievement progress
  Future<void> _onIncrementAchievementProgress(
    IncrementAchievementProgress event,
    Emitter<AchievementState> emit,
  ) async {
    final currentState = state;
    if (currentState is! AchievementLoaded) return;

    // Find the achievement being updated
    final achievementToUpdate = currentState.achievements
        .where((achievement) => achievement.id == event.achievementId)
        .firstOrNull;

    if (achievementToUpdate == null) return;

    emit(
      AchievementUpdating(
        achievements: currentState.achievements,
        updateType: AchievementUpdateType.progressUpdate,
        updatingAchievementId: event.achievementId,
      ),
    );

    try {
      final updatedAchievement = await _achievementRepository.incrementProgress(
        event.achievementId,
        event.amount,
      );

      if (updatedAchievement == null) {
        emit(
          AchievementError(
            message: 'Failed to increment achievement progress',
            achievements: currentState.achievements,
            errorType: AchievementErrorType.general,
          ),
        );
        return;
      }

      // Update achievements list
      final updatedAchievements = currentState.achievements
          .map(
            (achievement) => achievement.id == updatedAchievement.id
                ? updatedAchievement
                : achievement,
          )
          .toList();

      // Check if achievement was just unlocked
      final wasJustUnlocked =
          !achievementToUpdate.isUnlocked && updatedAchievement.isUnlocked;

      emit(
        AchievementLoaded(
          achievements: updatedAchievements,
          filteredAchievements: currentState.filteredAchievements,
          activeFilter: currentState.activeFilter,
          sortType: currentState.sortType,
          searchQuery: currentState.searchQuery,
          showUnlockNotification: wasJustUnlocked,
          unlockedAchievement: wasJustUnlocked ? updatedAchievement : null,
          showCelebration: wasJustUnlocked,
          celebratingAchievement: wasJustUnlocked ? updatedAchievement : null,
          recentUnlocks: currentState.recentUnlocks,
          progressUpdates: {event.achievementId: updatedAchievement.progress},
        ),
      );
    } on Exception catch (e) {
      emit(
        AchievementError(
          message: 'Failed to increment achievement progress: ${e.toString()}',
          achievements: currentState.achievements,
          errorType: AchievementErrorType.general,
        ),
      );
    }
  }

  /// Handles manual achievement unlock
  Future<void> _onUnlockAchievement(
    UnlockAchievement event,
    Emitter<AchievementState> emit,
  ) async {
    final currentState = state;
    if (currentState is! AchievementLoaded) return;

    // Find the achievement being unlocked
    final achievementToUnlock = currentState.achievements
        .where((achievement) => achievement.id == event.achievementId)
        .firstOrNull;

    if (achievementToUnlock == null || achievementToUnlock.isUnlocked) return;

    emit(
      AchievementUpdating(
        achievements: currentState.achievements,
        updateType: AchievementUpdateType.unlock,
        updatingAchievementId: event.achievementId,
      ),
    );

    try {
      final success = await _achievementRepository.unlockAchievement(
        event.achievementId,
      );

      if (!success) {
        emit(
          AchievementError(
            message: 'Failed to unlock achievement',
            achievements: currentState.achievements,
            errorType: AchievementErrorType.general,
          ),
        );
        return;
      }

      // Get updated achievement
      final unlockedAchievement = await _achievementRepository
          .getAchievementById(event.achievementId);

      if (unlockedAchievement == null) {
        emit(
          AchievementError(
            message: 'Failed to refresh achievement after unlock',
            achievements: currentState.achievements,
            errorType: AchievementErrorType.general,
          ),
        );
        return;
      }

      // Update achievements list
      final updatedAchievements = currentState.achievements
          .map(
            (achievement) => achievement.id == unlockedAchievement.id
                ? unlockedAchievement
                : achievement,
          )
          .toList();

      emit(
        AchievementLoaded(
          achievements: updatedAchievements,
          filteredAchievements: currentState.filteredAchievements,
          activeFilter: currentState.activeFilter,
          sortType: currentState.sortType,
          searchQuery: currentState.searchQuery,
          showUnlockNotification: true,
          unlockedAchievement: unlockedAchievement,
          showCelebration: true,
          celebratingAchievement: unlockedAchievement,
          recentUnlocks: [...currentState.recentUnlocks, unlockedAchievement],
        ),
      );
    } on Exception catch (e) {
      emit(
        AchievementError(
          message: 'Failed to unlock achievement: ${e.toString()}',
          achievements: currentState.achievements,
          errorType: AchievementErrorType.general,
        ),
      );
    }
  }

  /// Handles checking and updating achievements based on user stats
  Future<void> _onCheckAndUpdateAchievements(
    CheckAndUpdateAchievements event,
    Emitter<AchievementState> emit,
  ) async {
    final currentState = state;
    if (currentState is! AchievementLoaded) return;

    emit(
      AchievementChecking(
        achievements: currentState.achievements,
        checkingType: AchievementCheckingType.single,
      ),
    );

    try {
      final newlyUnlockedAchievements = await _achievementRepository
          .checkAndUpdateAchievements(event.userId, event.userStats);

      if (newlyUnlockedAchievements.isEmpty) {
        emit(currentState);
        return;
      }

      // Refresh all achievements to get updated progress
      final allAchievements = await _achievementRepository
          .getAchievementsByUserId(event.userId);

      // Show celebration for the first newly unlocked achievement
      final firstUnlocked = newlyUnlockedAchievements.first;

      emit(
        AchievementLoaded(
          achievements: allAchievements,
          filteredAchievements: currentState.filteredAchievements,
          activeFilter: currentState.activeFilter,
          sortType: currentState.sortType,
          searchQuery: currentState.searchQuery,
          showUnlockNotification: true,
          unlockedAchievement: firstUnlocked,
          showCelebration: true,
          celebratingAchievement: firstUnlocked,
          recentUnlocks: [
            ...currentState.recentUnlocks,
            ...newlyUnlockedAchievements,
          ],
        ),
      );
    } on Exception catch (e) {
      emit(
        AchievementError(
          message: 'Failed to check and update achievements: ${e.toString()}',
          achievements: currentState.achievements,
          errorType: AchievementErrorType.criteriaEvaluation,
        ),
      );
    }
  }

  /// Handles batch checking criteria for multiple achievements
  Future<void> _onBatchCheckCriteria(
    BatchCheckCriteria event,
    Emitter<AchievementState> emit,
  ) async {
    final currentState = state;
    if (currentState is! AchievementLoaded) return;

    emit(
      AchievementChecking(
        achievements: currentState.achievements,
        checkingType: AchievementCheckingType.batch,
      ),
    );

    try {
      final newlyUnlockedAchievements = await _achievementRepository
          .batchCheckCriteria(event.userId, event.userStats);

      if (newlyUnlockedAchievements.isEmpty) {
        emit(currentState);
        return;
      }

      // Refresh all achievements to get updated progress
      final allAchievements = await _achievementRepository
          .getAchievementsByUserId(event.userId);

      // Show celebration for the first newly unlocked achievement
      final firstUnlocked = newlyUnlockedAchievements.first;

      emit(
        AchievementLoaded(
          achievements: allAchievements,
          filteredAchievements: currentState.filteredAchievements,
          activeFilter: currentState.activeFilter,
          sortType: currentState.sortType,
          searchQuery: currentState.searchQuery,
          showUnlockNotification: true,
          unlockedAchievement: firstUnlocked,
          showCelebration: true,
          celebratingAchievement: firstUnlocked,
          recentUnlocks: [
            ...currentState.recentUnlocks,
            ...newlyUnlockedAchievements,
          ],
        ),
      );
    } on Exception catch (e) {
      emit(
        AchievementError(
          message: 'Failed to batch check criteria: ${e.toString()}',
          achievements: currentState.achievements,
          errorType: AchievementErrorType.criteriaEvaluation,
        ),
      );
    }
  }

  /// Handles evaluating specific achievement criteria
  Future<void> _onEvaluateAchievementCriteria(
    EvaluateAchievementCriteria event,
    Emitter<AchievementState> emit,
  ) async {
    final currentState = state;
    if (currentState is! AchievementLoaded) return;

    emit(
      AchievementChecking(
        achievements: currentState.achievements,
        checkingType: AchievementCheckingType.criteria,
      ),
    );

    try {
      final meetsRequirements = _achievementRepository
          .evaluateAchievementCriteria(event.achievement, event.userStats);

      // If criteria are met and achievement is not unlocked, unlock it
      if (meetsRequirements && !event.achievement.isUnlocked) {
        add(UnlockAchievement(achievementId: event.achievement.id));
      } else {
        emit(currentState);
      }
    } on Exception catch (e) {
      emit(
        AchievementError(
          message: 'Failed to evaluate achievement criteria: ${e.toString()}',
          achievements: currentState.achievements,
          errorType: AchievementErrorType.criteriaEvaluation,
        ),
      );
    }
  }

  /// Handles calculating achievement progress
  Future<void> _onCalculateAchievementProgress(
    CalculateAchievementProgress event,
    Emitter<AchievementState> emit,
  ) async {
    final currentState = state;
    if (currentState is! AchievementLoaded) return;

    emit(
      AchievementChecking(
        achievements: currentState.achievements,
        checkingType: AchievementCheckingType.progress,
      ),
    );

    try {
      final calculatedProgress = _achievementRepository
          .calculateAchievementProgress(event.achievement, event.userStats);

      // Update the achievement progress if it's different
      if (calculatedProgress != event.achievement.progress) {
        add(
          UpdateAchievementProgress(
            achievementId: event.achievement.id,
            newProgress: calculatedProgress,
          ),
        );
      } else {
        emit(currentState);
      }
    } on Exception catch (e) {
      emit(
        AchievementError(
          message: 'Failed to calculate achievement progress: ${e.toString()}',
          achievements: currentState.achievements,
          errorType: AchievementErrorType.criteriaEvaluation,
        ),
      );
    }
  }

  /// Handles loading recent achievement unlocks
  Future<void> _onLoadRecentUnlocks(
    LoadRecentUnlocks event,
    Emitter<AchievementState> emit,
  ) async {
    final currentState = state;
    if (currentState is! AchievementLoaded) return;

    try {
      final recentUnlocks = await _achievementRepository.getRecentUnlocks(
        event.userId,
        days: event.days,
      );

      emit(currentState.copyWith(recentUnlocks: recentUnlocks));
    } on Exception catch (e) {
      emit(
        AchievementError(
          message: 'Failed to load recent unlocks: ${e.toString()}',
          achievements: currentState.achievements,
          errorType: AchievementErrorType.general,
        ),
      );
    }
  }

  /// Handles loading unlockable achievements
  Future<void> _onLoadUnlockableAchievements(
    LoadUnlockableAchievements event,
    Emitter<AchievementState> emit,
  ) async {
    final currentState = state;
    if (currentState is! AchievementLoaded) return;

    try {
      final unlockableAchievements = await _achievementRepository
          .getUnlockableAchievements(event.userId);

      final filter = const AchievementFilter(canUnlock: true);

      emit(
        currentState.copyWith(
          filteredAchievements: unlockableAchievements,
          activeFilter: filter,
        ),
      );
    } on Exception catch (e) {
      emit(
        AchievementError(
          message: 'Failed to load unlockable achievements: ${e.toString()}',
          achievements: currentState.achievements,
          errorType: AchievementErrorType.general,
        ),
      );
    }
  }

  /// Handles creating default achievements for new user
  Future<void> _onCreateDefaultAchievements(
    CreateDefaultAchievements event,
    Emitter<AchievementState> emit,
  ) async {
    emit(const AchievementLoading());

    try {
      await _achievementRepository.createDefaultAchievements(event.userId);

      // Load the newly created achievements
      final achievements = await _achievementRepository.getAchievementsByUserId(
        event.userId,
      );

      emit(AchievementLoaded(achievements: achievements));
    } on Exception catch (e) {
      emit(
        AchievementError(
          message: 'Failed to create default achievements: ${e.toString()}',
          errorType: AchievementErrorType.general,
        ),
      );
    }
  }

  /// Handles refreshing achievements
  Future<void> _onRefreshAchievements(
    RefreshAchievements event,
    Emitter<AchievementState> emit,
  ) async {
    try {
      final achievements = await _achievementRepository.getAchievementsByUserId(
        event.userId,
      );

      final currentState = state;
      if (currentState is AchievementLoaded) {
        emit(currentState.copyWith(achievements: achievements));
      } else {
        emit(AchievementLoaded(achievements: achievements));
      }
    } on Exception catch (e) {
      emit(
        AchievementError(
          message: 'Failed to refresh achievements: ${e.toString()}',
          errorType: AchievementErrorType.general,
        ),
      );
    }
  }

  /// Handles achievement unlock notification completion
  Future<void> _onAchievementUnlockNotificationCompleted(
    AchievementUnlockNotificationCompleted event,
    Emitter<AchievementState> emit,
  ) async {
    final currentState = state;
    if (currentState is! AchievementLoaded) return;

    emit(currentState.clearUnlockNotification());
  }

  /// Handles achievement celebration completion
  Future<void> _onAchievementCelebrationCompleted(
    AchievementCelebrationCompleted event,
    Emitter<AchievementState> emit,
  ) async {
    final currentState = state;
    if (currentState is! AchievementLoaded) return;

    emit(currentState.clearCelebration());
  }

  /// Handles filtering achievements
  Future<void> _onFilterAchievements(
    FilterAchievements event,
    Emitter<AchievementState> emit,
  ) async {
    final currentState = state;
    if (currentState is! AchievementLoaded) return;

    final filteredAchievements = currentState.achievements
        .where((achievement) => event.filter.matches(achievement))
        .toList();

    emit(
      currentState.copyWith(
        filteredAchievements: filteredAchievements,
        activeFilter: event.filter,
      ),
    );
  }

  /// Handles sorting achievements
  Future<void> _onSortAchievements(
    SortAchievements event,
    Emitter<AchievementState> emit,
  ) async {
    final currentState = state;
    if (currentState is! AchievementLoaded) return;

    final sortedAchievements = _sortAchievements(
      currentState.displayAchievements,
      event.sortType,
    );

    if (currentState.filteredAchievements != null) {
      emit(
        currentState.copyWith(
          filteredAchievements: sortedAchievements,
          sortType: event.sortType,
        ),
      );
    } else {
      emit(
        currentState.copyWith(
          achievements: sortedAchievements,
          sortType: event.sortType,
        ),
      );
    }
  }

  /// Handles searching achievements
  Future<void> _onSearchAchievements(
    SearchAchievements event,
    Emitter<AchievementState> emit,
  ) async {
    final currentState = state;
    if (currentState is! AchievementLoaded) return;

    if (event.query.isEmpty) {
      emit(currentState.copyWith(filteredAchievements: null, searchQuery: ''));
      return;
    }

    final searchResults = currentState.achievements.where((achievement) {
      final query = event.query.toLowerCase();
      return achievement.title.toLowerCase().contains(query) ||
          achievement.description.toLowerCase().contains(query) ||
          achievement.type.displayName.toLowerCase().contains(query);
    }).toList();

    emit(
      currentState.copyWith(
        filteredAchievements: searchResults,
        searchQuery: event.query,
      ),
    );
  }

  /// Handles clearing achievement filters
  Future<void> _onClearAchievementFilters(
    ClearAchievementFilters event,
    Emitter<AchievementState> emit,
  ) async {
    final currentState = state;
    if (currentState is! AchievementLoaded) return;

    emit(currentState.clearFilters());
  }

  // Achievement unlock handling is done through events, not direct stream listening

  // Private helper methods

  /// Sorts achievements based on the specified sort type
  List<Achievement> _sortAchievements(
    List<Achievement> achievements,
    AchievementSortType sortType,
  ) {
    final sortedAchievements = List<Achievement>.from(achievements);

    switch (sortType) {
      case AchievementSortType.title:
        sortedAchievements.sort((a, b) => a.title.compareTo(b.title));
        break;

      case AchievementSortType.type:
        sortedAchievements.sort((a, b) => a.type.name.compareTo(b.type.name));
        break;

      case AchievementSortType.progress:
        sortedAchievements.sort((a, b) => b.progress.compareTo(a.progress));
        break;

      case AchievementSortType.unlockedDate:
        sortedAchievements.sort((a, b) {
          if (a.unlockedAt == null && b.unlockedAt == null) return 0;
          if (a.unlockedAt == null) return 1;
          if (b.unlockedAt == null) return -1;
          return b.unlockedAt!.compareTo(a.unlockedAt!);
        });
        break;

      case AchievementSortType.createdDate:
        sortedAchievements.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;

      case AchievementSortType.badgeTier:
        sortedAchievements.sort(
          (a, b) => b.badgeTier.index.compareTo(a.badgeTier.index),
        );
        break;

      case AchievementSortType.canUnlock:
        sortedAchievements.sort((a, b) {
          if (a.canUnlock && !b.canUnlock) return -1;
          if (!a.canUnlock && b.canUnlock) return 1;
          return 0;
        });
        break;
    }

    return sortedAchievements;
  }

  @override
  Future<void> close() {
    _achievementUnlockSubscription?.cancel();
    _achievementRepository.dispose();
    return super.close();
  }
}

// FirstOrNull extension removed to avoid conflicts with repository extensions
