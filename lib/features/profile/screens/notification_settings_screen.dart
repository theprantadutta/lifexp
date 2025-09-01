import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../shared/services/notification_service.dart' as notification_service;

/// Screen for managing notification preferences
class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  // Notification preferences
  bool _enableTaskReminders = true;
  bool _enableStreakWarnings = true;
  bool _enableAchievements = true;
  bool _enableXPGains = false;
  TimeOfDay _defaultReminderTime = const TimeOfDay(hour: 9, minute: 0);
  bool _smartScheduling = true;
  int _reminderFrequency = 1; // hours

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  /// Load saved notification preferences
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    
    setState(() {
      _enableTaskReminders = prefs.getBool('enableTaskReminders') ?? true;
      _enableStreakWarnings = prefs.getBool('enableStreakWarnings') ?? true;
      _enableAchievements = prefs.getBool('enableAchievements') ?? true;
      _enableXPGains = prefs.getBool('enableXPGains') ?? false;
      _smartScheduling = prefs.getBool('smartScheduling') ?? true;
      _reminderFrequency = prefs.getInt('reminderFrequency') ?? 1;
      
      // Load reminder time
      final hour = prefs.getInt('reminderHour') ?? 9;
      final minute = prefs.getInt('reminderMinute') ?? 0;
      _defaultReminderTime = TimeOfDay(hour: hour, minute: minute);
    });
  }

  /// Save notification preferences
  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.setBool('enableTaskReminders', _enableTaskReminders);
    await prefs.setBool('enableStreakWarnings', _enableStreakWarnings);
    await prefs.setBool('enableAchievements', _enableAchievements);
    await prefs.setBool('enableXPGains', _enableXPGains);
    await prefs.setBool('smartScheduling', _smartScheduling);
    await prefs.setInt('reminderFrequency', _reminderFrequency);
    await prefs.setInt('reminderHour', _defaultReminderTime.hour);
    await prefs.setInt('reminderMinute', _defaultReminderTime.minute);
  }

  /// Update notification manager with new preferences
  Future<void> _updateNotificationManager() async {
    // This would typically call the notification manager to update settings
    // For now, we'll just save the preferences
    await _savePreferences();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Notification Categories
            Text(
              'Notification Categories',
              style: theme.textTheme.titleLarge?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Task Reminders
            _buildToggleTile(
              icon: Icons.alarm,
              title: 'Task Reminders',
              subtitle: 'Get reminders for your pending tasks',
              value: _enableTaskReminders,
              onChanged: (value) {
                setState(() {
                  _enableTaskReminders = value;
                });
                _updateNotificationManager();
              },
            ),
            
            // Streak Warnings
            _buildToggleTile(
              icon: Icons.local_fire_department,
              title: 'Streak Warnings',
              subtitle: 'Get warnings when your streaks are about to break',
              value: _enableStreakWarnings,
              onChanged: (value) {
                setState(() {
                  _enableStreakWarnings = value;
                });
                _updateNotificationManager();
              },
            ),
            
            // Achievement Notifications
            _buildToggleTile(
              icon: Icons.emoji_events,
              title: 'Achievement Notifications',
              subtitle: 'Get notified when you unlock achievements',
              value: _enableAchievements,
              onChanged: (value) {
                setState(() {
                  _enableAchievements = value;
                });
                _updateNotificationManager();
              },
            ),
            
            // XP Gain Notifications
            _buildToggleTile(
              icon: Icons.star,
              title: 'XP Gain Notifications',
              subtitle: 'Get notified when you earn XP',
              value: _enableXPGains,
              onChanged: (value) {
                setState(() {
                  _enableXPGains = value;
                });
                _updateNotificationManager();
              },
            ),
            
            const SizedBox(height: 32),
            
            // Smart Scheduling
            Text(
              'Smart Scheduling',
              style: theme.textTheme.titleLarge?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            _buildToggleTile(
              icon: Icons.auto_mode,
              title: 'Smart Scheduling',
              subtitle: 'Automatically schedule notifications based on your patterns',
              value: _smartScheduling,
              onChanged: (value) {
                setState(() {
                  _smartScheduling = value;
                });
                _updateNotificationManager();
              },
            ),
            
            const SizedBox(height: 16),
            
            // Default Reminder Time
            ListTile(
              leading: Icon(
                Icons.schedule,
                color: colorScheme.primary,
              ),
              title: const Text('Default Reminder Time'),
              subtitle: Text('${_defaultReminderTime.hour}:${_defaultReminderTime.minute.toString().padLeft(2, '0')}'),
              trailing: IconButton(
                icon: const Icon(Icons.edit),
                onPressed: _selectReminderTime,
              ),
              onTap: _selectReminderTime,
            ),
            
            const SizedBox(height: 16),
            
            // Reminder Frequency
            ListTile(
              leading: Icon(
                Icons.repeat,
                color: colorScheme.primary,
              ),
              title: const Text('Reminder Frequency'),
              subtitle: Text('Every $_reminderFrequency hour${_reminderFrequency > 1 ? 's' : ''}'),
              trailing: IconButton(
                icon: const Icon(Icons.edit),
                onPressed: _selectReminderFrequency,
              ),
              onTap: _selectReminderFrequency,
            ),
            
            const SizedBox(height: 32),
            
            // Notification Test Button
            Center(
              child: ElevatedButton.icon(
                onPressed: _testNotification,
                icon: const Icon(Icons.notifications_active),
                label: const Text('Test Notification'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build a toggle tile for notification settings
  Widget _buildToggleTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(
          icon,
          color: colorScheme.primary,
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
        ),
      ),
    );
  }

  /// Select reminder time
  Future<void> _selectReminderTime() async {
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: _defaultReminderTime,
    );
    
    if (selectedTime != null) {
      setState(() {
        _defaultReminderTime = selectedTime;
      });
      _updateNotificationManager();
    }
  }

  /// Select reminder frequency
  Future<void> _selectReminderFrequency() async {
    int? selectedFrequency = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reminder Frequency'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 1; i <= 12; i++)
              ListTile(
                title: Text('$i hour${i > 1 ? 's' : ''}'),
                onTap: () => Navigator.of(context).pop(i),
              ),
          ],
        ),
      ),
    );
    
    if (selectedFrequency != null) {
      setState(() {
        _reminderFrequency = selectedFrequency;
      });
      _updateNotificationManager();
    }
  }

  /// Test notification
  Future<void> _testNotification() async {
    final notificationService = notification_service.NotificationService();
    await notificationService.showAchievementNotification(
      achievementName: 'Test Notification',
      description: 'This is a test of your notification settings',
    );
    
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Test notification sent!'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}