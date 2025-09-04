part of '../database.dart';

/// Goals table definition
@DataClassName('GoalData')
class Goals extends Table {
  /// Primary key
  TextColumn get id => text()();

  /// Foreign key to users table
  TextColumn get userId =>
      text().references(Users, #id, onDelete: KeyAction.cascade)();

  /// Goal title
  TextColumn get title => text().withLength(min: 1, max: 100)();

  /// Goal description
  TextColumn get description =>
      text().withLength(max: 1000).withDefault(const Constant(''))();

  /// Goal category (health, fitness, mindfulness, learning, career, financial, relationships, personal, custom)
  TextColumn get category => text()();

  /// Goal priority (low, medium, high, critical)
  TextColumn get priority => text()();

  /// Goal status (notStarted, inProgress, onHold, completed, cancelled)
  TextColumn get status => text()();

  /// Progress toward goal completion (0.0 - 1.0)
  RealColumn get progress => real().withDefault(const Constant(0.0))();

  /// Start date (optional)
  DateTimeColumn get startDate => dateTime().nullable()();

  /// Deadline for goal completion
  DateTimeColumn get deadline => dateTime()();

  /// Completion timestamp
  DateTimeColumn get completedAt => dateTime().nullable()();

  /// Creation timestamp
  DateTimeColumn get createdAt => dateTime()();

  /// Last update timestamp
  DateTimeColumn get updatedAt => dateTime()();

  /// Parent goal ID (for hierarchical goals)
  TextColumn get parentGoalId => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    'CHECK (length(title) >= 1 AND length(title) <= 100)',
    'CHECK (length(description) <= 1000)',
    "CHECK (category IN ('health', 'fitness', 'mindfulness', 'learning', 'career', 'financial', 'relationships', 'personal', 'custom'))",
    "CHECK (priority IN ('low', 'medium', 'high', 'critical'))",
    "CHECK (status IN ('notStarted', 'inProgress', 'onHold', 'completed', 'cancelled'))",
    'CHECK (progress >= 0.0 AND progress <= 1.0)',
  ];
}