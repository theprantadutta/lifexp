import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/models/task.dart';
import '../../data/repositories/task_repository.dart';
import 'notification_service.dart';

/// Manager for intelligent notification scheduling and handling
class NotificationManager {
  factory NotificationManager() => _instance;
  NotificationManager._internal();
  static final NotificationManager _instance = NotificationManager._internal();

  final NotificationService _notificationService = NotificationService();
  final TaskRepository _taskRepository = TaskRepository();

  Timer? _dailyCheckTimer;
  Timer? _streakCheckTimer;

  /// Initialize the notification manager
  Future<void> initialize() async {
    await _notificationService.initialize();
    _startPeriodicChecks();
  }

  /// Start periodic checks for notifications
  void _startPeriodicChecks() {
    // Check for daily reminders every hour
    _dailyCheckTimer = Timer.periodic(
      const Duration(hours: 1),
      (_) => _checkDailyReminders(),
    );

    // Check for streak warnings every 30 minutes
    _streakCheckTimer = Timer.periodic(
      const Duration(minutes: 30),
      (_) => _checkStreakWarnings(),
    );
  }

  /// Schedule smart task reminders based on user patterns
  Future<void> scheduleSmartReminders() async {
    try {
      final tasks = await _taskRepository.getAllTasks();
      final activeTasks = tasks.where((task) => !task.isCompleted).toList();

      for (final task in activeTasks) {
        await _scheduleTaskReminder(task);
      }

      debugPrint('Scheduled smart reminders for ${activeTasks.length} tasks');
    } catch (e) {
      debugPrint('Failed to schedule smart reminders: $e');
    }
  }

  /// Schedule reminder for a specific task
  Future<void> _scheduleTaskReminder(Task task) async {
    final optimalTime = _calculateOptimalReminderTime(task);
    
    if (optimalTime != null) {
      await _notificationService.scheduleTaskReminder(
        task: task,
        scheduledTime: optimalTime,
        customMessage: _generateSmartMessage(task),
      );
    }
  }

  /// Calculate optimal reminder time based on task patterns
  DateTime? _calculateOptimalReminderTime(Task task) {
    final now = DateTime.now();
    
    switch (task.type) {
      case TaskType.daily:
        return _calculateDailyReminderTime(task, now);
      case TaskType.weekly:
        return _calculateWeeklyReminderTime(task, now);
      case TaskType.longTerm:
        return _calculateLongTermReminderTime(task, now);
    }
  }

  /// Calculate reminder time for daily tasks
  DateTime _calculateDailyReminderTime(Task task, DateTime now) {
    // Default to 9 AM if no completion history
    var reminderHour = 9;
    
    // If task has completion history, use average completion time
    if (task.lastCompletedDate != null) {
      reminderHour = task.lastCompletedDate!.hour;
      // Remind 1 hour before usual completion time
      reminderHour = (reminderHour - 1).clamp(6, 22);
    }

    // Adjust based on task category
    reminderHour = _adjustTimeByCategory(task.category, reminderHour);

    var reminderTime = DateTime(
      now.year,
      now.month,
      now.day,
      reminderHour,
    );

    // If time has passed today, schedule for tomorrow
    if (reminderTime.isBefore(now)) {
      reminderTime = reminderTime.add(const Duration(days: 1));
    }

    return reminderTime;
  }

  /// Calculate reminder time for weekly tasks
  DateTime _calculateWeeklyReminderTime(Task task, DateTime now) {
    // Schedule for the same day of week, 2 days before due date
    var targetDay = now.weekday;
    
    if (task.dueDate != null) {
      targetDay = task.dueDate!.weekday;
      // Remind 2 days before
      targetDay = (targetDay - 2) % 7;
      if (targetDay == 0) targetDay = 7;
    }

    var daysUntilTarget = (targetDay - now.weekday) % 7;
    if (daysUntilTarget == 0) daysUntilTarget = 7; // Next week

    final reminderHour = _adjustTimeByCategory(task.category, 10);
    
    return DateTime(
      now.year,
      now.month,
      now.day + daysUntilTarget,
      reminderHour,
    );
  }

