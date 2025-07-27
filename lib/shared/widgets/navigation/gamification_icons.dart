import 'package:flutter/material.dart';

/// Custom gamification-themed icons for navigation and UI elements
class GamificationIcons {
  // Navigation tab icons
  static const IconData home = Icons.home_rounded;
  static const IconData homeOutlined = Icons.home_outlined;

  static const IconData tasks = Icons.assignment_turned_in_rounded;
  static const IconData tasksOutlined = Icons.assignment_outlined;

  static const IconData progress = Icons.trending_up_rounded;
  static const IconData progressOutlined = Icons.trending_up_outlined;

  static const IconData world = Icons.explore_rounded;
  static const IconData worldOutlined = Icons.explore_outlined;

  static const IconData profile = Icons.account_circle_rounded;
  static const IconData profileOutlined = Icons.account_circle_outlined;

  // Action icons
  static const IconData addTask = Icons.add_task_rounded;
  static const IconData quickAdd = Icons.flash_on_rounded;

  // Achievement and XP icons
  static const IconData xp = Icons.bolt_rounded;
  static const IconData level = Icons.military_tech_rounded;
  static const IconData achievement = Icons.emoji_events_rounded;
  static const IconData streak = Icons.local_fire_department_rounded;

  // Category icons
  static const IconData health = Icons.favorite_rounded;
  static const IconData finance = Icons.account_balance_wallet_rounded;
  static const IconData work = Icons.work_rounded;
  static const IconData learning = Icons.school_rounded;
  static const IconData custom = Icons.star_rounded;

  // Attribute icons
  static const IconData strength = Icons.fitness_center_rounded;
  static const IconData wisdom = Icons.psychology_rounded;
  static const IconData intelligence = Icons.lightbulb_rounded;

  // World elements
  static const IconData worldTile = Icons.landscape_rounded;
  static const IconData building = Icons.domain_rounded;
  static const IconData unlock = Icons.lock_open_rounded;

  // Settings and drawer icons
  static const IconData settings = Icons.settings_rounded;
  static const IconData themes = Icons.palette_rounded;
  static const IconData notifications = Icons.notifications_rounded;
  static const IconData help = Icons.help_outline_rounded;
  static const IconData about = Icons.info_outline_rounded;
}

/// Custom icon widget with gamification styling
class GamificationIcon extends StatelessWidget {
  final IconData icon;
  final double? size;
  final Color? color;
  final bool isActive;
  final bool showGlow;

  const GamificationIcon({
    super.key,
    required this.icon,
    this.size,
    this.color,
    this.isActive = false,
    this.showGlow = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconColor =
        color ??
        (isActive
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurface.withValues(alpha: 0.6));

    Widget iconWidget = Icon(icon, size: size ?? 24, color: iconColor);

    if (showGlow && isActive) {
      iconWidget = Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: iconColor.withValues(alpha: 0.3),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
        child: iconWidget,
      );
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: iconWidget,
    );
  }
}
