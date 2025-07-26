part of '../database.dart';

/// Data Access Object for Avatar operations
@DriftAccessor(tables: [Avatars, Users])
class AvatarDao extends DatabaseAccessor<LifeXPDatabase> with _$AvatarDaoMixin {
  AvatarDao(super.db);

  /// Gets avatar by user ID
  Future<AvatarData?> getAvatarByUserId(String userId) async => (select(
    avatars,
  )..where((a) => a.userId.equals(userId))).getSingleOrNull();

  /// Gets avatar by ID
  Future<AvatarData?> getAvatarById(String id) async =>
      (select(avatars)..where((a) => a.id.equals(id))).getSingleOrNull();

  /// Creates a new avatar
  Future<void> createAvatar(AvatarsCompanion avatar) async {
    await into(avatars).insert(avatar);
  }

  /// Updates avatar data
  Future<bool> updateAvatar(AvatarsCompanion avatar) async =>
      update(avatars).replace(avatar);

  /// Updates avatar XP and handles level progression
  Future<AvatarData?> updateAvatarXP(String avatarId, int xpGain) async =>
      transaction(() async {
        final avatar = await getAvatarById(avatarId);
        if (avatar == null) {
          return null;
        }

        final newXP = avatar.currentXp + xpGain;
        final newLevel = _calculateLevelFromXP(newXP);
        final levelDifference = newLevel - avatar.level;
        final attributeIncrease = levelDifference * 2; // 2 points per level

        final updatedAvatar = AvatarsCompanion(
          id: Value(avatarId),
          currentXp: Value(newXP),
          level: Value(newLevel),
          strength: Value(avatar.strength + attributeIncrease),
          wisdom: Value(avatar.wisdom + attributeIncrease),
          intelligence: Value(avatar.intelligence + attributeIncrease),
          updatedAt: Value(DateTime.now()),
        );

        await update(avatars).replace(updatedAvatar);
        return getAvatarById(avatarId);
      });

  /// Updates specific attribute
  Future<bool> updateAttribute(
    String avatarId,
    String attributeType,
    int amount,
  ) async {
    final avatar = await getAvatarById(avatarId);
    if (avatar == null || amount <= 0) {
      return false;
    }

    AvatarsCompanion updatedAvatar;

    switch (attributeType.toLowerCase()) {
      case 'strength':
        final newStrength = (avatar.strength + amount).clamp(0, 999);
        updatedAvatar = AvatarsCompanion(
          id: Value(avatarId),
          strength: Value(newStrength),
          updatedAt: Value(DateTime.now()),
        );
        break;
      case 'wisdom':
        final newWisdom = (avatar.wisdom + amount).clamp(0, 999);
        updatedAvatar = AvatarsCompanion(
          id: Value(avatarId),
          wisdom: Value(newWisdom),
          updatedAt: Value(DateTime.now()),
        );
        break;
      case 'intelligence':
        final newIntelligence = (avatar.intelligence + amount).clamp(0, 999);
        updatedAvatar = AvatarsCompanion(
          id: Value(avatarId),
          intelligence: Value(newIntelligence),
          updatedAt: Value(DateTime.now()),
        );
        break;
      default:
        return false;
    }

    return update(avatars).replace(updatedAvatar);
  }

  /// Updates avatar appearance
  Future<bool> updateAppearance(String avatarId, String appearanceJson) async {
    final result = await (update(avatars)..where((a) => a.id.equals(avatarId)))
        .write(
          AvatarsCompanion(
            appearanceData: Value(appearanceJson),
            updatedAt: Value(DateTime.now()),
          ),
        );
    return result > 0;
  }

  /// Unlocks item for avatar
  Future<bool> unlockItem(String avatarId, String itemId) async =>
      transaction(() async {
        final avatar = await getAvatarById(avatarId);
        if (avatar == null) {
          return false;
        }

        // Parse current unlocked items
        final currentItems = json.decode(avatar.unlockedItems) as List<dynamic>;

        // Check if item is already unlocked
        if (currentItems.contains(itemId)) {
          return true;
        }

        // Add new item
        currentItems.add(itemId);
        final updatedItemsJson = json.encode(currentItems);

        final result =
            await (update(avatars)..where((a) => a.id.equals(avatarId))).write(
              AvatarsCompanion(
                unlockedItems: Value(updatedItemsJson),
                updatedAt: Value(DateTime.now()),
              ),
            );
        return result > 0;
      });

