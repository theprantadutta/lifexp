part of '../database.dart';

/// Progress entries table definition
@DataClassName('ProgressEntryData')
class ProgressEntries extends Table {
  /// Primary key
  TextColumn get id => text()();

  /// Foreign key to users table
  TextColumn get userId =>
      text().references(Users, #id, onDelete: KeyAction.cascade)();

  /// Date of the progress entry
  DateTimeColumn get date => dateTime()();

  /// XP gained on this date
  IntColumn get xpGained => integer().withDefault(const Constant(0))();

  /// Tasks completed on this date
  IntColumn get tasksCompleted => integer().withDefault(const Constant(0))();

  /// Category filter (optional)
  TextColumn get category => text().nullable()();

  /// Category breakdown as JSON
  TextColumn get categoryBreakdown =>
      text().withDefault(const Constant('{}'))();

  /// Task type breakdown as JSON
  TextColumn get taskTypeBreakdown =>
      text().withDefault(const Constant('{}'))();

  /// Streak count at this time
  IntColumn get streakCount => integer().withDefault(const Constant(0))();

  /// User level at this time
  IntColumn get levelAtTime => integer().withDefault(const Constant(1))();

  /// Additional metrics as JSON
  TextColumn get additionalMetrics =>
      text().withDefault(const Constant('{}'))();

  /// Creation timestamp
  DateTimeColumn get createdAt => dateTime()();

  /// Last update timestamp
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    'CHECK (xp_gained >= 0 AND xp_gained <= 999999)',
    'CHECK (tasks_completed >= 0 AND tasks_completed <= 1000)',
    'CHECK (streak_count >= 0)',
    'CHECK (level_at_time >= 1)',
  ];
}
