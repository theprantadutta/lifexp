import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../data/models/task.dart';
import '../../data/models/user.dart';
import '../../data/repositories/progress_repository.dart';
import '../../data/repositories/task_repository.dart';
import '../../data/database/database.dart';
import '../../data/repositories/auth_repository.dart';
import 'notification_service.dart';

/// Service for sending motivational and re-engagement notifications
class MotivationalNotificationService {
  factory MotivationalNotificationService({required LifeXPDatabase database}) {
    _instance._database ??= database;
    _instance._taskRepository ??= TaskRepository(database: database);
    _instance._progressRepository ??= ProgressRepository(database: database);
    _instance._authRepository ??= AuthRepository();
    return _instance;
  }
  MotivationalNotificationService._internal();
  static final MotivationalNotificationService _instance = 
      MotivationalNotificationService._internal();

  final NotificationService _notificationService = NotificationService();
  LifeXPDatabase? _database;
  TaskRepository? _taskRepository;
  ProgressRepository? _progressRepository;
  AuthRepository? _authRepository;

  Timer? _motivationalTimer;
  final Random _random = Random();

  /// Initialize the motivational notification service
  Future<void> initialize() async {
    await _notificationService.initialize();
    _startMotivationalChecks();
  }

  /// Start periodic motivational checks
  void _startMotivationalChecks() {
    // Check for motivational opportunities every 4 hours
    _motivationalTimer = Timer.periodic(
      const Duration(hours: 4),
      (_) => _checkMotivationalOpportunities(),
    );
  }

  /// Check for motivational notification opportunities
  Future<void> _checkMotivationalOpportunities() async {
    try {
      final user = await _authRepository!.getCurrentUser();
      if (user == null) return;

      final lastActivity = await _getLastActivityDate();
      final daysSinceActivity = lastActivity != null 
          ? DateTime.now().difference(lastActivity).inDays 
          : 0;

      if (daysSinceActivity >= 1) {
        await _sendReEngagementNotification(user, daysSinceActivity);
      } else {
        await _sendDailyMotivation(user);
      }
    } catch (e) {
      debugPrint('Failed to check motivational opportunities: $e');
    }
  }

  /// Get last activity date
  Future<DateTime?> _getLastActivityDate() async {
    try {
      final recentTasks = await _taskRepository!.getCompletedTasks('userId'); // TODO: Get actual userId
      if (recentTasks.isEmpty) return null;

      return recentTasks
          .map((task) => task.lastCompletedDate)
          .where((date) => date != null)
          .cast<DateTime>()
          .reduce((a, b) => a.isAfter(b) ? a : b);
    } catch (e) {
      debugPrint('Failed to get last activity date: $e');
      return null;
    }
  }

  /// Send re-engagement notification based on inactivity period
  Future<void> _sendReEngagementNotification(User user, int daysSinceActivity) async {
    final message = _getReEngagementMessage(daysSinceActivity);
    final lastTask = await _getLastCompletedTask();

    await _notificationService.showAchievementNotification(
      achievementName: message['title']!,
      description: message['body']! + 
                   (lastTask != null ? '\n\nLast completed: "${lastTask.title}"' : ''),
    );

    debugPrint('Sent re-engagement notification for $daysSinceActivity days inactive');
  }

  /// Get re-engagement message based on days inactive
  Map<String, String> _getReEngagementMessage(int days) {
    if (days == 1) {
      return {
        'title': 'We miss you! 🌟',
        'body': 'Your journey awaits! Come back and continue building amazing habits.',
      };
    } else if (days <= 3) {
      return {
        'title': 'Your habits are waiting! ⏰',
        'body': "It's been $days days. Your future self will thank you for getting back on track!",
      };
    } else if (days <= 7) {
      return {
        'title': 'Time to restart! 🔄',
        'body': "A week away is okay - what matters is coming back stronger! Let's rebuild those habits.",
      };
    } else if (days <= 14) {
      return {
        'title': 'Fresh start time! 🌱',
        'body': "Two weeks is a good break. Now let's channel that rest into renewed energy and focus!",
      };
    } else {
      return {
        'title': 'Welcome back, champion! 👑',
        'body': 'Every expert was once a beginner. Today is perfect for a fresh start on your journey!',
      };
    }
  }

  /// Get last completed task
  Future<Task?> _getLastCompletedTask() async {
    try {
      final recentTasks = await _taskRepository!.getCompletedTasks('userId'); // TODO: Get actual userId
      return recentTasks.isNotEmpty ? recentTasks.first : null;
    } catch (e) {
      debugPrint('Failed to get last completed task: $e');
      return null;
    }
  }

