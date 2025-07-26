part of '../database.dart';

/// Achievements table definition
@DataClassName('AchievementData')
class Achievements extends Table {
  /// Primary key
  TextColumn get id => text()();

  /// Foreign key to users table
  TextColumn get userId =>
      text().references(Users, #id, onDelete: KeyAction.cascade)();

  /// Achievement type (streak, total, milestone, category, level, special)
  TextColumn get achievementType => text()();

  /// Achievement title
  TextColumn get title => text().withLength(min: 1, max: 100)();

  /// Achievement description
  TextColumn get description => text().withLength(min: 1, max: 500)();

  /// Icon path
  TextColumn get iconPath => text()();

  /// Achievement criteria as JSON
  TextColumn get criteria => text()();

  /// Unlock status
  BoolColumn get isUnlocked => boolean().withDefault(const Constant(false))();

  /// Current progress towards achievement
  IntColumn get progress => integer().withDefault(const Constant(0))();

  /// Unlock timestamp
  DateTimeColumn get unlockedAt => dateTime().nullable()();

  /// Creation timestamp
  DateTimeColumn get createdAt => dateTime()();

  /// Last update timestamp
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    'CHECK (length(title) >= 1 AND length(title) <= 100)',
    'CHECK (length(description) >= 1 AND length(description) <= 500)',
    'CHECK (achievement_type IN ("streak", "total", "milestone", "category", "level", "special"))',
    'CHECK (progress >= 0)',
    'CHECK (length(icon_path) > 0)',
  ];
}
