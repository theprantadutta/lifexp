import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/avatar.dart';
import '../../../data/repositories/avatar_repository.dart';
import 'avatar_event.dart';
import 'avatar_state.dart';

/// BLoC for managing avatar progression, XP calculations, and character customization
class AvatarBloc extends Bloc<AvatarEvent, AvatarState> {
  AvatarBloc({required AvatarRepository avatarRepository})
    : _avatarRepository = avatarRepository,
      super(const AvatarInitial()) {
    on<LoadAvatar>(_onLoadAvatar);
    on<CreateAvatar>(_onCreateAvatar);
    on<GainXP>(_onGainXP);
    on<IncreaseAttribute>(_onIncreaseAttribute);
    on<UpdateAppearance>(_onUpdateAppearance);
    on<UnlockItem>(_onUnlockItem);
    on<RefreshAvatar>(_onRefreshAvatar);
    on<LevelUpCelebrationCompleted>(_onLevelUpCelebrationCompleted);
    on<ApplyAttributeBonus>(_onApplyAttributeBonus);
    on<ItemUnlockNotificationCompleted>(_onItemUnlockNotificationCompleted);
  }

  final AvatarRepository _avatarRepository;

  /// Handles loading avatar data
  Future<void> _onLoadAvatar(
    LoadAvatar event,
    Emitter<AvatarState> emit,
  ) async {
    emit(const AvatarLoading());

    try {
      final avatar = await _avatarRepository.getAvatarByUserId(event.userId);

      if (avatar != null) {
        emit(AvatarLoaded(avatar: avatar));
      } else {
        emit(
          const AvatarError(
            message: 'No avatar found for this user',
            errorType: AvatarErrorType.notFound,
          ),
        );
      }
    } on Exception catch (e) {
      emit(
        AvatarError(
          message: 'Failed to load avatar: ${e.toString()}',
          errorType: AvatarErrorType.general,
        ),
      );
    }
  }

  /// Handles creating a new avatar
  Future<void> _onCreateAvatar(
    CreateAvatar event,
    Emitter<AvatarState> emit,
  ) async {
    emit(const AvatarCreating());

    try {
      final avatar = await _avatarRepository.createAvatar(
        userId: event.userId,
        name: event.name,
        appearance: event.appearance,
      );

      emit(
        AvatarLoaded(
          avatar: avatar,
          showCelebration: true,
          celebrationType: CelebrationType.majorMilestone,
        ),
      );
    } on Exception catch (e) {
      emit(
        AvatarError(
          message: 'Failed to create avatar: ${e.toString()}',
          errorType: AvatarErrorType.general,
        ),
      );
    }
  }

  /// Handles XP gain with level up logic and celebrations
  Future<void> _onGainXP(GainXP event, Emitter<AvatarState> emit) async {
    final currentState = state;
    if (currentState is! AvatarLoaded) return;

    final previousAvatar = currentState.avatar;
    final previousLevel = previousAvatar.level;

    emit(
      AvatarUpdating(
        avatar: previousAvatar,
        updateType: AvatarUpdateType.xpGain,
      ),
    );

    try {
      final updatedAvatar = await _avatarRepository.gainXP(
        event.avatarId,
        event.xpAmount,
      );

      if (updatedAvatar == null) {
        emit(
          AvatarError(
            message: 'Failed to gain XP',
            avatar: previousAvatar,
            errorType: AvatarErrorType.general,
          ),
        );
        return;
      }

      final newLevel = updatedAvatar.level;
      final didLevelUp = newLevel > previousLevel;

      if (didLevelUp) {
        // Calculate level up data
        final levelUpData = LevelUpData(
          previousLevel: previousLevel,
          newLevel: newLevel,
          xpGained: event.xpAmount,
          attributeIncreases: _calculateAttributeIncreases(
            previousLevel,
            newLevel,
          ),
          newUnlocks: _calculateNewUnlocks(previousLevel, newLevel),
        );

        emit(
          AvatarLoaded(
            avatar: updatedAvatar,
            isLevelingUp: true,
            levelUpData: levelUpData,
            showCelebration: true,
            celebrationType: CelebrationType.levelUp,
            unlockedItems: levelUpData.newUnlocks,
          ),
        );
      } else {
        emit(AvatarLoaded(avatar: updatedAvatar));
      }
    } on Exception catch (e) {
      emit(
        AvatarError(
          message: 'Failed to gain XP: ${e.toString()}',
          avatar: previousAvatar,
          errorType: AvatarErrorType.general,
        ),
      );
    }
  }

