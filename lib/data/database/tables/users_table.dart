part of '../database.dart';

/// Users table definition
@DataClassName('UserData')
class Users extends Table {
  /// Primary key
  TextColumn get id => text()();

  /// User name
  TextColumn get name => text().withLength(min: 1, max: 50)();

  /// Email (optional for future use)
  TextColumn get email => text().nullable()();

  /// Creation timestamp
  DateTimeColumn get createdAt => dateTime()();

  /// Last activity timestamp
  DateTimeColumn get lastActive => dateTime()();

  /// User preferences as JSON
  TextColumn get preferences => text().withDefault(const Constant('{}'))();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    'CHECK (length(name) >= 1 AND length(name) <= 50)',
  ];
}
