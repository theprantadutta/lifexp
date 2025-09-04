import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../shared/blocs/navigation/navigation_cubit.dart';
import '../../../shared/widgets/attribute_bar.dart';
import '../../../shared/widgets/navigation/custom_app_bar.dart';
import '../../../shared/widgets/task_card.dart';
import '../../../shared/widgets/xp_progress_bar.dart';
import '../widgets/daily_streak_widget.dart';
import '../widgets/motivational_message.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: const CustomAppBar(title: 'LifeXP', showBackButton: false),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar and Level Section
            _buildAvatarSection(context, colorScheme),
            const SizedBox(height: 20),

            // Motivational Message Section
            const MotivationalMessage(
              currentXP: 180,
              dailyGoal: 250,
              streakCount: 7,
              completedTasksToday: 2,
            ),
            const SizedBox(height: 20),

            // Daily XP Goal Section
            _buildDailyGoalSection(context, colorScheme),
            const SizedBox(height: 20),

            // Daily Streak Section
            const DailyStreakWidget(
              currentStreak: 7,
              longestStreak: 12,
              completedToday: true,
            ),
            const SizedBox(height: 20),

            // Attributes Section
            _buildAttributesSection(context, colorScheme),
            const SizedBox(height: 20),

            // Today's Tasks Section
            _buildTodaysTasksSection(context, colorScheme),
            const SizedBox(height: 20),

            // Quick Actions Section
            _buildQuickActionsSection(context, colorScheme),
            const SizedBox(height: 20), // Extra padding at bottom
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarSection(BuildContext context, ColorScheme colorScheme) => Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary.withValues(alpha: 0.1),
            colorScheme.secondary.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          // Avatar placeholder - will be replaced with actual avatar widget
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(color: colorScheme.primary, width: 2),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(Icons.person, size: 40, color: colorScheme.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'Level 12 Adventurer',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const XPProgressBar(
                  currentXP: 2450,
                  maxXP: 3000,
                ),
                const SizedBox(height: 4),
                Text(
                  '550 XP to next level',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );

  Widget _buildDailyGoalSection(BuildContext context, ColorScheme colorScheme) => Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.track_changes, color: colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Daily XP Goal',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const XPProgressBar(
            currentXP: 180,
            maxXP: 250,
            height: 8,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '180 / 250 XP earned today',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '72%',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

  Widget _buildAttributesSection(
    BuildContext context,
    ColorScheme colorScheme,
  ) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Attributes',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        const AttributeBar(
          attributeName: 'Strength',
          currentValue: 45,
          maxValue: 100,
          icon: Icons.fitness_center,
        ),
        const SizedBox(height: 8),
        const AttributeBar(
          attributeName: 'Wisdom',
          currentValue: 62,
          maxValue: 100,
          icon: Icons.psychology,
        ),
        const SizedBox(height: 8),
        const AttributeBar(
          attributeName: 'Intelligence',
          currentValue: 38,
          maxValue: 100,
          icon: Icons.lightbulb,
        ),
      ],
    );

  Widget _buildTodaysTasksSection(
    BuildContext context,
    ColorScheme colorScheme,
  ) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Today's Tasks",
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () {
                // Navigate to tasks screen
                context.read<NavigationCubit>().navigateToTasks();
              },
              child: Text(
                'View All',
                style: TextStyle(color: colorScheme.primary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Sample tasks - these would come from BLoC in real implementation
        const TaskCard(
          title: 'Morning Workout',
          category: 'Health',
          xpReward: 50,
          difficulty: 2,
          isCompleted: true,
          streakCount: 7,
        ),
        const SizedBox(height: 8),
        const TaskCard(
          title: 'Read for 30 minutes',
          category: 'Learning',
          xpReward: 30,
          difficulty: 1,
          streakCount: 3,
        ),
        const SizedBox(height: 8),
        const TaskCard(
          title: 'Complete project milestone',
          category: 'Work',
          xpReward: 100,
          difficulty: 3,
        ),
      ],
    );

  Widget _buildQuickActionsSection(
    BuildContext context,
    ColorScheme colorScheme,
  ) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                context,
                colorScheme,
                icon: Icons.add_task,
                title: 'Add Task',
                subtitle: 'Create new task',
                onTap: () {
                  // Navigate to add task
                  context.read<NavigationCubit>().navigateToTasks();
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionCard(
                context,
                colorScheme,
                icon: Icons.emoji_events,
                title: 'Achievements',
                subtitle: 'View progress',
                onTap: () {
                  // Navigate to achievements
                  context.read<NavigationCubit>().navigateToProfile();
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                context,
                colorScheme,
                icon: Icons.analytics,
                title: 'Progress',
                subtitle: 'View stats',
                onTap: () {
                  // Navigate to progress
                  context.read<NavigationCubit>().navigateToProgress();
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionCard(
                context,
                colorScheme,
                icon: Icons.public,
                title: 'World',
                subtitle: 'Explore map',
                onTap: () {
                  // Navigate to world
                  context.read<NavigationCubit>().navigateToAnalytics();
                },
              ),
            ),
          ],
        ),
      ],
    );

  Widget _buildQuickActionCard(
    BuildContext context,
    ColorScheme colorScheme, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) => InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: colorScheme.primary, size: 20),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.7),
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
}
