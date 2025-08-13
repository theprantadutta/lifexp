import 'package:flutter/material.dart';
import '../../../shared/themes/theme_extensions.dart';

/// Widget that displays motivational messages based on user progress
class MotivationalMessage extends StatelessWidget {

  const MotivationalMessage({
    required this.currentXP, required this.dailyGoal, required this.streakCount, required this.completedTasksToday, super.key,
  });
  final int currentXP;
  final int dailyGoal;
  final int streakCount;
  final int completedTasksToday;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final message = _getMotivationalMessage();
    final icon = _getMotivationalIcon();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            context.xpPrimary.withValues(alpha: 0.1),
            context.xpSecondary.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.xpPrimary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: context.xpPrimary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: context.xpPrimary, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getMessageTitle(),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getMessageTitle() {
    final progress = currentXP / dailyGoal;

    if (progress >= 1.0) {
      return '🎉 Goal Crushed!';
    } else if (progress >= 0.8) {
      return '🔥 Almost There!';
    } else if (progress >= 0.5) {
      return '💪 Great Progress!';
    } else if (completedTasksToday > 0) {
      return '⭐ Keep Going!';
    } else {
      return '🌟 Ready to Start?';
    }
  }

  String _getMotivationalMessage() {
    final progress = currentXP / dailyGoal;

    if (progress >= 1.0) {
      return "Amazing! You've exceeded your daily XP goal. You're unstoppable!";
    } else if (progress >= 0.8) {
      return "You're so close to your daily goal! Just a little more to go.";
    } else if (progress >= 0.5) {
      return 'Halfway there! Your consistency is paying off.';
    } else if (completedTasksToday > 0) {
      return 'Great start today! Every task completed brings you closer to your goals.';
    } else if (streakCount > 0) {
      return "You have a $streakCount-day streak! Don't break the chain today.";
    } else {
      return 'A new day, a new opportunity! Start with a small task to build momentum.';
    }
  }

  IconData _getMotivationalIcon() {
    final progress = currentXP / dailyGoal;

    if (progress >= 1.0) {
      return Icons.emoji_events;
    } else if (progress >= 0.8) {
      return Icons.local_fire_department;
    } else if (progress >= 0.5) {
      return Icons.trending_up;
    } else if (completedTasksToday > 0) {
      return Icons.star;
    } else {
      return Icons.rocket_launch;
    }
  }
}
