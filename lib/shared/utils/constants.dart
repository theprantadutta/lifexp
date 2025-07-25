/// Application-wide constants and configuration values.
class AppConstants {
  // App Information
  static const String appName = 'LifeExp';
  static const String appVersion = '1.0.0';

  // Database
  static const String databaseName = 'lifexp.db';
  static const int databaseVersion = 1;

  // Shared Preferences Keys
  static const String keyFirstLaunch = 'first_launch';
  static const String keyUserId = 'user_id';
  static const String keyThemeMode = 'theme_mode';

  // Animation Durations
  static const Duration shortAnimationDuration = Duration(milliseconds: 200);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 400);
  static const Duration longAnimationDuration = Duration(milliseconds: 600);

  // UI Constants
  static const double defaultPadding = 16;
  static const double smallPadding = 8;
  static const double largePadding = 24;
  static const double borderRadius = 12;

  // Gamification
  static const int baseXpPerLevel = 100;
  static const double xpMultiplier = 1.5;
  static const int maxLevel = 100;

  // Notifications
  static const String notificationChannelId = 'lifexp_notifications';
  static const String notificationChannelName = 'LifeExp Notifications';
  static const String notificationChannelDescription =
      'Notifications for LifeExp app';
}

/// Firebase configuration constants.
class FirebaseConstants {
  // Collection names
  static const String usersCollection = 'users';
  static const String tasksCollection = 'tasks';
  static const String achievementsCollection = 'achievements';
  static const String progressCollection = 'progress';
  static const String worldTilesCollection = 'world_tiles';

  // Storage paths
  static const String avatarImagesPath = 'avatars';
  static const String achievementIconsPath = 'achievements';
  static const String worldTilesPath = 'world_tiles';
}