  /// Calculate reminder time for long-term tasks
  DateTime _calculateLongTermReminderTime(Task task, DateTime now) {
    if (task.dueDate == null) {
      // No due date, remind weekly
      return now.add(const Duration(days: 7));
    }

    final daysUntilDue = task.dueDate!.difference(now).inDays;
    
    if (daysUntilDue > 30) {
      // More than a month away, remind monthly
      return now.add(const Duration(days: 30));
    } else if (daysUntilDue > 7) {
      // More than a week away, remind weekly
      return now.add(const Duration(days: 7));
    } else {
      // Less than a week away, remind daily
      return now.add(const Duration(days: 1));
    }
  }

  /// Adjust reminder time based on task category
  int _adjustTimeByCategory(TaskCategory category, int baseHour) {
    switch (category) {
      case TaskCategory.fitness:
        return 7; // Early morning for fitness
      case TaskCategory.work:
        return 9; // Work hours
      case TaskCategory.mindfulness:
        return 8; // Morning mindfulness
      case TaskCategory.learning:
        return 19; // Evening learning
      case TaskCategory.social:
        return 18; // Evening social activities
      case TaskCategory.creative:
        return 20; // Evening creativity
      case TaskCategory.health:
        return baseHour; // Keep user's preferred time
      case TaskCategory.finance:
        return 10; // Mid-morning for finance tasks
      case TaskCategory.custom:
        return baseHour; // Keep user's preferred time
    }
  }

  /// Generate smart message based on task context
  String _generateSmartMessage(Task task) {
    final messages = _getMessagesForCategory(task.category);
    final streakBonus = task.streakCount > 0 
        ? ' Keep your ${task.streakCount}-day streak going!' 
        : '';
    
    return messages[task.streakCount % messages.length] + streakBonus;
  }

  /// Get motivational messages for each category
  List<String> _getMessagesForCategory(TaskCategory category) {
    switch (category) {
      case TaskCategory.fitness:
        return [
          'Time to get moving! 💪',
          'Your body will thank you! 🏃‍♂️',
          'Stronger every day! 🔥',
          "Fitness time! Let's go! ⚡",
        ];
      case TaskCategory.health:
        return [
          'Take care of yourself! 🌟',
          'Health is wealth! 💚',
          'Your wellbeing matters! 🌸',
          'Healthy habits, happy life! ✨',
        ];
      case TaskCategory.work:
        return [
          'Time to be productive! 📈',
          "Let's tackle this task! 💼",
          'Success awaits! 🎯',
          'Make it happen! 🚀',
        ];
      case TaskCategory.learning:
        return [
          'Knowledge is power! 📚',
          'Learn something new today! 🧠',
          'Expand your horizons! 🌟',
          'Growth mindset activated! 📖',
        ];
      case TaskCategory.mindfulness:
        return [
          'Time for inner peace! 🧘‍♀️',
          'Breathe and center yourself! 🌸',
          'Mindful moments matter! ☮️',
          'Find your calm! 🕯️',
        ];
      case TaskCategory.social:
        return [
          'Connect with others! 👥',
          'Relationships matter! 💝',
          'Social time! 🤝',
          'Spread some joy! 😊',
        ];
      case TaskCategory.creative:
        return [
          'Time to create! 🎨',
          'Express yourself! ✨',
          'Unleash your creativity! 🌈',
          'Art is calling! 🖌️',
        ];
      case TaskCategory.finance:
        return [
          'Secure your future! 💰',
          'Financial wellness check! 📊',
          'Money matters! 💳',
          'Build your wealth! 📈',
        ];
      case TaskCategory.custom:
        return [
          'Time for your task! ⭐',
          "You've got this! 💪",
          'Make progress today! 🎯',
          'Every step counts! 👣',
        ];
    }
  }

  /// Check for daily reminders that need to be sent
  Future<void> _checkDailyReminders() async {
    try {
      final now = DateTime.now();
      final tasks = await _taskRepository.getTasksByType(TaskType.daily);
      
      for (final task in tasks) {
        if (!task.isCompleted && _shouldSendDailyReminder(task, now)) {
          await _notificationService.scheduleTaskReminder(
            task: task,
            scheduledTime: now.add(const Duration(minutes: 5)),
            customMessage: _generateSmartMessage(task),
          );
        }
      }
    } catch (e) {
      debugPrint('Failed to check daily reminders: $e');
    }
  }

  /// Check if daily reminder should be sent
  bool _shouldSendDailyReminder(Task task, DateTime now) {
    // Don't remind if already completed today
    if (task.lastCompletedDate != null) {
      final lastCompleted = task.lastCompletedDate!;
      if (lastCompleted.year == now.year &&
          lastCompleted.month == now.month &&
          lastCompleted.day == now.day) {
        return false;
      }
    }

    // Send reminder if it's past the optimal time and not completed
    final optimalTime = _calculateOptimalReminderTime(task);
    return optimalTime != null && now.isAfter(optimalTime);
  }

