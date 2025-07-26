import 'package:equatable/equatable.dart';

/// Represents a tile in the user's world map
class WorldTile extends Equatable {
  const WorldTile({
    required this.id,
    required this.name,
    required this.description,
    required this.imagePath,
    required this.type,
    required this.isUnlocked,
    required this.unlockRequirement,
    required this.positionX,
    required this.positionY,
    required this.createdAt,
    required this.updatedAt,
    this.unlockCategory,
    this.unlockedAt,
    this.customProperties = const {},
  });

  /// Creates a new world tile with default values
  factory WorldTile.create({
    required String id,
    required String name,
    required String imagePath,
    required TileType type,
    required int unlockRequirement,
    required int positionX,
    required int positionY,
    String description = '',
    String? unlockCategory,
    Map<String, dynamic> customProperties = const {},
  }) {
    final now = DateTime.now();
    return WorldTile(
      id: id,
      name: name,
      description: description,
      imagePath: imagePath,
      type: type,
      isUnlocked: false,
      unlockRequirement: unlockRequirement,
      unlockCategory: unlockCategory,
      positionX: positionX,
      positionY: positionY,
      customProperties: customProperties,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Creates from JSON
  factory WorldTile.fromJson(Map<String, dynamic> json) => WorldTile(
    id: json['id'] as String,
    name: json['name'] as String,
    description: json['description'] as String,
    imagePath: json['imagePath'] as String,
    type: TileType.values.byName(json['type'] as String),
    isUnlocked: json['isUnlocked'] as bool,
    unlockRequirement: json['unlockRequirement'] as int,
    unlockCategory: json['unlockCategory'] as String?,
    positionX: json['positionX'] as int,
    positionY: json['positionY'] as int,
    unlockedAt: json['unlockedAt'] != null
        ? DateTime.parse(json['unlockedAt'] as String)
        : null,
    customProperties: Map<String, dynamic>.from(
      json['customProperties'] as Map? ?? {},
    ),
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );
  final String id;
  final String name;
  final String description;
  final String imagePath;
  final TileType type;
  final bool isUnlocked;
  final int unlockRequirement;
  final String? unlockCategory; // Category requirement for unlocking
  final int positionX;
  final int positionY;
  final DateTime? unlockedAt;
  final Map<String, dynamic> customProperties;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Maximum unlock requirement value
  static const int maxUnlockRequirement = 999999;

  /// Maximum position coordinate
  static const int maxPosition = 1000;

  /// Validates world tile data
  bool get isValid =>
      _validateName() &&
      _validateDescription() &&
      _validateImagePath() &&
      _validateUnlockRequirement() &&
      _validatePosition() &&
      _validateUnlockState();

  /// Validates tile name
  bool _validateName() => name.isNotEmpty && name.length <= 100;

  /// Validates tile description
  bool _validateDescription() => description.length <= 500;

  /// Validates image path
  bool _validateImagePath() => imagePath.isNotEmpty;

  /// Validates unlock requirement
  bool _validateUnlockRequirement() =>
      unlockRequirement >= 0 && unlockRequirement <= maxUnlockRequirement;

  /// Validates position coordinates
  bool _validatePosition() =>
      positionX >= 0 &&
      positionX <= maxPosition &&
      positionY >= 0 &&
      positionY <= maxPosition;

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

  /// Checks if tile can be unlocked based on current progress
  bool canUnlock({
    required int currentXP,
    required Map<String, int> categoryProgress,
  }) {
    if (isUnlocked) {
      return false;
    }

    // Check XP requirement
    if (currentXP < unlockRequirement) {
      return false;
    }

    // Check category requirement if specified
    if (unlockCategory != null) {
      final categoryXP = categoryProgress[unlockCategory] ?? 0;
      return categoryXP >= unlockRequirement;
    }

    return true;
  }

  /// Unlocks the tile
  WorldTile unlock() {
    if (isUnlocked) {
      return this;
    }

    return copyWith(
      isUnlocked: true,
      unlockedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Locks the tile (for testing or admin purposes)
  WorldTile lock() {
    if (!isUnlocked) {
      return this;
    }

    return WorldTile(
      id: id,
      name: name,
      description: description,
      imagePath: imagePath,
      type: type,
      isUnlocked: false,
      unlockRequirement: unlockRequirement,
      unlockCategory: unlockCategory,
      positionX: positionX,
      positionY: positionY,
      customProperties: customProperties,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  /// Updates tile position
  WorldTile updatePosition(int newX, int newY) {
    if (newX < 0 || newX > maxPosition || newY < 0 || newY > maxPosition) {
      return this;
    }

    return copyWith(
      positionX: newX,
      positionY: newY,
      updatedAt: DateTime.now(),
    );
  }

  /// Updates custom properties
  WorldTile updateCustomProperties(Map<String, dynamic> newProperties) =>
      copyWith(
        customProperties: {...customProperties, ...newProperties},
        updatedAt: DateTime.now(),
      );

  /// Gets distance to another tile
  double distanceTo(WorldTile other) {
    final dx = positionX - other.positionX;
    final dy = positionY - other.positionY;
    return (dx * dx + dy * dy).toDouble();
  }

  /// Checks if tile is adjacent to another tile
  bool isAdjacentTo(WorldTile other) {
    final dx = (positionX - other.positionX).abs();
    final dy = (positionY - other.positionY).abs();
    return (dx <= 1 && dy <= 1) && !(dx == 0 && dy == 0);
  }

  /// Creates a copy with updated fields
  WorldTile copyWith({
    String? id,
    String? name,
    String? description,
    String? imagePath,
    TileType? type,
    bool? isUnlocked,
    int? unlockRequirement,
    String? unlockCategory,
    int? positionX,
    int? positionY,
    DateTime? unlockedAt,
    Map<String, dynamic>? customProperties,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => WorldTile(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description ?? this.description,
    imagePath: imagePath ?? this.imagePath,
    type: type ?? this.type,
    isUnlocked: isUnlocked ?? this.isUnlocked,
    unlockRequirement: unlockRequirement ?? this.unlockRequirement,
    unlockCategory: unlockCategory ?? this.unlockCategory,
    positionX: positionX ?? this.positionX,
    positionY: positionY ?? this.positionY,
    unlockedAt: unlockedAt ?? this.unlockedAt,
    customProperties: customProperties ?? this.customProperties,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  /// Converts to JSON
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'imagePath': imagePath,
    'type': type.name,
    'isUnlocked': isUnlocked,
    'unlockRequirement': unlockRequirement,
    'unlockCategory': unlockCategory,
    'positionX': positionX,
    'positionY': positionY,
    'unlockedAt': unlockedAt?.toIso8601String(),
    'customProperties': customProperties,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    imagePath,
    type,
    isUnlocked,
    unlockRequirement,
    unlockCategory,
    positionX,
    positionY,
    unlockedAt,
    customProperties,
    createdAt,
    updatedAt,
  ];

  @override
  String toString() =>
      'WorldTile(id: $id, name: $name, type: $type, '
      'position: ($positionX, $positionY), unlocked: $isUnlocked, '
      'requirement: $unlockRequirement)';
}

/// Enum for tile types
enum TileType {
  grass,
  forest,
  mountain,
  water,
  desert,
  city,
  building,
  special,
}

/// Extension to get display names for tile types
extension TileTypeExtension on TileType {
  String get displayName {
    switch (this) {
      case TileType.grass:
        return 'Grass';
      case TileType.forest:
        return 'Forest';
      case TileType.mountain:
        return 'Mountain';
      case TileType.water:
        return 'Water';
      case TileType.desert:
        return 'Desert';
      case TileType.city:
        return 'City';
      case TileType.building:
        return 'Building';
      case TileType.special:
        return 'Special';
    }
  }

  String get icon {
    switch (this) {
      case TileType.grass:
        return '🌱';
      case TileType.forest:
        return '🌲';
      case TileType.mountain:
        return '⛰️';
      case TileType.water:
        return '💧';
      case TileType.desert:
        return '🏜️';
      case TileType.city:
        return '🏙️';
      case TileType.building:
        return '🏢';
      case TileType.special:
        return '✨';
    }
  }
}
