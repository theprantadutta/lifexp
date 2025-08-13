part of '../database.dart';

/// World tiles table definition
@DataClassName('WorldTileData')
class WorldTiles extends Table {
  /// Primary key
  TextColumn get id => text()();

  /// Foreign key to users table
  TextColumn get userId =>
      text().references(Users, #id, onDelete: KeyAction.cascade)();

  /// Tile name
  TextColumn get name => text().withLength(min: 1, max: 100)();

  /// Tile description
  TextColumn get description =>
      text().withLength(max: 500).withDefault(const Constant(''))();

  /// Image path
  TextColumn get imagePath => text()();

  /// Tile type (grass, forest, mountain, water, desert, city, building, special)
  TextColumn get tileType => text()();

  /// Unlock status
  BoolColumn get isUnlocked => boolean().withDefault(const Constant(false))();

  /// XP requirement to unlock
  IntColumn get unlockRequirement => integer()();

  /// Category requirement for unlocking (optional)
  TextColumn get unlockCategory => text().nullable()();

  /// X position on the map
  IntColumn get positionX => integer()();

  /// Y position on the map
  IntColumn get positionY => integer()();

  /// Unlock timestamp
  DateTimeColumn get unlockedAt => dateTime().nullable()();

  /// Custom properties as JSON
  TextColumn get customProperties => text().withDefault(const Constant('{}'))();

  /// Creation timestamp
  DateTimeColumn get createdAt => dateTime()();

  /// Last update timestamp
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    'CHECK (length(name) >= 1 AND length(name) <= 100)',
    'CHECK (length(description) <= 500)',
    "CHECK (tile_type IN ('grass', 'forest', 'mountain', 'water', 'desert', 'city', 'building', 'special'))",
    'CHECK (unlock_requirement >= 0)',
    'CHECK (position_x >= 0 AND position_x <= 1000)',
    'CHECK (position_y >= 0 AND position_y <= 1000)',
    'CHECK (length(image_path) > 0)',
  ];
}