  /// Check for streak warnings that need to be sent
  Future<void> _checkStreakWarnings() async {
    try {
      final now = DateTime.now();
      final tasks = await _taskRepository.getTasksWithStreaks();
      
      for (final task in tasks) {
        if (task.streakCount > 0 && _shouldSendStreakWarning(task, now)) {
          final warningTime = _calculateStreakWarningTime(task, now);
          if (warningTime != null) {
            await _notificationService.scheduleStreakWarning(
              task: task,
              warningTime: warningTime,
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Failed to check streak warnings: $e');
    }
  }

  /// Check if streak warning should be sent
  bool _shouldSendStreakWarning(Task task, DateTime now) {
    if (task.lastCompletedDate == null) return false;
    
    final hoursSinceCompletion = now.difference(task.lastCompletedDate!).inHours;
    
    // Warn if it's been more than 20 hours since last completion
    // and less than 24 hours (before streak breaks)
    return hoursSinceCompletion > 20 && hoursSinceCompletion < 24;
  }

  /// Calculate when to send streak warning
  DateTime? _calculateStreakWarningTime(Task task, DateTime now) {
    if (task.lastCompletedDate == null) return null;
    
    // Warn 2 hours before streak would break (22 hours after last completion)
    final warningTime = task.lastCompletedDate!.add(const Duration(hours: 22));
    
    // Only schedule if warning time is in the future
    return warningTime.isAfter(now) ? warningTime : null;
  }

  /// Handle task completion - cancel reminders and show celebration
  Future<void> onTaskCompleted(Task task, int xpGained) async {
    // Cancel any pending reminders for this task
    await _notificationService.cancelTaskReminders(task.id);
    
    // Show XP gain notification
    await _notificationService.showXPGainNotification(
      xpGained: xpGained,
      source: task.title,
    );
    
    // If this maintains or starts a streak, show encouragement
    if (task.streakCount > 1) {
      await _showStreakCelebration(task);
    }
  }

  /// Handle achievement unlock
  Future<void> onAchievementUnlocked({
    required String achievementName,
    required String description,
    required int xpReward,
    String? category,
  }) async {
    // Show immediate achievement notification
    await _notificationService.showAchievementNotification(
      achievementName: achievementName,
      description: description,
      xpReward: xpReward,
    );

    // Schedule follow-up motivational notification
    await _scheduleMotivationalFollowUp(achievementName, category);
    
    debugPrint('Achievement unlocked: $achievementName (+$xpReward XP)');
  }

  /// Schedule motivational follow-up after achievement
  Future<void> _scheduleMotivationalFollowUp(
    String achievementName, 
    String? category,
  ) async {
    final followUpTime = DateTime.now().add(const Duration(hours: 2));
    
    final motivationalMessages = [
      "You're on fire! 🔥 Keep up the amazing work!",
      'That $achievementName achievement was just the beginning! 🚀',
      "You're building incredible momentum! 💪",
      'Your dedication is paying off! ⭐',
    ];

    final message = motivationalMessages[
      DateTime.now().millisecond % motivationalMessages.length
    ];

    // This would typically use a delayed notification
    // For now, we'll just log it
    debugPrint('Scheduled motivational follow-up: $message');
  }

  /// Send re-engagement notification for inactive users
  Future<void> sendReEngagementNotification({
    required int daysSinceLastActivity,
    String? lastCompletedTask,
  }) async {
    String title;
    String body;

    if (daysSinceLastActivity <= 3) {
      title = 'We miss you! 🌟';
      body = 'Your journey awaits! Come back and continue building your habits.';
    } else if (daysSinceLastActivity <= 7) {
      title = 'Your streak is waiting! ⏰';
      body = lastCompletedTask != null 
          ? 'Remember "$lastCompletedTask"? Let\'s get back on track!'
          : 'Your goals are still there, ready when you are!';
    } else {
      title = 'Ready for a fresh start? 🌱';
      body = "Every expert was once a beginner. Let's restart your journey!";
    }

    await _notificationService.showAchievementNotification(
      achievementName: title,
      description: body,
    );
  }

  /// Send streak milestone celebration
  Future<void> sendStreakMilestone({
    required Task task,
    required int streakDays,
  }) async {
    final milestoneMessages = {
      7: 'One week strong! 📅',
      14: 'Two weeks of dedication! 💪',
      30: 'One month champion! 🏆',
      60: 'Two months of excellence! ⭐',
      100: 'Century club member! 💯',
      365: 'One year legend! 👑',
    };

    final message = milestoneMessages[streakDays];
    if (message != null) {
      await _notificationService.showAchievementNotification(
        achievementName: message,
        description: 'Amazing $streakDays-day streak on "${task.title}"!',
        xpReward: streakDays * 10,
      );

      // Schedule encouragement for next milestone
      await _scheduleNextMilestoneEncouragement(task, streakDays);
    }
  }

  /// Schedule encouragement for next streak milestone
  Future<void> _scheduleNextMilestoneEncouragement(
    Task task, 
    int currentStreak,
  ) async {
    final nextMilestone = _getNextMilestone(currentStreak);
    if (nextMilestone == null) return;

    final daysToNext = nextMilestone - currentStreak;
    final encouragementTime = DateTime.now().add(
      Duration(days: (daysToNext * 0.5).round()),
    );

    debugPrint(
      'Scheduled milestone encouragement for ${task.title}: '
      '$daysToNext days to reach $nextMilestone-day milestone'
    );
  }

  /// Get next streak milestone
  int? _getNextMilestone(int currentStreak) {
    const milestones = [7, 14, 30, 60, 100, 365];
    
    for (final milestone in milestones) {
      if (milestone > currentStreak) {
        return milestone;
      }
    }
    
    return null; // Already at highest milestone
  }

  /// Send weekly progress summary
  Future<void> sendWeeklyProgressSummary({
    required int tasksCompleted,
    required int xpGained,
    required int streaksActive,
    required List<String> topCategories,
  }) async {
    const title = 'Weekly Progress Report 📊';
    final body = 'This week: $tasksCompleted tasks completed, '
                 '+$xpGained XP gained, $streaksActive active streaks! '
                 'Top categories: ${topCategories.take(2).join(", ")}';

    await _notificationService.showAchievementNotification(
      achievementName: title,
      description: body,
    );
  }

  /// Send personalized encouragement based on user patterns
  Future<void> sendPersonalizedEncouragement({
    required String userName,
    required TaskCategory favoriteCategory,
    required int bestStreak,
    required TimeOfDay mostActiveTime,
  }) async {
    final categoryName = _getCategoryDisplayName(favoriteCategory);
    final timeString = mostActiveTime.toString();
    
    final encouragements = [
      'Hey $userName! Your $bestStreak-day streak shows real dedication! 🌟',
      "$userName, you're crushing it in $categoryName! Keep it up! 💪",
      'Perfect timing, $userName! $timeString seems to be your power hour! ⚡',
      'Your consistency in $categoryName is inspiring, $userName! 🚀',
    ];

    final message = encouragements[
      DateTime.now().day % encouragements.length
    ];

    await _notificationService.showAchievementNotification(
      achievementName: 'Personal Note 💌',
      description: message,
    );
  }

  /// Get display name for task category
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

  /// Show streak celebration notification
  Future<void> _showStreakCelebration(Task task) async {
    final streakMilestones = [7, 14, 30, 60, 100, 365];
    
    if (streakMilestones.contains(task.streakCount)) {
      await _notificationService.showAchievementNotification(
        achievementName: 'Streak Master!',
        description: '${task.streakCount} days strong on "${task.title}"',
        xpReward: task.streakCount * 10,
      );
    }
  }

  /// Update notification preferences
  Future<void> updateNotificationPreferences({
    bool enableTaskReminders = true,
    bool enableStreakWarnings = true,
    bool enableAchievements = true,
    bool enableXPGains = false,
    TimeOfDay? defaultReminderTime,
  }) async {
    // Store preferences (would typically save to local storage)
    debugPrint('Updated notification preferences');
    
    if (!enableTaskReminders) {
      // Cancel all task reminder notifications
      final pendingNotifications = await _notificationService.getPendingNotifications();
      for (final notification in pendingNotifications) {
        if (notification.payload?.startsWith('task_reminder:') == true) {
          await _notificationService.cancelNotification(notification.id);
        }
      }
    }
  }

  /// Dispose resources
  void dispose() {
    _dailyCheckTimer?.cancel();
    _streakCheckTimer?.cancel();
  }
}