part of '../database.dart';

/// Tasks table definition
@DataClassName('TaskData')
class Tasks extends Table {
  /// Primary key
  TextColumn get id => text()();

  /// Foreign key to users table
  TextColumn get userId =>
      text().references(Users, #id, onDelete: KeyAction.cascade)();

  /// Task title
  TextColumn get title => text().withLength(min: 1, max: 100)();

  /// Task description
  TextColumn get description =>
      text().withLength(max: 500).withDefault(const Constant(''))();

  /// Task type (daily, weekly, longTerm)
  TextColumn get type => text()();

  /// Task category (health, finance, work, custom)
  TextColumn get category => text()();

  /// XP reward for completion
  IntColumn get xpReward => integer()();

  /// Task difficulty (1-10)
  IntColumn get difficulty => integer()();

  /// Due date (optional)
  DateTimeColumn get dueDate => dateTime().nullable()();

  /// Completion status
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();

  /// Current streak count
  IntColumn get streakCount => integer().withDefault(const Constant(0))();

  /// Last completion date
  DateTimeColumn get lastCompletedDate => dateTime().nullable()();

  /// Creation timestamp
  DateTimeColumn get createdAt => dateTime()();

  /// Last update timestamp
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    'CHECK (length(title) >= 1 AND length(title) <= 100)',
    'CHECK (length(description) <= 500)',
    "CHECK (type IN ('daily', 'weekly', 'longTerm'))",
    "CHECK (category IN ('health', 'finance', 'work', 'custom'))",
    'CHECK (xp_reward > 0)',
    'CHECK (difficulty >= 1 AND difficulty <= 10)',
    'CHECK (streak_count >= 0)',
  ];
}
