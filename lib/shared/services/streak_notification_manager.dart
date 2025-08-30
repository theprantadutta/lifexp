import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/models/task.dart';
import '../../data/repositories/task_repository.dart';
import 'notification_service.dart';

/// Specialized manager for streak-related notifications
class StreakNotificationManager {
  factory StreakNotificationManager() => _instance;
  StreakNotificationManager._internal();
  static final StreakNotificationManager _instance = 
      StreakNotificationManager._internal();

  final NotificationService _notificationService = NotificationService();
  TaskRepository? _taskRepository;

  Timer? _streakMonitorTimer;
  final Map<String, DateTime> _lastWarningTimes = {};

  /// Set the task repository
  void setTaskRepository(TaskRepository taskRepository) {
    _taskRepository = taskRepository;
  }

  /// Initialize the streak notification manager
  Future<void> initialize() async {
    await _notificationService.initialize();
    _startStreakMonitoring();
  }

  /// Start monitoring streaks
  void _startStreakMonitoring() {
    // Check streaks every 30 minutes
    _streakMonitorTimer = Timer.periodic(
      const Duration(minutes: 30),
      (_) => _monitorAllStreaks(),
    );
  }

  /// Monitor all active streaks
  Future<void> _monitorAllStreaks() async {
    try {
      if (_taskRepository == null) return;
      final tasks = await _taskRepository!.getTasksWithStreaks('current_user_id');
      final now = DateTime.now();

      for (final task in tasks) {
        if (task.streakCount > 0) {
          await _checkStreakStatus(task, now);
        }
      }
    } catch (e) {
      debugPrint('Failed to monitor streaks: $e');
    }
  }

  /// Check individual streak status
  Future<void> _checkStreakStatus(Task task, DateTime now) async {
    if (task.lastCompletedDate == null) return;

    final hoursSinceCompletion = now.difference(task.lastCompletedDate!).inHours;
    final streakType = _getStreakType(task);
    final warningThreshold = _getWarningThreshold(streakType);
    final breakThreshold = _getBreakThreshold(streakType);

    // Check if streak is about to break
    if (hoursSinceCompletion >= warningThreshold && 
        hoursSinceCompletion < breakThreshold) {
      await _sendStreakWarning(task, now);
    }
    
    // Check if streak has broken
    else if (hoursSinceCompletion >= breakThreshold) {
      await _sendStreakBrokenNotification(task);
    }
    
    // Check for streak milestones
    else if (_isStreakMilestone(task.streakCount)) {
      await _sendStreakMilestoneNotification(task);
    }
  }

  /// Get streak type based on task
  StreakType _getStreakType(Task task) {
    switch (task.type) {
      case TaskType.daily:
        return StreakType.daily;
      case TaskType.weekly:
        return StreakType.weekly;
      case TaskType.longTerm:
        return StreakType.flexible;
    }
  }

  /// Get warning threshold in hours
  int _getWarningThreshold(StreakType type) {
    switch (type) {
      case StreakType.daily:
        return 20; // Warn 4 hours before 24-hour mark
      case StreakType.weekly:
        return 144; // Warn 24 hours before 7-day mark
      case StreakType.flexible:
        return 48; // Warn after 2 days for flexible tasks
    }
  }

  /// Get break threshold in hours
  int _getBreakThreshold(StreakType type) {
    switch (type) {
      case StreakType.daily:
        return 24;
      case StreakType.weekly:
        return 168; // 7 days
      case StreakType.flexible:
        return 72; // 3 days
    }
  }

  /// Send streak warning notification
  Future<void> _sendStreakWarning(Task task, DateTime now) async {
    // Avoid spam - only send one warning per 6 hours
    final lastWarning = _lastWarningTimes[task.id];
    if (lastWarning != null && 
        now.difference(lastWarning).inHours < 6) {
      return;
    }

    await _notificationService.scheduleStreakWarning(
      task: task,
      warningTime: now.add(const Duration(minutes: 1)), // Send immediately
    );

    _lastWarningTimes[task.id] = now;
    debugPrint('Sent streak warning for: ${task.title}');
  }

  /// Send streak broken notification
  Future<void> _sendStreakBrokenNotification(Task task) async {
    final brokenStreakCount = task.streakCount;
    
    // Only notify if it was a significant streak
    if (brokenStreakCount < 3) return;

    const title = 'Streak Ended 💔';
    final description = 'Your $brokenStreakCount-day streak for "${task.title}" '
                       "has ended. But don't worry - every expert was once a beginner! "
                       'Start fresh today! 🌱';

    await _notificationService.showAchievementNotification(
      achievementName: title,
      description: description,
    );

    // Send encouragement to restart
    await _sendRestartEncouragement(task, brokenStreakCount);
  }

  /// Send encouragement to restart streak
  Future<void> _sendRestartEncouragement(Task task, int brokenStreak) async {
    final encouragementMessages = [
      'The best time to plant a tree was 20 years ago. The second best time is now! 🌳',
      'Every master was once a disaster. Your comeback starts today! 💪',
      "Streaks end, but determination doesn't. Let's go again! 🚀",
      'You did $brokenStreak days before - you can do it again! ⭐',
    ];

    final message = encouragementMessages[
      DateTime.now().day % encouragementMessages.length
    ];

    // Schedule for 2 hours later to give time to process
    debugPrint('Scheduled restart encouragement: $message');
  }

  /// Check if streak count is a milestone
  bool _isStreakMilestone(int streakCount) {
    const milestones = [3, 7, 14, 21, 30, 60, 100, 365];
    return milestones.contains(streakCount);
  }

