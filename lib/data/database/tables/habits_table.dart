part of '../database.dart';

/// Habits table definition
@DataClassName('HabitData')
class Habits extends Table {
  /// Primary key
  TextColumn get id => text()();

  /// Foreign key to users table
  TextColumn get userId =>
      text().references(Users, #id, onDelete: KeyAction.cascade)();

  /// Habit title
  TextColumn get title => text().withLength(min: 1, max: 100)();

  /// Habit description
  TextColumn get description =>
      text().withLength(max: 500).withDefault(const Constant(''))();

  /// Habit category (health, fitness, mindfulness, learning, creative, social, productivity, custom)
  TextColumn get category => text()();

  /// Habit frequency (daily, weekly, weekdays, weekends, custom)
  TextColumn get frequency => text()();

  /// Habit difficulty (1-10)
  IntColumn get difficulty => integer()();

  /// Completion status for today
  BoolColumn get isCompletedToday => boolean().withDefault(const Constant(false))();

  /// Current streak count
  IntColumn get streakCount => integer().withDefault(const Constant(0))();

  /// Longest streak achieved
  IntColumn get longestStreak => integer().withDefault(const Constant(0))();

  /// Completion rate (0.0 - 1.0)
  RealColumn get completionRate => real().withDefault(const Constant(0.0))();

  /// Total completions
  IntColumn get totalCompletions => integer().withDefault(const Constant(0))();

  /// Reminder time (optional)
  DateTimeColumn get reminderTime => dateTime().nullable()();

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
    "CHECK (category IN ('health', 'fitness', 'mindfulness', 'learning', 'creative', 'social', 'productivity', 'custom'))",
    "CHECK (frequency IN ('daily', 'weekly', 'weekdays', 'weekends', 'custom'))",
    'CHECK (difficulty >= 1 AND difficulty <= 10)',
    'CHECK (streak_count >= 0)',
    'CHECK (longest_streak >= 0)',
    'CHECK (completion_rate >= 0.0 AND completion_rate <= 1.0)',
    'CHECK (total_completions >= 0)',
  ];
}