import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../shared/blocs/achievement/achievement_bloc.dart';
import '../../../shared/blocs/achievement/achievement_state.dart';
import '../../../shared/widgets/achievement_badge.dart';
import '../widgets/achievement_gallery.dart';

/// Dedicated screen for achievement gallery with enhanced features
class AchievementGalleryScreen extends StatelessWidget {
  const AchievementGalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Achievement Gallery'),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => _showAchievementStats(context),
            icon: const Icon(Icons.bar_chart),
          ),
          IconButton(
            onPressed: () => _showAchievementHelp(context),
            icon: const Icon(Icons.help_outline),
          ),
        ],
      ),
      body: BlocBuilder<AchievementBloc, AchievementState>(
        builder: (context, state) {
          if (state is AchievementLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (state is AchievementError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load achievements',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.message,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      // TODO: Implement retry logic
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Retry functionality coming soon!'),
                        ),
                      );
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is! AchievementLoaded) {
            return const SizedBox.shrink();
          }

          final stats = state.stats;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stats summary
                _buildStatsSummary(context, stats),
                const SizedBox(height: 24),

                // Achievement gallery
                _buildAchievementGallery(context),
                const SizedBox(height: 24),

                // Recent unlocks
                if (state.recentUnlocks.isNotEmpty) ...[
                  _buildRecentUnlocks(context, state.recentUnlocks),
                  const SizedBox(height: 24),
                ],

                // Achievement tips
                _buildAchievementTips(context),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatsSummary(BuildContext context, stats) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
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
      ),
      child: Column(
        children: [
          Text(
            'Achievement Progress',
            style: theme.textTheme.titleLarge?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                context,
                Icons.emoji_events,
                '${stats.unlocked}',
                'Unlocked',
                colorScheme.primary,
              ),
              _buildStatItem(
                context,
                Icons.lock_outline,
                '${stats.locked}',
                'Locked',
                colorScheme.onSurfaceVariant,
              ),
              _buildStatItem(
                context,
                Icons.auto_graph,
                '${(stats.completionRate * 100).toInt()}%',
                'Complete',
                colorScheme.secondary,
              ),
            ],
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: stats.completionRate,
            backgroundColor: colorScheme.outline.withValues(alpha: 0.3),
            valueColor: AlwaysStoppedAnimation(colorScheme.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Icon(icon, size: 32, color: color),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.headlineSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildAchievementGallery(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'All Achievements',
          style: theme.textTheme.titleLarge?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        const AchievementGallery(),
      ],
    );
  }

  Widget _buildRecentUnlocks(BuildContext context, recentUnlocks) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recently Unlocked',
          style: theme.textTheme.titleLarge?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            children: recentUnlocks.map<Widget>((achievement) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: DetailedAchievementBadge(
                  title: achievement.title,
                  description: achievement.description,
                  tier: achievement.tier,
                  isUnlocked: achievement.isUnlocked,
                  unlockedAt: achievement.unlockedAt,
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildAchievementTips(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Achievement Tips',
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildTipItem(
            context,
            Icons.check_circle_outline,
            'Complete daily tasks to earn XP and unlock achievements',
          ),
          const SizedBox(height: 8),
          _buildTipItem(
            context,
            Icons.stars,
            'Higher tier achievements give more rewards',
          ),
          const SizedBox(height: 8),
          _buildTipItem(
            context,
            Icons.track_changes,
            'Check your progress regularly to stay motivated',
          ),
        ],
      ),
    );
  }

  Widget _buildTipItem(BuildContext context, IconData icon, String text) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Icon(icon, size: 20, color: colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }

  void _showAchievementStats(BuildContext context) {
    final state = context.read<AchievementBloc>().state;
    if (state is! AchievementLoaded) return;

    final stats = state.stats;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Achievement Statistics'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatRow(context, 'Total Achievements', '${stats.total}'),
              _buildStatRow(context, 'Unlocked', '${stats.unlocked}'),
              _buildStatRow(context, 'Locked', '${stats.locked}'),
              _buildStatRow(context, 'Unlockable', '${stats.unlockable}'),
              _buildStatRow(
                context,
                'Completion Rate',
                '${(stats.completionRate * 100).toInt()}%',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _showAchievementHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Achievement Help'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'About Achievements:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                  'Achievements are rewards you earn by completing tasks and reaching milestones in LifeXP.'),
              SizedBox(height: 16),
              Text(
                'How to unlock achievements:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Complete daily tasks to earn XP'),
              SizedBox(height: 4),
              Text('• Reach specific milestones (e.g., 100 tasks completed)'),
              SizedBox(height: 4),
              Text('• Maintain streaks for special rewards'),
              SizedBox(height: 4),
              Text('• Explore different categories for varied achievements'),
              SizedBox(height: 16),
              Text(
                'Achievement tiers:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Bronze: Entry-level achievements'),
              SizedBox(height: 4),
              Text('• Silver: Intermediate achievements'),
              SizedBox(height: 4),
              Text('• Gold: Advanced achievements'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}