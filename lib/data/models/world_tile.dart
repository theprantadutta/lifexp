import 'package:equatable/equatable.dart';

/// Enum for different tile types in the world
enum TileType {
  forest,
  mountain,
  water,
  desert,
  city,
  special,
  building,
  grass,
}

/// Model representing a tile in the world map
class WorldTile extends Equatable {
  const WorldTile({
    required this.id,
    required this.x,
    required this.y,
    required this.type,
    required this.name,
    required this.description,
    required this.unlockRequirement,
    required this.isUnlocked,
    this.rewards = const [],
    this.customizations = const {},
  });

  /// Creates a WorldTile from a map (for database/JSON)
  factory WorldTile.fromMap(Map<String, dynamic> map) => WorldTile(
      id: map['id'] as String,
      x: map['x'] as int,
      y: map['y'] as int,
      type: TileType.values[map['type'] as int],
      name: map['name'] as String,
      description: map['description'] as String,
      unlockRequirement: map['unlockRequirement'] as int,
      isUnlocked: map['isUnlocked'] as bool,
      rewards: List<String>.from(map['rewards'] as List? ?? []),
      customizations: Map<String, dynamic>.from(
        map['customizations'] as Map? ?? {},
      ),
    );

  final String id;
  final int x;
  final int y;
  final TileType type;
  final String name;
  final String description;
  final int unlockRequirement; // XP required to unlock
  final bool isUnlocked;
  final List<String> rewards;
  final Map<String, dynamic> customizations;

  /// Creates a new world tile with default values
  factory WorldTile.create({
    required String id,
    required String name,
    required TileType type,
    required int unlockRequirement,
    required int x,
    required int y,
    String description = '',
    List<String> rewards = const [],
    Map<String, dynamic> customizations = const {},
  }) {
    return WorldTile(
      id: id,
      name: name,
      description: description,
      type: type,
      isUnlocked: false,
      unlockRequirement: unlockRequirement,
      x: x,
      y: y,
      rewards: rewards,
      customizations: customizations,
    );
  }

  /// Check if this tile can be unlocked with given XP and category progress
  bool canUnlock(int currentXP, Map<String, int> categoryProgress) {
    return currentXP >= unlockRequirement;
  }

  /// Get the maximum position value (for grid calculations)
  static int get maxPosition => 10; // Default grid size

  /// Creates a copy with updated fields
  WorldTile copyWith({
    String? id,
    int? x,
    int? y,
    TileType? type,
    String? name,
    String? description,
    int? unlockRequirement,
    bool? isUnlocked,
    List<String>? rewards,
    Map<String, dynamic>? customizations,
  }) => WorldTile(
      id: id ?? this.id,
      x: x ?? this.x,
      y: y ?? this.y,
      type: type ?? this.type,
      name: name ?? this.name,
      description: description ?? this.description,
      unlockRequirement: unlockRequirement ?? this.unlockRequirement,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      rewards: rewards ?? this.rewards,
      customizations: customizations ?? this.customizations,
    );

  /// Converts to a map (for database/JSON)
  Map<String, dynamic> toMap() => {
      'id': id,
      'x': x,
      'y': y,
      'type': type.index,
      'name': name,
      'description': description,
      'unlockRequirement': unlockRequirement,
      'isUnlocked': isUnlocked,
      'rewards': rewards,
      'customizations': customizations,
    };

  @override
  List<Object?> get props => [
        id,
        x,
        y,
        type,
        name,
        description,
        unlockRequirement,
        isUnlocked,
        rewards,
        customizations,
      ];
}
/// Extension to get display names for tile types
extension TileTypeExtension on TileType {
  String get displayName {
    switch (this) {
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
      case TileType.special:
        return 'Special';
      case TileType.building:
        return 'Building';
      case TileType.grass:
        return 'Grass';
    }
  }
}