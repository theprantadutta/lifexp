import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart' as uuid;

part 'daos/achievement_dao.dart';
// Import DAOs
part 'daos/avatar_dao.dart';
part 'daos/progress_dao.dart';
part 'daos/task_dao.dart';
part 'daos/world_dao.dart';
// Generated file
part 'database.g.dart';
part 'tables/achievements_table.dart';
part 'tables/avatars_table.dart';
part 'tables/progress_entries_table.dart';
part 'tables/tasks_table.dart';
// Import table definitions
part 'tables/users_table.dart';
part 'tables/world_tiles_table.dart';

/// Main database class for LifeXP app
@DriftDatabase(
  tables: [Users, Avatars, Tasks, Achievements, WorldTiles, ProgressEntries],
  daos: [AvatarDao, TaskDao, AchievementDao, WorldDao, ProgressDao],
)
class LifeXPDatabase extends _$LifeXPDatabase {
  LifeXPDatabase() : super(_openConnection());

  /// Constructor for testing with custom executor
  LifeXPDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await _createIndexes(m);
    },
    onUpgrade: (m, from, to) async {
      // Handle future migrations here
      if (from < 2) {
        // Example migration for version 2
        // await m.addColumn(tasks, tasks.newColumn);
      }
    },
    beforeOpen: (details) async {
      // Enable foreign keys
      await customStatement('PRAGMA foreign_keys = ON');

      // Optimize database performance
      await customStatement('PRAGMA journal_mode = WAL');
      await customStatement('PRAGMA synchronous = NORMAL');
      await customStatement('PRAGMA cache_size = 10000');
      await customStatement('PRAGMA temp_store = MEMORY');
    },
  );

  /// Creates database indexes for optimal query performance
  Future<void> _createIndexes(Migrator m) async {
    // Avatar indexes
    await m.createIndex(
      Index(
        'idx_avatars_user_id',
        'CREATE INDEX idx_avatars_user_id ON avatars (user_id)',
      ),
    );

    // Task indexes
    await m.createIndex(
      Index(
        'idx_tasks_user_id',
        'CREATE INDEX idx_tasks_user_id ON tasks (user_id)',
      ),
    );
    await m.createIndex(
      Index(
        'idx_tasks_category',
        'CREATE INDEX idx_tasks_category ON tasks (category)',
      ),
    );
    await m.createIndex(
      Index('idx_tasks_type', 'CREATE INDEX idx_tasks_type ON tasks (type)'),
    );
    await m.createIndex(
      Index(
        'idx_tasks_due_date',
        'CREATE INDEX idx_tasks_due_date ON tasks (due_date)',
      ),
    );
    await m.createIndex(
      Index(
        'idx_tasks_completed',
        'CREATE INDEX idx_tasks_completed ON tasks (is_completed)',
      ),
    );

    // Achievement indexes
    await m.createIndex(
      Index(
        'idx_achievements_user_id',
        'CREATE INDEX idx_achievements_user_id ON achievements (user_id)',
      ),
    );
    await m.createIndex(
      Index(
        'idx_achievements_type',
        'CREATE INDEX idx_achievements_type ON achievements (achievement_type)',
      ),
    );
    await m.createIndex(
      Index(
        'idx_achievements_unlocked',
        'CREATE INDEX idx_achievements_unlocked ON achievements (is_unlocked)',
      ),
    );

    // World tiles indexes
    await m.createIndex(
      Index(
        'idx_world_tiles_user_id',
        'CREATE INDEX idx_world_tiles_user_id ON world_tiles (user_id)',
      ),
    );
    await m.createIndex(
      Index(
        'idx_world_tiles_position',
        'CREATE INDEX idx_world_tiles_position ON world_tiles '
            '(position_x, position_y)',
      ),
    );
    await m.createIndex(
      Index(
        'idx_world_tiles_unlocked',
        'CREATE INDEX idx_world_tiles_unlocked ON world_tiles '
            '(is_unlocked)',
      ),
    );

    // Progress entries indexes
    await m.createIndex(
      Index(
        'idx_progress_entries_user_id',
        'CREATE INDEX idx_progress_entries_user_id ON progress_entries '
            '(user_id)',
      ),
    );
    await m.createIndex(
      Index(
        'idx_progress_entries_date',
        'CREATE INDEX idx_progress_entries_date ON progress_entries '
            '(date)',
      ),
    );
    await m.createIndex(
      Index(
        'idx_progress_entries_category',
        'CREATE INDEX idx_progress_entries_category ON progress_entries '
            '(category)',
      ),
    );
  }

  /// Validates database constraints
  Future<bool> validateConstraints() async {
    try {
      // Check avatar constraints
      final invalidAvatars = await customSelect(
        'SELECT COUNT(*) as count FROM avatars WHERE level < 1 OR '
        'level > 100 OR current_xp < 0',
      ).getSingle();
      if (invalidAvatars.data['count'] > 0) {
        return false;
      }

      // Check task constraints
      final invalidTasks = await customSelect(
        'SELECT COUNT(*) as count FROM tasks WHERE difficulty < 1 OR '
        'difficulty > 10 OR xp_reward <= 0',
      ).getSingle();
      if (invalidTasks.data['count'] > 0) {
        return false;
      }

      // Check achievement constraints
      final invalidAchievements = await customSelect(
        'SELECT COUNT(*) as count FROM achievements WHERE '
        'progress < 0',
      ).getSingle();
      if (invalidAchievements.data['count'] > 0) {
        return false;
      }

      return true;
    } on Exception {
      return false;
    }
  }

  /// Clears all data (for testing purposes)
  Future<void> clearAllData() async {
    await transaction(() async {
      await delete(progressEntries).go();
      await delete(worldTiles).go();
      await delete(achievements).go();
      await delete(tasks).go();
      await delete(avatars).go();
      await delete(users).go();
    });
  }

  /// Gets database statistics
  Future<Map<String, int>> getDatabaseStats() async {
    final stats = <String, int>{};

    stats['users'] = await users.count().getSingle();
    stats['avatars'] = await avatars.count().getSingle();
    stats['tasks'] = await tasks.count().getSingle();
    stats['achievements'] = await achievements.count().getSingle();
    stats['world_tiles'] = await worldTiles.count().getSingle();
    stats['progress_entries'] = await progressEntries.count().getSingle();

    return stats;
  }
}

/// Opens database connection
LazyDatabase _openConnection() => LazyDatabase(() async {
  final dbFolder = await getApplicationDocumentsDirectory();
  final file = File(p.join(dbFolder.path, 'lifexp.db'));
  return NativeDatabase.createInBackground(file);
});