  /// Send daily motivational notification
  Future<void> _sendDailyMotivation(User user) async {
    // Only send daily motivation 20% of the time to avoid spam
    if (_random.nextDouble() > 0.2) return;

    final motivationType = _selectMotivationType();
    final message = await _generateMotivationalMessage(motivationType, user);

    if (message != null) {
      await _notificationService.showAchievementNotification(
        achievementName: message['title']!,
        description: message['body']!,
      );

      debugPrint('Sent daily motivation: ${motivationType.name}');
    }
  }

  /// Select type of motivational message
  MotivationType _selectMotivationType() {
    const types = MotivationType.values;
    return types[_random.nextInt(types.length)];
  }

  /// Generate motivational message based on type
  Future<Map<String, String>?> _generateMotivationalMessage(
    MotivationType type, 
    User user,
  ) async {
    switch (type) {
      case MotivationType.progress:
        return _generateProgressMessage(user);
      case MotivationType.streak:
        return _generateStreakMessage();
      case MotivationType.achievement:
        return _generateAchievementMessage();
      case MotivationType.inspiration:
        return _generateInspirationalMessage();
      case MotivationType.tip:
        return _generateTipMessage();
      case MotivationType.celebration:
        return _generateCelebrationMessage(user);
    }
  }

  /// Generate progress-based motivational message
  Future<Map<String, String>?> _generateProgressMessage(User user) async {
    try {
      final weeklyProgress = await _progressRepository!.getWeeklyProgressSummary('userId'); // TODO: Get actual userId
      final tasksCompleted = weeklyProgress.fold<int>(
        0, (sum, entry) => sum + (entry['tasksCompleted'] as int? ?? 0),
      );

      if (tasksCompleted == 0) return null;

      return {
        'title': 'Progress Update 📈',
        'body': "You've completed $tasksCompleted tasks this week! "
                'Every task brings you closer to your goals. Keep it up!',
      };
    } catch (e) {
      return null;
    }
  }

  /// Generate streak-based motivational message
  Future<Map<String, String>?> _generateStreakMessage() async {
    try {
      final streakTasks = await _taskRepository!.getTasksWithStreaks('userId'); // TODO: Get actual userId
      if (streakTasks.isEmpty) return null;

      final longestStreak = streakTasks
          .map((task) => task.streakCount)
          .reduce((a, b) => a > b ? a : b);

      return {
        'title': 'Streak Power! 🔥',
        'body': 'Your longest streak is $longestStreak days! '
                'Consistency is your superpower. Keep the momentum going!',
      };
    } catch (e) {
      return null;
    }
  }

  /// Generate achievement-based motivational message
  Future<Map<String, String>?> _generateAchievementMessage() async {
    // This would typically check recent achievements
    // For now, return a generic achievement message
    return {
      'title': 'Achievement Hunter! 🏆',
      'body': 'Every small step is an achievement worth celebrating. '
              "You're building something amazing, one task at a time!",
    };
  }

  /// Generate inspirational message
  Map<String, String> _generateInspirationalMessage() {
    final inspirations = [
      {
        'title': 'Daily Inspiration ✨',
        'body': 'The secret of getting ahead is getting started. '
                "You've already begun - that's the hardest part!",
      },
      {
        'title': 'Mindset Moment 🧠',
        'body': 'Success is the sum of small efforts repeated day in and day out. '
                "You're building that success right now!",
      },
      {
        'title': 'Motivation Boost 🚀',
        'body': "Don't watch the clock; do what it does. Keep going. "
                'Your consistency will compound into amazing results!',
      },
      {
        'title': 'Inner Strength 💪',
        'body': 'You are stronger than you think and more capable than you imagine. '
                'Today is another chance to prove it to yourself!',
      },
      {
        'title': 'Growth Mindset 🌱',
        'body': 'Every expert was once a beginner. Every pro was once an amateur. '
                "You're exactly where you need to be in your journey!",
      },
    ];

    return inspirations[_random.nextInt(inspirations.length)];
  }

  /// Generate tip message
  Map<String, String> _generateTipMessage() {
    final tips = [
      {
        'title': 'Pro Tip 💡',
        'body': "Start with just 2 minutes. It's easier to continue than to start. "
                'Small beginnings lead to big achievements!',
      },
      {
        'title': 'Habit Hack 🔧',
        'body': 'Stack new habits onto existing ones. After I [existing habit], '
                'I will [new habit]. This makes habits stick faster!',
      },
      {
        'title': 'Success Strategy 🎯',
        'body': 'Focus on systems, not goals. Goals are about results, '
                'systems are about the process. Fall in love with the process!',
      },
      {
        'title': 'Productivity Tip ⚡',
        'body': "The best time to do something is when you don't feel like it. "
                "That's when discipline builds character!",
      },
      {
        'title': 'Mindfulness Moment 🧘‍♀️',
        'body': 'Progress, not perfection. Every step forward counts, '
                "even if it's smaller than yesterday's step.",
      },
    ];

    return tips[_random.nextInt(tips.length)];
  }