  /// Gets avatars with level progression stats
  Future<List<Map<String, dynamic>>> getAvatarProgressionStats(
    String userId,
  ) async {
    final result = await customSelect(
      '''
      SELECT 
        a.*,
        (SELECT COUNT(*) FROM tasks t WHERE t.user_id = a.user_id AND t.is_completed = 1) as total_tasks_completed,
        (SELECT COUNT(*) FROM achievements ac WHERE ac.user_id = a.user_id AND ac.is_unlocked = 1) as total_achievements
      FROM avatars a 
      WHERE a.user_id = ?
      ''',
      variables: [Variable.withString(userId)],
    ).get();

    return result.map((row) => row.data).toList();
  }

  /// Gets top avatars by level (for leaderboard)
  Future<List<AvatarData>> getTopAvatarsByLevel({int limit = 10}) async =>
      (select(avatars)
            ..orderBy([(a) => OrderingTerm.desc(a.level)])
            ..limit(limit))
          .get();

  /// Gets avatars by XP range
  Future<List<AvatarData>> getAvatarsByXPRange(int minXP, int maxXP) async =>
      (select(
        avatars,
      )..where((a) => a.currentXp.isBetweenValues(minXP, maxXP))).get();

  /// Deletes avatar
  Future<bool> deleteAvatar(String avatarId) async {
    final result = await (delete(
      avatars,
    )..where((a) => a.id.equals(avatarId))).go();
    return result > 0;
  }

  /// Batch update for sync operations
  Future<void> batchUpdateAvatars(List<AvatarsCompanion> avatarUpdates) async {
    await batch((batch) {
      for (final avatar in avatarUpdates) {
        batch.replace(avatars, avatar);
      }
    });
  }

  /// Batch XP updates for multiple avatars
  Future<List<AvatarData>> batchUpdateXP(
    List<Map<String, dynamic>> xpUpdates,
  ) async => transaction(() async {
    final updatedAvatars = <AvatarData>[];

    for (final update in xpUpdates) {
      final avatarId = update['avatarId'] as String;
      final xpGain = update['xpGain'] as int;

      final updatedAvatar = await updateAvatarXP(avatarId, xpGain);
      if (updatedAvatar != null) {
        updatedAvatars.add(updatedAvatar);
      }
    }

    return updatedAvatars;
  });

  /// Optimized level progression query
  Future<List<Map<String, dynamic>>> getLevelProgressionData(
    String userId,
  ) async {
    final result = await customSelect(
      '''
      SELECT 
        a.*,
        CASE 
          WHEN a.level < 100 THEN (100 * a.level * a.level * 0.8) - a.current_xp
          ELSE 0
        END as xp_to_next_level,
        (a.strength + a.wisdom + a.intelligence) as total_attributes,
        (SELECT COUNT(*) FROM json_each(a.unlocked_items)) as unlocked_items_count
      FROM avatars a 
      WHERE a.user_id = ?
      ''',
      variables: [Variable.withString(userId)],
    ).get();

    return result.map((row) => row.data).toList();
  }

  /// Calculates level from total XP
  int _calculateLevelFromXP(int totalXP) {
    for (var level = 1; level <= 100; level++) {
      final xpRequired = (100 * (level - 1) * (level - 1) * 0.8).round();
      if (totalXP < xpRequired) {
        return level - 1;
      }
    }
    return 100; // Max level
  }

  /// Gets avatar statistics
  Future<Map<String, dynamic>> getAvatarStats(String avatarId) async {
    final result = await customSelect(
      '''
      SELECT 
        a.*,
        (a.strength + a.wisdom + a.intelligence) as total_attributes,
        (SELECT COUNT(*) FROM tasks t WHERE t.user_id = a.user_id AND t.is_completed = 1) as completed_tasks,
        (SELECT COUNT(*) FROM achievements ac WHERE ac.user_id = a.user_id AND ac.is_unlocked = 1) as unlocked_achievements,
        (SELECT COUNT(*) FROM world_tiles wt WHERE wt.user_id = a.user_id AND wt.is_unlocked = 1) as unlocked_tiles
      FROM avatars a 
      WHERE a.id = ?
      ''',
      variables: [Variable.withString(avatarId)],
    ).getSingleOrNull();

    return result?.data ?? {};
  }
}