  /// Handles attribute increases
  Future<void> _onIncreaseAttribute(
    IncreaseAttribute event,
    Emitter<AvatarState> emit,
  ) async {
    final currentState = state;
    if (currentState is! AvatarLoaded) return;

    final previousAvatar = currentState.avatar;

    emit(
      AvatarUpdating(
        avatar: previousAvatar,
        updateType: AvatarUpdateType.attributeIncrease,
      ),
    );

    try {
      final updatedAvatar = await _avatarRepository.increaseAttribute(
        event.avatarId,
        event.attributeType,
        event.amount,
      );

      if (updatedAvatar == null) {
        emit(
          AvatarError(
            message: 'Failed to increase attribute',
            avatar: previousAvatar,
            errorType: AvatarErrorType.general,
          ),
        );
        return;
      }

      // Check if this triggers any attribute bonuses
      final bonuses = _checkAttributeBonuses(updatedAvatar);
      final showCelebration = bonuses.isNotEmpty;

      emit(
        AvatarLoaded(
          avatar: updatedAvatar,
          attributeBonuses: bonuses,
          showCelebration: showCelebration,
          celebrationType: showCelebration
              ? CelebrationType.attributeBonus
              : null,
        ),
      );
    } on Exception catch (e) {
      emit(
        AvatarError(
          message: 'Failed to increase attribute: ${e.toString()}',
          avatar: previousAvatar,
          errorType: AvatarErrorType.general,
        ),
      );
    }
  }

  /// Handles appearance updates
  Future<void> _onUpdateAppearance(
    UpdateAppearance event,
    Emitter<AvatarState> emit,
  ) async {
    final currentState = state;
    if (currentState is! AvatarLoaded) return;

    final previousAvatar = currentState.avatar;

    emit(
      AvatarUpdating(
        avatar: previousAvatar,
        updateType: AvatarUpdateType.appearanceUpdate,
      ),
    );

    try {
      final updatedAvatar = await _avatarRepository.updateAppearance(
        event.avatarId,
        event.appearance,
      );

      if (updatedAvatar == null) {
        emit(
          AvatarError(
            message: 'Failed to update appearance',
            avatar: previousAvatar,
            errorType: AvatarErrorType.general,
          ),
        );
        return;
      }

      emit(AvatarLoaded(avatar: updatedAvatar));
    } on Exception catch (e) {
      emit(
        AvatarError(
          message: 'Failed to update appearance: ${e.toString()}',
          avatar: previousAvatar,
          errorType: AvatarErrorType.general,
        ),
      );
    }
  }

  /// Handles item unlocking
  Future<void> _onUnlockItem(
    UnlockItem event,
    Emitter<AvatarState> emit,
  ) async {
    final currentState = state;
    if (currentState is! AvatarLoaded) return;

    final previousAvatar = currentState.avatar;

    emit(
      AvatarUpdating(
        avatar: previousAvatar,
        updateType: AvatarUpdateType.itemUnlock,
      ),
    );

    try {
      final success = await _avatarRepository.unlockItem(
        event.avatarId,
        event.itemId,
      );

      if (!success) {
        emit(
          AvatarError(
            message: 'Failed to unlock item',
            avatar: previousAvatar,
            errorType: AvatarErrorType.general,
          ),
        );
        return;
      }

      // Get updated avatar
      final updatedAvatar = await _avatarRepository.getAvatarById(
        event.avatarId,
      );

      if (updatedAvatar == null) {
        emit(
          AvatarError(
            message: 'Failed to refresh avatar after item unlock',
            avatar: previousAvatar,
            errorType: AvatarErrorType.general,
          ),
        );
        return;
      }

      emit(
        AvatarLoaded(
          avatar: updatedAvatar,
          unlockedItems: [event.itemId],
          showCelebration: true,
          celebrationType: CelebrationType.itemUnlock,
        ),
      );
    } on Exception catch (e) {
      emit(
        AvatarError(
          message: 'Failed to unlock item: ${e.toString()}',
          avatar: previousAvatar,
          errorType: AvatarErrorType.general,
        ),
      );
    }
  }

