import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../data/models/task.dart';

/// Service for managing local notifications
class NotificationService {
  factory NotificationService() => _instance;
  NotificationService._internal();
  static final NotificationService _instance = NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = 
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  /// Initialize the notification service
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      // Android initialization
      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );

      // iOS initialization
      const iosSettings = DarwinInitializationSettings(
        
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      final result = await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      if (result == true) {
        await _requestPermissions();
        _isInitialized = true;
        return true;
      }
    } catch (e) {
      debugPrint('NotificationService: Failed to initialize: $e');
    }

    return false;
  }

  /// Request notification permissions
  Future<bool> _requestPermissions() async {
    if (Platform.isAndroid) {
      final androidPlugin = _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      
      return await androidPlugin?.requestNotificationsPermission() ?? false;
    } else if (Platform.isIOS) {
      final iosPlugin = _notifications
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      
      return await iosPlugin?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      ) ?? false;
    }
    
    return true;
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
    // TODO: Navigate to appropriate screen based on payload
  }

  /// Schedule a task reminder notification
  Future<void> scheduleTaskReminder({
    required Task task,
    required DateTime scheduledTime,
    String? customMessage,
  }) async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) return;
    }

    try {
      final id = task.id.hashCode;
      final title = customMessage ?? 'Task Reminder';
      final body = "Don't forget: ${task.title}";

      await _notifications.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledTime, tz.local),
        _getNotificationDetails(task),
        payload: 'task_reminder:${task.id}',
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );

      debugPrint('Scheduled reminder for task: ${task.title} at $scheduledTime');
    } catch (e) {
      debugPrint('Failed to schedule task reminder: $e');
    }
  }

  /// Schedule daily task reminders
  Future<void> scheduleDailyReminders({
    required List<Task> tasks,
    required TimeOfDay reminderTime,
  }) async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) return;
    }

    for (final task in tasks) {
      if (task.type == TaskType.daily && !task.isCompleted) {
        final now = DateTime.now();
        var scheduledTime = DateTime(
          now.year,
          now.month,
          now.day,
          reminderTime.hour,
          reminderTime.minute,
        );

        // If the time has passed today, schedule for tomorrow
        if (scheduledTime.isBefore(now)) {
          scheduledTime = scheduledTime.add(const Duration(days: 1));
        }

        await scheduleTaskReminder(
          task: task,
          scheduledTime: scheduledTime,
          customMessage: 'Daily Task Reminder',
        );
      }
    }
  }

  /// Schedule streak warning notification
  Future<void> scheduleStreakWarning({
    required Task task,
    required DateTime warningTime,
  }) async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) return;
    }

    try {
      final id = 'streak_warning_${task.id}'.hashCode;
      const title = 'Streak Alert! 🔥';
      final body = 'Your ${task.streakCount}-day streak for "${task.title}" '
                   'is about to break! Complete it now to keep going.';

      await _notifications.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(warningTime, tz.local),
        _getStreakWarningDetails(),
        payload: 'streak_warning:${task.id}',
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );

      debugPrint('Scheduled streak warning for: ${task.title}');
    } catch (e) {
      debugPrint('Failed to schedule streak warning: $e');
    }
  }

  /// Show immediate achievement notification
  Future<void> showAchievementNotification({
    required String achievementName,
    required String description,
    int? xpReward,
  }) async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) return;
    }

    try {
      const id = 999999; // Use a high ID for immediate notifications
      const title = '🏆 Achievement Unlocked!';
      final body = '$achievementName\n$description${xpReward != null ? '\n+$xpReward XP' : ''}';

      await _notifications.show(
        id,
        title,
        body,
        _getAchievementDetails(),
        payload: 'achievement:$achievementName',
      );

      debugPrint('Showed achievement notification: $achievementName');
    } catch (e) {
      debugPrint('Failed to show achievement notification: $e');
    }
  }

  /// Show XP gain notification
  Future<void> showXPGainNotification({
    required int xpGained,
    required String source,
  }) async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) return;
    }

    try {
      const id = 999998;
      const title = '⭐ XP Gained!';
      final body = '+$xpGained XP from $source';

      await _notifications.show(
        id,
        title,
        body,
        _getXPGainDetails(),
        payload: 'xp_gain:$xpGained',
      );
    } catch (e) {
      debugPrint('Failed to show XP gain notification: $e');
    }
  }

  /// Cancel a specific notification
  Future<void> cancelNotification(int id) async {
    try {
      await _notifications.cancel(id);
      debugPrint('Cancelled notification: $id');
    } catch (e) {
      debugPrint('Failed to cancel notification: $e');
    }
  }

  /// Cancel all task reminders for a specific task
  Future<void> cancelTaskReminders(String taskId) async {
    try {
      final id = taskId.hashCode;
      await _notifications.cancel(id);
      
      final streakWarningId = 'streak_warning_$taskId'.hashCode;
      await _notifications.cancel(streakWarningId);
      
      debugPrint('Cancelled reminders for task: $taskId');
    } catch (e) {
      debugPrint('Failed to cancel task reminders: $e');
    }
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    try {
      await _notifications.cancelAll();
      debugPrint('Cancelled all notifications');
    } catch (e) {
      debugPrint('Failed to cancel all notifications: $e');
    }
  }

  /// Get notification details for task reminders
  NotificationDetails _getNotificationDetails(Task task) {
    final categoryColor = _getCategoryColor(task.category);
    
    final androidDetails = AndroidNotificationDetails(
      'task_reminders',
      'Task Reminders',
      channelDescription: 'Reminders for your daily tasks',
      importance: Importance.high,
      priority: Priority.high,
      color: categoryColor,
      icon: '@drawable/ic_task',
      actions: [
        const AndroidNotificationAction(
          'complete',
          'Complete',
          showsUserInterface: true,
        ),
        const AndroidNotificationAction(
          'snooze',
          'Snooze 1h',
        ),
      ],
    );

    const iosDetails = DarwinNotificationDetails(
      categoryIdentifier: 'task_reminder',
      interruptionLevel: InterruptionLevel.active,
    );

    return NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
  }

  /// Get notification details for streak warnings
  NotificationDetails _getStreakWarningDetails() {
    const androidDetails = AndroidNotificationDetails(
      'streak_warnings',
      'Streak Warnings',
      channelDescription: 'Warnings when your streaks are about to break',
      importance: Importance.max,
      priority: Priority.max,
      color: Color(0xFFFF6B35), // Orange warning color
      icon: '@drawable/ic_streak',
      actions: [
        AndroidNotificationAction(
          'complete_now',
          'Complete Now',
          showsUserInterface: true,
        ),
      ],
    );

    const iosDetails = DarwinNotificationDetails(
      categoryIdentifier: 'streak_warning',
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    return const NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
  }

  /// Get notification details for achievements
  NotificationDetails _getAchievementDetails() {
    const androidDetails = AndroidNotificationDetails(
      'achievements',
      'Achievements',
      channelDescription: 'Achievement unlock notifications',
      importance: Importance.high,
      priority: Priority.high,
      color: Color(0xFFFFD700), // Gold color
      icon: '@drawable/ic_achievement',
    );

    const iosDetails = DarwinNotificationDetails(
      categoryIdentifier: 'achievement',
      interruptionLevel: InterruptionLevel.active,
      sound: 'achievement.wav',
    );

    return const NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
  }

  /// Get notification details for XP gains
  NotificationDetails _getXPGainDetails() {
    const androidDetails = AndroidNotificationDetails(
      'xp_gains',
      'XP Gains',
      channelDescription: 'Experience point gain notifications',
      importance: Importance.low,
      priority: Priority.low,
      color: Color(0xFF4CAF50), // Green color
      icon: '@drawable/ic_xp',
      timeoutAfter: 3000, // Auto-dismiss after 3 seconds
    );

    const iosDetails = DarwinNotificationDetails(
      categoryIdentifier: 'xp_gain',
      interruptionLevel: InterruptionLevel.passive,
    );

    return const NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
  }

  /// Get color for task category
  Color _getCategoryColor(TaskCategory category) {
    switch (category) {
      case TaskCategory.health:
        return const Color(0xFF4CAF50); // Green
      case TaskCategory.finance:
        return const Color(0xFF2196F3); // Blue
      case TaskCategory.work:
        return const Color(0xFF9C27B0); // Purple
      case TaskCategory.learning:
        return const Color(0xFFFF9800); // Orange
      case TaskCategory.social:
        return const Color(0xFFE91E63); // Pink
      case TaskCategory.creative:
        return const Color(0xFF00BCD4); // Cyan
      case TaskCategory.fitness:
        return const Color(0xFF8BC34A); // Light Green
      case TaskCategory.mindfulness:
        return const Color(0xFF673AB7); // Deep Purple
      case TaskCategory.custom:
        return const Color(0xFF607D8B); // Blue Grey
    }
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    if (!_isInitialized) return false;
    
    if (Platform.isAndroid) {
      final androidPlugin = _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      return await androidPlugin?.areNotificationsEnabled() ?? false;
    }
    
    return true; // iOS handles this at the system level
  }

  /// Get pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    try {
      return await _notifications.pendingNotificationRequests();
    } catch (e) {
      debugPrint('Failed to get pending notifications: $e');
      return [];
    }
  }
}

/// Time of day helper
class TimeOfDay {
  const TimeOfDay({required this.hour, required this.minute});
  
  final int hour;
  final int minute;
  
  @override
  String toString() => '${hour.toString().padLeft(2, '0')}:'
                      '${minute.toString().padLeft(2, '0')}';
}