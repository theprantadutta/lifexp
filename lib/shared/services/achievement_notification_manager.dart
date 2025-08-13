import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/models/achievement.dart';
import '../../data/models/task.dart';
import '../../data/repositories/achievement_repository.dart';
import '../../data/repositories/progress_repository.dart';
import 'notification_service.dart';

/// Specialized manager for achievement and milestone notifications
class AchievementNotificationManager {
  factory AchievementNotificationManager() => _instance;
  AchievementNotificationManager._internal();
  static final AchievementNotificationManager _instance = 
      AchievementNotificationManager._internal();

  final NotificationService _notificationService = NotificationService();
  final AchievementRepository _achievementRepository = AchievementRepository();
  final ProgressRepository _progressRepository = ProgressRepository();

  Timer? _achievementCheckTimer;
  final Set<String> _recentlyNotified = {};

  /// Initialize the achievement notification manager
  Future<void> initialize() async {
    await _notificationService.initialize();
    _startAchievementChecks();
  }

  /// Start periodic achievement checks
  void _startAchievementChecks() {
    // Check for new achievements every 5 minutes
    _achievementCheckTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _checkForNewAchievements(),
    );
  }

  /// Check for newly unlocked achievements
  Future<void> _checkForNewAchievements() async {
    try {
      // TODO: Need user ID to get achievements
      // final achievements = await _achievementRepository.getAchievementsByUserId(userId);
      final List<Achievement> achievements = [];
      final newlyUnlocked = achievements.where(
        (achievement) => achievement.isUnlocked && 
                        !_recentlyNotified.contains(achievement.id),
      ).toList();

      for (final achievement in newlyUnlocked) {
        await _sendAchievementNotification(achievement);
        _recentlyNotified.add(achievement.id);
      }

      // Clean up old notifications (keep last 50)
      if (_recentlyNotified.length > 50) {
        final toRemove = _recentlyNotified.length - 50;
        final oldEntries = _recentlyNotified.take(toRemove).toList();
        for (final entry in oldEntries) {
          _recentlyNotified.remove(entry);
        }
      }
    } catch (e) {
      debugPrint('Failed to check for new achievements: $e');
    }
  }

  /// Send achievement unlock notification
  Future<void> _sendAchievementNotification(Achievement achievement) async {
    final celebrationMessage = _getCelebrationMessage(achievement);
    
    await _notificationService.showAchievementNotification(
      achievementName: achievement.name,
      description: '${achievement.description}\n$celebrationMessage',
      xpReward: achievement.xpReward,
    );

    // Schedule follow-up encouragement
    await _scheduleAchievementFollowUp(achievement);
    
    debugPrint('Sent achievement notification: ${achievement.name}');
  }

  /// Get celebration message based on achievement type
  String _getCelebrationMessage(Achievement achievement) {
    final type = achievement.type;
    
    switch (type) {
      case AchievementType.streak:
        return '🔥 Your dedication is paying off!';
      case AchievementType.completion:
        return '✅ Task master in action!';
      case AchievementType.xp:
        return '⭐ Experience points champion!';
      case AchievementType.category:
        return '🎯 Category specialist unlocked!';
      case AchievementType.milestone:
        return '🏆 Major milestone achieved!';
      case AchievementType.special:
        return '💎 Something special just happened!';
    }
  }

  /// Schedule follow-up encouragement after achievement
  Future<void> _scheduleAchievementFollowUp(Achievement achievement) async {
    // Schedule a motivational message 1 hour after achievement
    final followUpTime = DateTime.now().add(const Duration(hours: 1));
    
    final messages = _getFollowUpMessages(achievement.type);
    final message = messages[DateTime.now().second % messages.length];
    
    // In a real implementation, this would schedule a delayed notification
    debugPrint('Scheduled follow-up for ${achievement.name}: $message');
  }

  /// Get follow-up messages for achievement types
  List<String> _getFollowUpMessages(AchievementType type) {
    switch (type) {
      case AchievementType.streak:
        return [
          'Consistency is your superpower! 💪',
          'Every day you show up, you get stronger! 🌟',
          'Your streak is building incredible momentum! 🚀',
        ];
      case AchievementType.completion:
        return [
          "You're becoming a completion machine! ⚡",
          'Each task completed is a step toward greatness! 👑',
          'Your productivity is truly inspiring! 📈',
        ];
      case AchievementType.xp:
        return [
          'Your experience is growing exponentially! 📊',
          'Level up mindset activated! 🎮',
          "You're accumulating wisdom with every point! 🧠",
        ];
      case AchievementType.category:
        return [
          'Specialization leads to mastery! 🎯',
          "You're becoming an expert in this area! 🔬",
          'Deep focus brings extraordinary results! 🌟',
        ];
      case AchievementType.milestone:
        return [
          'Major milestones deserve major celebration! 🎉',
          "You've reached a significant landmark! 🗻",
          'This achievement will inspire others! ✨',
        ];
      case AchievementType.special:
        return [
          'Special moments like this are rare! 💎',
          "You've done something truly unique! 🦄",
          'This achievement has a special story! 📖',
        ];
    }
  }

  /// Send streak milestone notification
  Future<void> sendStreakMilestone({
    required String taskTitle,
    required int streakDays,
    required TaskCategory category,
  }) async {
    final milestoneData = _getStreakMilestoneData(streakDays);
    if (milestoneData == null) return;

    final title = '${milestoneData['emoji']} ${milestoneData['title']}';
    final description = 'Amazing $streakDays-day streak on "$taskTitle"!\n'
                       '${milestoneData['message']}';

    await _notificationService.showAchievementNotification(
      achievementName: title,
      description: description,
      xpReward: streakDays * 10,
    );

    // Send category-specific encouragement
    await _sendCategoryStreakEncouragement(category, streakDays);
  }

  /// Get streak milestone data
  Map<String, String>? _getStreakMilestoneData(int days) {
    const milestones = {
      3: {
        'emoji': '🌱',
        'title': 'Habit Seedling',
        'message': 'Your new habit is taking root!',
      },
      7: {
        'emoji': '📅',
        'title': 'Week Warrior',
        'message': "One week of consistency - you're building momentum!",
      },
      14: {
        'emoji': '💪',
        'title': 'Fortnight Fighter',
        'message': 'Two weeks strong - your dedication is showing!',
      },
      21: {
        'emoji': '🧠',
        'title': 'Habit Hacker',
        'message': 'Scientists say 21 days forms a habit - you did it!',
      },
      30: {
        'emoji': '🏆',
        'title': 'Monthly Master',
        'message': "One month of excellence - you're unstoppable!",
      },
      60: {
        'emoji': '⭐',
        'title': 'Two-Month Titan',
        'message': 'Your consistency is truly inspiring!',
      },
      100: {
        'emoji': '💯',
        'title': 'Century Champion',
        'message': "Triple digits! You're in elite company!",
      },
      365: {
        'emoji': '👑',
        'title': 'Year-Long Legend',
        'message': "A full year! You've achieved something extraordinary!",
      },
    };

    return milestones[days];
  }

  /// Send category-specific streak encouragement
  Future<void> _sendCategoryStreakEncouragement(
    TaskCategory category, 
    int streakDays,
  ) async {
    final categoryMessages = _getCategoryStreakMessages(category);
    final message = categoryMessages[streakDays % categoryMessages.length];
    
    // Schedule for 30 minutes later
    debugPrint('Category encouragement for $category: $message');
  }

  /// Get category-specific streak messages
  List<String> _getCategoryStreakMessages(TaskCategory category) {
    switch (category) {
      case TaskCategory.fitness:
        return [
          'Your body is getting stronger every day! 💪',
          'Fitness consistency builds lifelong health! 🏃‍♂️',
          "You're sculpting both body and discipline! 🔥",
        ];
      case TaskCategory.health:
        return [
          'Investing in health pays the best dividends! 💚',
          'Your future self will thank you! 🌟',
          'Healthy habits create a healthy life! ✨',
        ];
      case TaskCategory.learning:
        return [
          'Knowledge compounds with every session! 📚',
          "You're building a more capable version of yourself! 🧠",
          'Learning consistently is a superpower! ⚡',
        ];
      case TaskCategory.mindfulness:
        return [
          'Inner peace grows with practice! 🧘‍♀️',
          "You're cultivating mental clarity! 🌸",
          'Mindfulness is the foundation of wisdom! ☮️',
        ];
      case TaskCategory.work:
        return [
          'Professional growth through consistency! 📈',
          "You're building career momentum! 🚀",
          'Excellence is a habit, not an act! 💼',
        ];
      case TaskCategory.creative:
        return [
          'Creativity flourishes with regular practice! 🎨',
          "You're nurturing your artistic soul! ✨",
          'Every creative session adds to your masterpiece! 🌈',
        ];
      case TaskCategory.social:
        return [
          'Relationships grow stronger with attention! 💝',
          "You're investing in human connections! 🤝",
          "Social bonds are life's greatest treasures! 😊",
        ];
      case TaskCategory.finance:
        return [
          'Financial discipline builds wealth! 💰',
          "You're securing your future! 📊",
          'Smart money habits compound over time! 📈',
        ];
      case TaskCategory.custom:
        return [
          'Your personal goals matter! ⭐',
          'Custom habits show self-awareness! 🎯',
          'You know what works for you! 💪',
        ];
    }
  }

  /// Send level up celebration
  Future<void> sendLevelUpCelebration({
    required int newLevel,
    required int totalXP,
    required List<String> unlockedFeatures,
  }) async {
    final title = '🎉 Level $newLevel Achieved!';
    final description = "Congratulations! You've reached level $newLevel "
                       'with $totalXP total XP!\n'
                       '${_getLevelUpMessage(newLevel)}';

    await _notificationService.showAchievementNotification(
      achievementName: title,
      description: description,
      xpReward: newLevel * 100,
    );

    // Notify about unlocked features
    if (unlockedFeatures.isNotEmpty) {
      await _sendFeatureUnlockNotification(unlockedFeatures, newLevel);
    }
  }

  /// Get level up message
  String _getLevelUpMessage(int level) {
    if (level <= 5) {
      return "You're just getting started - great momentum! 🌱";
    } else if (level <= 10) {
      return "You're building serious habits! 💪";
    } else if (level <= 25) {
      return "You're becoming a habit master! 🏆";
    } else if (level <= 50) {
      return 'Your consistency is legendary! ⭐';
    } else {
      return "You've achieved habit mastery! 👑";
    }
  }

  /// Send feature unlock notification
  Future<void> _sendFeatureUnlockNotification(
    List<String> features, 
    int level,
  ) async {
    const title = '🔓 New Features Unlocked!';
    final featureList = features.map((f) => '• $f').join('\n');
    final description = 'Level $level unlocks:\n$featureList';

    await _notificationService.showAchievementNotification(
      achievementName: title,
      description: description,
    );
  }

  /// Send weekly achievement summary
  Future<void> sendWeeklyAchievementSummary({
    required List<Achievement> newAchievements,
    required int totalXPGained,
    required Map<TaskCategory, int> categoryProgress,
  }) async {
    if (newAchievements.isEmpty) return;

    const title = '📊 Weekly Achievement Report';
    final achievementCount = newAchievements.length;
    final topCategory = categoryProgress.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;

    final description = 'This week you unlocked $achievementCount achievements '
                       'and gained $totalXPGained XP! '
                       'Your strongest category: ${_getCategoryDisplayName(topCategory)}';

    await _notificationService.showAchievementNotification(
      achievementName: title,
      description: description,
    );
  }

  /// Get category display name
  String _getCategoryDisplayName(TaskCategory category) {
    switch (category) {
      case TaskCategory.health:
        return 'Health & Wellness';
      case TaskCategory.finance:
        return 'Financial Goals';
      case TaskCategory.work:
        return 'Professional Growth';
      case TaskCategory.learning:
        return 'Learning & Development';
      case TaskCategory.social:
        return 'Social Connections';
      case TaskCategory.creative:
        return 'Creative Projects';
      case TaskCategory.fitness:
        return 'Fitness & Exercise';
      case TaskCategory.mindfulness:
        return 'Mindfulness & Peace';
      case TaskCategory.custom:
        return 'Personal Goals';
    }
  }

  /// Dispose resources
  void dispose() {
    _achievementCheckTimer?.cancel();
    _recentlyNotified.clear();
  }
}