part of '../database.dart';

/// Avatars table definition
@DataClassName('AvatarData')
class Avatars extends Table {
  /// Primary key
  TextColumn get id => text()();

  /// Foreign key to users table
  TextColumn get userId =>
      text().references(Users, #id, onDelete: KeyAction.cascade)();

  /// Avatar name
  TextColumn get name => text().withLength(min: 1, max: 50)();

  /// Current level (1-100)
  IntColumn get level => integer().withDefault(const Constant(1))();

  /// Current XP
  IntColumn get currentXp => integer().withDefault(const Constant(0))();

  /// Strength attribute (0-999)
  IntColumn get strength => integer().withDefault(const Constant(0))();

  /// Wisdom attribute (0-999)
  IntColumn get wisdom => integer().withDefault(const Constant(0))();

  /// Intelligence attribute (0-999)
  IntColumn get intelligence => integer().withDefault(const Constant(0))();

  /// Avatar appearance data as JSON
  TextColumn get appearanceData => text().withDefault(const Constant('{}'))();

  /// Unlocked items as JSON array
  TextColumn get unlockedItems => text().withDefault(const Constant('[]'))();

  /// Creation timestamp
  DateTimeColumn get createdAt => dateTime()();

  /// Last update timestamp
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    'CHECK (level >= 1 AND level <= 100)',
    'CHECK (current_xp >= 0)',
    'CHECK (strength >= 0 AND strength <= 999)',
    'CHECK (wisdom >= 0 AND wisdom <= 999)',
    'CHECK (intelligence >= 0 AND intelligence <= 999)',
    'CHECK (length(name) >= 1 AND length(name) <= 50)',
  ];
}