  /// Generate celebration message
  Future<Map<String, String>?> _generateCelebrationMessage(User user) async {
    try {
      final totalXP = user.totalXP ?? 0;
      final level = user.level ?? 1;

      if (totalXP == 0) return null;

      return {
        'title': 'Celebration Time! 🎉',
        'body': "You're level $level with $totalXP total XP! "
                "Take a moment to appreciate how far you've come. You're amazing!",
      };
    } catch (e) {
      return null;
    }
  }

  /// Send personalized encouragement
  Future<void> sendPersonalizedEncouragement({
    required String userName,
    required TaskCategory favoriteCategory,
    required int bestStreak,
    required String mostActiveTime,
  }) async {
    final categoryName = _getCategoryDisplayName(favoriteCategory);
    
    final personalizedMessages = [
      {
        'title': 'Personal Note 💌',
        'body': 'Hey $userName! Your $bestStreak-day streak shows incredible dedication. '
                "You're building something special! 🌟",
      },
      {
        'title': 'Category Champion 🏆',
        'body': "$userName, you're absolutely crushing it in $categoryName! "
                'Your consistency in this area is truly inspiring! 💪',
      },
      {
        'title': 'Perfect Timing ⏰',
        'body': 'Hey $userName! $mostActiveTime seems to be your power hour. '
                "You've found your rhythm - keep leveraging it! ⚡",
      },
      {
        'title': 'Strength Recognition 💎',
        'body': 'Your dedication to $categoryName is remarkable, $userName! '
                "You're becoming the person you want to be, one day at a time! 🚀",
      },
    ];

    final message = personalizedMessages[_random.nextInt(personalizedMessages.length)];

    await _notificationService.showAchievementNotification(
      achievementName: message['title']!,
      description: message['body']!,
    );
  }

  /// Send weekly motivation summary
  Future<void> sendWeeklyMotivationSummary({
    required int tasksCompleted,
    required int xpGained,
    required int activeStreaks,
    required List<TaskCategory> topCategories,
  }) async {
    final categoryNames = topCategories
        .take(2)
        .map(_getCategoryDisplayName)
        .join(' and ');

    const title = 'Weekly Wins! 🎊';
    final body = 'This week you completed $tasksCompleted tasks, '
                 'gained $xpGained XP, and maintained $activeStreaks streaks! '
                 'Your strongest areas: $categoryNames. '
                 "You're building incredible momentum! 🚀";

    await _notificationService.showAchievementNotification(
      achievementName: title,
      description: body,
    );
  }

  /// Send seasonal motivation
  Future<void> sendSeasonalMotivation() async {
    final now = DateTime.now();
    final month = now.month;
    
    Map<String, String>? seasonalMessage;

    // New Year motivation
    if (month == 1) {
      seasonalMessage = {
        'title': 'New Year, New You! 🎊',
        'body': 'January is the perfect time for fresh starts. '
                "You're already ahead by building consistent habits! Keep going!",
      };
    }
    // Spring motivation
    else if (month >= 3 && month <= 5) {
      seasonalMessage = {
        'title': 'Spring Growth! 🌸',
        'body': 'Just like nature blooms in spring, your habits are blossoming too. '
                'This is your season of growth and renewal!',
      };
    }
    // Summer motivation
    else if (month >= 6 && month <= 8) {
      seasonalMessage = {
        'title': 'Summer Momentum! ☀️',
        'body': 'Summer energy is perfect for building strong habits. '
                'Use these longer days to fuel your progress!',
      };
    }
    // Fall motivation
    else if (month >= 9 && month <= 11) {
      seasonalMessage = {
        'title': 'Autumn Achievement! 🍂',
        'body': "Fall is harvest time - you're reaping the rewards of your consistency. "
                'Your dedication is paying off beautifully!',
      };
    }
    // Winter motivation
    else {
      seasonalMessage = {
        'title': 'Winter Strength! ❄️',
        'body': 'Winter builds character and resilience. '
                'Your commitment during these months shows true dedication!',
      };
    }

    await _notificationService.showAchievementNotification(
      achievementName: seasonalMessage['title']!,
      description: seasonalMessage['body']!,
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
    _motivationalTimer?.cancel();
  }
}

/// Types of motivational messages
enum MotivationType {
  progress,
  streak,
  achievement,
  inspiration,
  tip,
  celebration,
}