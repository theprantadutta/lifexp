import 'package:equatable/equatable.dart';

/// Represents the user's avatar with progression system
class Avatar extends Equatable {
  const Avatar({
    required this.id,
    required this.name,
    required this.level,
    required this.currentXP,
    required this.strength,
    required this.wisdom,
    required this.intelligence,
    required this.appearance,
    required this.unlockedItems,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Creates a new avatar with default values
  factory Avatar.create({
    required String id,
    required String name,
    AvatarAppearance? appearance,
  }) {
    final now = DateTime.now();
    return Avatar(
      id: id,
      name: name,
      level: 1,
      currentXP: 0,
      strength: 0,
      wisdom: 0,
      intelligence: 0,
      appearance: appearance ?? AvatarAppearance.defaultAppearance(),
      unlockedItems: const [],
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Creates from JSON
  factory Avatar.fromJson(Map<String, dynamic> json) => Avatar(
    id: json['id'] as String,
    name: json['name'] as String,
    level: json['level'] as int,
    currentXP: json['currentXP'] as int,
    strength: json['strength'] as int,
    wisdom: json['wisdom'] as int,
    intelligence: json['intelligence'] as int,
    appearance: AvatarAppearance.fromJson(
      json['appearance'] as Map<String, dynamic>,
    ),
    unlockedItems: List<String>.from(json['unlockedItems'] as List),
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );
  final String id;
  final String name;
  final int level;
  final int currentXP;
  final int strength;
  final int wisdom;
  final int intelligence;
  final AvatarAppearance appearance;
  final List<String> unlockedItems;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Maximum level allowed
  static const int maxLevel = 100;

  /// Maximum attribute value
  static const int maxAttributeValue = 999;

  /// XP required for each level (exponential growth)
  static int xpRequiredForLevel(int level) {
    if (level <= 1) return 0;
    return (100 * (level - 1) * (level - 1) * 0.8).round();
  }

  /// Calculate XP needed to reach next level
  int get xpToNextLevel {
    if (level >= maxLevel) return 0;
    return xpRequiredForLevel(level + 1) - currentXP;
  }

  /// Calculate total XP needed for current level
  int get xpRequiredForCurrentLevel => xpRequiredForLevel(level);

  /// Calculate progress percentage to next level (0.0 to 1.0)
  double get progressToNextLevel {
    if (level >= maxLevel) return 1;

    final currentLevelXP = xpRequiredForCurrentLevel;
    final nextLevelXP = xpRequiredForLevel(level + 1);
    final xpInCurrentLevel = currentXP - currentLevelXP;
    final xpNeededForLevel = nextLevelXP - currentLevelXP;

    return (xpInCurrentLevel / xpNeededForLevel).clamp(0.0, 1.0);
  }

  /// Total attribute points
  int get totalAttributes => strength + wisdom + intelligence;

  /// Validates avatar data
  bool get isValid =>
      _validateName() &&
      _validateLevel() &&
      _validateXP() &&
      _validateAttributes() &&
      _validateUnlockedItems();

  /// Validates avatar name
  bool _validateName() => name.isNotEmpty && name.length <= 50;

  /// Validates level bounds
  bool _validateLevel() => level >= 1 && level <= maxLevel;

  /// Validates XP consistency with level
  bool _validateXP() {
    if (currentXP < 0) return false;

    final minXPForLevel = xpRequiredForCurrentLevel;
    final maxXPForLevel = level >= maxLevel
        ? double.infinity
        : xpRequiredForLevel(level + 1) - 1;

    return currentXP >= minXPForLevel && currentXP <= maxXPForLevel;
  }

  /// Validates attribute bounds
  bool _validateAttributes() =>
      strength >= 0 &&
      strength <= maxAttributeValue &&
      wisdom >= 0 &&
      wisdom <= maxAttributeValue &&
      intelligence >= 0 &&
      intelligence <= maxAttributeValue;

  /// Validates unlocked items list
  bool _validateUnlockedItems() =>
      unlockedItems.every((item) => item.isNotEmpty);

  /// Gains XP and handles level progression
  Avatar gainXP(int xpAmount) {
    if (xpAmount <= 0) return this;

    final newXP = currentXP + xpAmount;
    final newLevel = _calculateLevelFromXP(newXP);

    // Calculate attribute increases based on level progression
    final levelDifference = newLevel - level;
    final attributeIncrease = levelDifference * 2; // 2 points per level

    return copyWith(
      currentXP: newXP,
      level: newLevel,
      strength: strength + attributeIncrease,
      wisdom: wisdom + attributeIncrease,
      intelligence: intelligence + attributeIncrease,
      updatedAt: DateTime.now(),
    );
  }

  /// Calculates level based on total XP
  int _calculateLevelFromXP(int totalXP) {
    for (var level = 1; level <= maxLevel; level++) {
      if (totalXP < xpRequiredForLevel(level + 1)) {
        return level;
      }
    }
    return maxLevel;
  }

  /// Increases specific attribute
  Avatar increaseAttribute(AttributeType type, int amount) {
    if (amount <= 0) return this;

    switch (type) {
      case AttributeType.strength:
        final newStrength = (strength + amount).clamp(0, maxAttributeValue);
        return copyWith(strength: newStrength, updatedAt: DateTime.now());
      case AttributeType.wisdom:
        final newWisdom = (wisdom + amount).clamp(0, maxAttributeValue);
        return copyWith(wisdom: newWisdom, updatedAt: DateTime.now());
      case AttributeType.intelligence:
        final newIntelligence = (intelligence + amount).clamp(
          0,
          maxAttributeValue,
        );
        return copyWith(
          intelligence: newIntelligence,
          updatedAt: DateTime.now(),
        );
    }
  }

  /// Unlocks a new item
  Avatar unlockItem(String itemId) {
    if (unlockedItems.contains(itemId)) return this;

    return copyWith(
      unlockedItems: [...unlockedItems, itemId],
      updatedAt: DateTime.now(),
    );
  }

  /// Checks if an item is unlocked
  bool hasUnlockedItem(String itemId) => unlockedItems.contains(itemId);

  /// Updates avatar appearance
  Avatar updateAppearance(AvatarAppearance newAppearance) =>
      copyWith(appearance: newAppearance, updatedAt: DateTime.now());

  /// Creates a copy with updated fields
  Avatar copyWith({
    String? id,
    String? name,
    int? level,
    int? currentXP,
    int? strength,
    int? wisdom,
    int? intelligence,
    AvatarAppearance? appearance,
    List<String>? unlockedItems,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Avatar(
    id: id ?? this.id,
    name: name ?? this.name,
    level: level ?? this.level,
    currentXP: currentXP ?? this.currentXP,
    strength: strength ?? this.strength,
    wisdom: wisdom ?? this.wisdom,
    intelligence: intelligence ?? this.intelligence,
    appearance: appearance ?? this.appearance,
    unlockedItems: unlockedItems ?? this.unlockedItems,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  /// Converts to JSON
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'level': level,
    'currentXP': currentXP,
    'strength': strength,
    'wisdom': wisdom,
    'intelligence': intelligence,
    'appearance': appearance.toJson(),
    'unlockedItems': unlockedItems,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  /// Converts to Map (alias for toJson for repository compatibility)
  Map<String, dynamic> toMap() => toJson();

  @override
  List<Object?> get props => [
    id,
    name,
    level,
    currentXP,
    strength,
    wisdom,
    intelligence,
    appearance,
    unlockedItems,
    createdAt,
    updatedAt,
  ];

  @override
  String toString() =>
      'Avatar(id: $id, name: $name, level: $level, xp: $currentXP, '
      'str: $strength, wis: $wisdom, int: $intelligence)';
}

/// Enum for attribute types
enum AttributeType { strength, wisdom, intelligence }

/// Represents avatar appearance customization
class AvatarAppearance extends Equatable {
  const AvatarAppearance({
    required this.skinTone,
    required this.hairStyle,
    required this.hairColor,
    required this.eyeColor,
    required this.clothing,
    required this.accessories,
  });

  /// Creates default appearance
  factory AvatarAppearance.defaultAppearance() => const AvatarAppearance(
    skinTone: 'medium',
    hairStyle: 'short',
    hairColor: 'brown',
    eyeColor: 'brown',
    clothing: 'casual',
    accessories: 'none',
  );

  /// Creates from JSON
  factory AvatarAppearance.fromJson(Map<String, dynamic> json) =>
      AvatarAppearance(
        skinTone: json['skinTone'] as String,
        hairStyle: json['hairStyle'] as String,
        hairColor: json['hairColor'] as String,
        eyeColor: json['eyeColor'] as String,
        clothing: json['clothing'] as String,
        accessories: json['accessories'] as String,
      );
  final String skinTone;
  final String hairStyle;
  final String hairColor;
  final String eyeColor;
  final String clothing;
  final String accessories;

  /// Creates a copy with updated fields
  AvatarAppearance copyWith({
    String? skinTone,
    String? hairStyle,
    String? hairColor,
    String? eyeColor,
    String? clothing,
    String? accessories,
  }) => AvatarAppearance(
    skinTone: skinTone ?? this.skinTone,
    hairStyle: hairStyle ?? this.hairStyle,
    hairColor: hairColor ?? this.hairColor,
    eyeColor: eyeColor ?? this.eyeColor,
    clothing: clothing ?? this.clothing,
    accessories: accessories ?? this.accessories,
  );

  /// Converts to JSON
  Map<String, dynamic> toJson() => {
    'skinTone': skinTone,
    'hairStyle': hairStyle,
    'hairColor': hairColor,
    'eyeColor': eyeColor,
    'clothing': clothing,
    'accessories': accessories,
  };

  @override
  List<Object?> get props => [
    skinTone,
    hairStyle,
    hairColor,
    eyeColor,
    clothing,
    accessories,
  ];
}