  /// Handles avatar refresh
  Future<void> _onRefreshAvatar(
    RefreshAvatar event,
    Emitter<AvatarState> emit,
  ) async {
    final currentState = state;
    Avatar? currentAvatar;

    if (currentState is AvatarLoaded) {
      currentAvatar = currentState.avatar;
    } else if (currentState is AvatarError) {
      currentAvatar = currentState.avatar;
    }

    try {
      final avatar = await _avatarRepository.getAvatarById(event.avatarId);

      if (avatar != null) {
        emit(AvatarLoaded(avatar: avatar));
      } else {
        emit(
          AvatarError(
            message: 'Avatar not found',
            avatar: currentAvatar,
            errorType: AvatarErrorType.notFound,
          ),
        );
      }
    } on Exception catch (e) {
      emit(
        AvatarError(
          message: 'Failed to refresh avatar: ${e.toString()}',
          avatar: currentAvatar,
          errorType: AvatarErrorType.general,
        ),
      );
    }
  }

  /// Handles level up celebration completion
  Future<void> _onLevelUpCelebrationCompleted(
    LevelUpCelebrationCompleted event,
    Emitter<AvatarState> emit,
  ) async {
    final currentState = state;
    if (currentState is! AvatarLoaded) return;

    emit(
      currentState.copyWith(
        isLevelingUp: false,
        showCelebration: false,
        celebrationType: null,
        levelUpData: null,
      ),
    );
  }

  /// Handles attribute bonus application
  Future<void> _onApplyAttributeBonus(
    ApplyAttributeBonus event,
    Emitter<AvatarState> emit,
  ) async {
    final currentState = state;
    if (currentState is! AvatarLoaded) return;

    try {
      Avatar updatedAvatar = currentState.avatar;

      // Apply each bonus
      for (final entry in event.bonuses.entries) {
        final result = await _avatarRepository.increaseAttribute(
          event.avatarId,
          entry.key,
          entry.value,
        );
        if (result != null) {
          updatedAvatar = result;
        }
      }

      emit(
        AvatarLoaded(
          avatar: updatedAvatar,
          attributeBonuses: event.bonuses,
          showCelebration: true,
          celebrationType: CelebrationType.attributeBonus,
        ),
      );
    } on Exception catch (e) {
      emit(
        AvatarError(
          message: 'Failed to apply attribute bonuses: ${e.toString()}',
          avatar: currentState.avatar,
          errorType: AvatarErrorType.general,
        ),
      );
    }
  }

  /// Handles item unlock notification completion
  Future<void> _onItemUnlockNotificationCompleted(
    ItemUnlockNotificationCompleted event,
    Emitter<AvatarState> emit,
  ) async {
    final currentState = state;
    if (currentState is! AvatarLoaded) return;

    emit(currentState.clearCelebration());
  }

  // Private helper methods

  /// Calculates attribute increases for level progression
  Map<AttributeType, int> _calculateAttributeIncreases(
    int previousLevel,
    int newLevel,
  ) {
    final levelDifference = newLevel - previousLevel;
    final baseIncrease = levelDifference * 2; // 2 points per level

    return {
      AttributeType.strength: baseIncrease,
      AttributeType.wisdom: baseIncrease,
      AttributeType.intelligence: baseIncrease,
    };
  }

  /// Calculates new unlocks based on level progression
  List<String> _calculateNewUnlocks(int previousLevel, int newLevel) {
    final unlocks = <String>[];

    for (var level = previousLevel + 1; level <= newLevel; level++) {
      switch (level) {
        case 5:
          unlocks.add('basic_sword');
          break;
        case 10:
          unlocks.add('leather_armor');
          break;
        case 15:
          unlocks.add('magic_staff');
          break;
        case 20:
          unlocks.add('steel_armor');
          break;
        case 25:
          unlocks.add('enchanted_cloak');
          break;
        case 30:
          unlocks.add('dragon_sword');
          break;
        case 40:
          unlocks.add('mythril_armor');
          break;
        case 50:
          unlocks.add('legendary_weapon');
          break;
      }
    }

    return unlocks;
  }

  /// Checks for attribute bonuses based on milestones
  Map<AttributeType, int> _checkAttributeBonuses(Avatar avatar) {
    final bonuses = <AttributeType, int>{};

    // Check for milestone bonuses
    if (avatar.strength > 0 && avatar.strength % 50 == 0) {
      bonuses[AttributeType.strength] = 5; // Bonus for reaching multiples of 50
    }
    if (avatar.wisdom > 0 && avatar.wisdom % 50 == 0) {
      bonuses[AttributeType.wisdom] = 5;
    }
    if (avatar.intelligence > 0 && avatar.intelligence % 50 == 0) {
      bonuses[AttributeType.intelligence] = 5;
    }

    return bonuses;
  }

  @override
  Future<void> close() {
    _avatarRepository.dispose();
    return super.close();
  }
}
