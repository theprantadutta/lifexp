import 'package:equatable/equatable.dart';

import '../../../data/models/avatar.dart';

/// Base class for all avatar events
abstract class AvatarEvent extends Equatable {
  const AvatarEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load avatar data
class LoadAvatar extends AvatarEvent {
  const LoadAvatar({required this.userId});

  final String userId;

  @override
  List<Object?> get props => [userId];
}

/// Event to gain XP
class GainXP extends AvatarEvent {
  const GainXP({required this.avatarId, required this.xpAmount, this.source});

  final String avatarId;
  final int xpAmount;
  final String? source; // e.g., 'task_completion', 'bonus'

  @override
  List<Object?> get props => [avatarId, xpAmount, source];
}

/// Event to increase specific attribute
class IncreaseAttribute extends AvatarEvent {
  const IncreaseAttribute({
    required this.avatarId,
    required this.attributeType,
    required this.amount,
  });

  final String avatarId;
  final AttributeType attributeType;
  final int amount;

  @override
  List<Object?> get props => [avatarId, attributeType, amount];
}

/// Event to update avatar appearance
class UpdateAppearance extends AvatarEvent {
  const UpdateAppearance({required this.avatarId, required this.appearance});

  final String avatarId;
  final AvatarAppearance appearance;

  @override
  List<Object?> get props => [avatarId, appearance];
}

/// Event to unlock item
class UnlockItem extends AvatarEvent {
  const UnlockItem({required this.avatarId, required this.itemId});

  final String avatarId;
  final String itemId;

  @override
  List<Object?> get props => [avatarId, itemId];
}

/// Event to create new avatar
class CreateAvatar extends AvatarEvent {
  const CreateAvatar({
    required this.userId,
    required this.name,
    this.appearance,
  });

  final String userId;
  final String name;
  final AvatarAppearance? appearance;

  @override
  List<Object?> get props => [userId, name, appearance];
}

/// Event to refresh avatar data
class RefreshAvatar extends AvatarEvent {
  const RefreshAvatar({required this.avatarId});

  final String avatarId;

  @override
  List<Object?> get props => [avatarId];
}

/// Event to handle level up celebration completion
class LevelUpCelebrationCompleted extends AvatarEvent {
  const LevelUpCelebrationCompleted({required this.avatarId});

  final String avatarId;

  @override
  List<Object?> get props => [avatarId];
}

/// Event to handle attribute bonus application
class ApplyAttributeBonus extends AvatarEvent {
  const ApplyAttributeBonus({required this.avatarId, required this.bonuses});

  final String avatarId;
  final Map<AttributeType, int> bonuses;

  @override
  List<Object?> get props => [avatarId, bonuses];
}

/// Event to handle item unlock notification completion
class ItemUnlockNotificationCompleted extends AvatarEvent {
  const ItemUnlockNotificationCompleted({
    required this.avatarId,
    required this.itemId,
  });

  final String avatarId;
  final String itemId;

  @override
  List<Object?> get props => [avatarId, itemId];
}