  /// Send streak milestone notification
  Future<void> _sendStreakMilestoneNotification(Task task) async {
    final milestone = task.streakCount;
    final milestoneData = _getMilestoneData(milestone);
    
    if (milestoneData == null) return;

    final title = '${milestoneData['emoji']} ${milestoneData['title']}';
    final description = '${milestoneData['message']}\n'
                       'Your $milestone-day streak on "${task.title}" is amazing!';

    await _notificationService.showAchievementNotification(
      achievementName: title,
      description: description,
      xpReward: milestone * 10,
    );

    // Send personalized milestone message
    await _sendPersonalizedMilestoneMessage(task, milestone);
  }

  /// Get milestone data
  Map<String, String>? _getMilestoneData(int days) {
    const milestones = {
      3: {
        'emoji': '🌱',
        'title': 'Habit Seedling',
        'message': 'Your habit is taking root!',
      },
      7: {
        'emoji': '📅',
        'title': 'Week Warrior',
        'message': 'One week of dedication!',
      },
      14: {
        'emoji': '💪',
        'title': 'Fortnight Fighter',
        'message': 'Two weeks of strength!',
      },
      21: {
        'emoji': '🧠',
        'title': 'Habit Hacker',
        'message': 'Neural pathways are forming!',
      },
      30: {
        'emoji': '🏆',
        'title': 'Monthly Master',
        'message': 'One month of excellence!',
      },
      60: {
        'emoji': '⭐',
        'title': 'Two-Month Titan',
        'message': 'Consistency champion!',
      },
      100: {
        'emoji': '💯',
        'title': 'Century Club',
        'message': 'Triple digits achieved!',
      },
      365: {
        'emoji': '👑',
        'title': 'Year-Long Legend',
        'message': 'A full year of dedication!',
      },
    };

    return milestones[days];
  }

  /// Send personalized milestone message
  Future<void> _sendPersonalizedMilestoneMessage(Task task, int milestone) async {
    final categoryMessages = _getCategoryMilestoneMessages(task.category);
    final message = categoryMessages[milestone % categoryMessages.length];
    
    // Schedule for 1 hour later
    debugPrint('Personalized milestone message for ${task.title}: $message');
  }

  /// Get category-specific milestone messages
  List<String> _getCategoryMilestoneMessages(TaskCategory category) {
    switch (category) {
      case TaskCategory.fitness:
        return [
          'Your body is transforming with every workout! 💪',
          'Fitness consistency builds unshakeable strength! 🏋️‍♂️',
          "You're sculpting both muscle and discipline! 🔥",
        ];
      case TaskCategory.health:
        return [
          'Every healthy choice compounds into vitality! 💚',
          "You're investing in your most valuable asset! 🌟",
          'Health habits today create wellness tomorrow! ✨',
        ];
      case TaskCategory.learning:
        return [
          'Knowledge grows exponentially with consistency! 📚',
          "You're building a more capable mind! 🧠",
          'Learning streaks create lasting wisdom! ⚡',
        ];
      case TaskCategory.mindfulness:
        return [
          'Inner peace deepens with practice! 🧘‍♀️',
          "You're cultivating mental clarity! 🌸",
          'Mindfulness streaks build emotional resilience! ☮️',
        ];
      case TaskCategory.work:
        return [
          'Professional excellence through consistency! 📈',
          "You're building unstoppable momentum! 🚀",
          'Career growth happens one day at a time! 💼',
        ];
      case TaskCategory.creative:
        return [
          'Creativity flourishes with regular practice! 🎨',
          "You're nurturing your artistic soul! ✨",
          'Creative streaks unlock new possibilities! 🌈',
        ];
      case TaskCategory.social:
        return [
          'Relationships strengthen with consistent care! 💝',
          "You're building meaningful connections! 🤝",
          'Social consistency creates lasting bonds! 😊',
        ];
      case TaskCategory.finance:
        return [
          'Financial discipline builds lasting wealth! 💰',
          "You're securing your financial future! 📊",
          'Money habits compound over time! 📈',
        ];
      case TaskCategory.custom:
        return [
          'Your personal commitment is inspiring! ⭐',
          'Custom streaks show true self-discipline! 🎯',
          'You know what works for you! 💪',
        ];
    }
  }

  /// Send streak recovery notification
  Future<void> sendStreakRecoveryNotification({
    required Task task,
    required int previousBestStreak,
  }) async {
    if (task.streakCount <= previousBestStreak) return;

    const title = '🎉 Streak Recovery!';
    final description = "Amazing! You've surpassed your previous best streak "
                       'of $previousBestStreak days on "${task.title}"! '
                       'Current streak: ${task.streakCount} days. '
                       "You're stronger than before! 💪";

    await _notificationService.showAchievementNotification(
      achievementName: title,
      description: description,
      xpReward: (task.streakCount - previousBestStreak) * 20,
    );
  }

  /// Send multi-streak celebration
  Future<void> sendMultiStreakCelebration({
    required List<Task> activeTasks,
    required int totalActiveStreaks,
  }) async {
    if (totalActiveStreaks < 3) return;

    const title = '🔥 Multi-Streak Master!';
    final taskTitles = activeTasks.take(3).map((t) => t.title).join(', ');
    final description = "Incredible! You're maintaining $totalActiveStreaks "
                       'active streaks simultaneously! '
                       'Including: $taskTitles${activeTasks.length > 3 ? '...' : ''}. '
                       'Your consistency is legendary! 👑';

    await _notificationService.showAchievementNotification(
      achievementName: title,
      description: description,
      xpReward: totalActiveStreaks * 50,
    );
  }

  /// Dispose resources
  void dispose() {
    _streakMonitorTimer?.cancel();
    _lastWarningTimes.clear();
  }
}

/// Enum for streak types
enum StreakType {
  daily,
  weekly,
  flexible,
}

/// Enum for streak urgency levels
enum StreakUrgency {
  low,
  medium,
  high,
  critical,
}