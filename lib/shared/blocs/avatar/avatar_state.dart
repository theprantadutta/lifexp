import 'package:equatable/equatable.dart';

import '../../../data/models/avatar.dart';

/// Base class for all avatar states
abstract class AvatarState extends Equatable {
  const AvatarState();

  @override
  List<Object?> get props => [];
}

/// Initial state when no avatar is loaded
class AvatarInitial extends AvatarState {
  const AvatarInitial();
}

/// State when avatar is being loaded
class AvatarLoading extends AvatarState {
  const AvatarLoading();
}

/// State when avatar is successfully loaded
class AvatarLoaded extends AvatarState {
  const AvatarLoaded({
    required this.avatar,
    this.isLevelingUp = false,
    this.levelUpData,
    this.unlockedItems = const [],
    this.attributeBonuses = const {},
    this.showCelebration = false,
    this.celebrationType,
  });

  final Avatar avatar;
  final bool isLevelingUp;
  final LevelUpData? levelUpData;
  final List<String> unlockedItems;
  final Map<AttributeType, int> attributeBonuses;
  final bool showCelebration;
  final CelebrationType? celebrationType;

  @override
  List<Object?> get props => [
    avatar,
    isLevelingUp,
    levelUpData,
    unlockedItems,
    attributeBonuses,
    showCelebration,
    celebrationType,
  ];

  /// Creates a copy with updated fields
  AvatarLoaded copyWith({
    Avatar? avatar,
    bool? isLevelingUp,
    LevelUpData? levelUpData,
    List<String>? unlockedItems,
    Map<AttributeType, int>? attributeBonuses,
    bool? showCelebration,
    CelebrationType? celebrationType,
  }) => AvatarLoaded(
    avatar: avatar ?? this.avatar,
    isLevelingUp: isLevelingUp ?? this.isLevelingUp,
    levelUpData: levelUpData ?? this.levelUpData,
    unlockedItems: unlockedItems ?? this.unlockedItems,
    attributeBonuses: attributeBonuses ?? this.attributeBonuses,
    showCelebration: showCelebration ?? this.showCelebration,
    celebrationType: celebrationType ?? this.celebrationType,
  );

  /// Clears celebration state
  AvatarLoaded clearCelebration() => copyWith(
    showCelebration: false,
    celebrationType: null,
    levelUpData: null,
    unlockedItems: const [],
    attributeBonuses: const {},
  );
}

/// State when avatar operation fails
class AvatarError extends AvatarState {
  const AvatarError({
    required this.message,
    this.avatar,
    this.errorType = AvatarErrorType.general,
  });

  final String message;
  final Avatar? avatar; // Keep current avatar if available
  final AvatarErrorType errorType;

  @override
  List<Object?> get props => [message, avatar, errorType];
}

/// State when avatar is being updated
class AvatarUpdating extends AvatarState {
  const AvatarUpdating({required this.avatar, required this.updateType});

  final Avatar avatar;
  final AvatarUpdateType updateType;

  @override
  List<Object?> get props => [avatar, updateType];
}

/// State when avatar creation is in progress
class AvatarCreating extends AvatarState {
  const AvatarCreating();
}

/// Data class for level up information
class LevelUpData extends Equatable {
  const LevelUpData({
    required this.previousLevel,
    required this.newLevel,
    required this.xpGained,
    required this.attributeIncreases,
    required this.newUnlocks,
  });

  final int previousLevel;
  final int newLevel;
  final int xpGained;
  final Map<AttributeType, int> attributeIncreases;
  final List<String> newUnlocks;

  @override
  List<Object?> get props => [
    previousLevel,
    newLevel,
    xpGained,
    attributeIncreases,
    newUnlocks,
  ];
}

/// Enum for different types of celebrations
enum CelebrationType { levelUp, itemUnlock, attributeBonus, majorMilestone }

/// Enum for different types of avatar errors
enum AvatarErrorType { general, network, validation, notFound, unauthorized }

/// Enum for different types of avatar updates
enum AvatarUpdateType {
  xpGain,
  attributeIncrease,
  appearanceUpdate,
  itemUnlock,
  creation,
}
