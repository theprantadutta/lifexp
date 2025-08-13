import 'package:flutter/material.dart';

import '../../../shared/widgets/attribute_bar.dart';

/// Card displaying avatar stats and attributes
class ProfileStatsCard extends StatelessWidget {
  const ProfileStatsCard({
    required this.avatar, super.key,
  });

  final dynamic avatar; // Avatar model

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Attributes',
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Strength
          AttributeBar(
            attributeName: 'Strength',
            currentValue: avatar.strength,
            maxValue: 100,
            color: Colors.red,
            icon: Icons.fitness_center,
          ),
          const SizedBox(height: 12),

          // Wisdom
          AttributeBar(
            attributeName: 'Wisdom',
            currentValue: avatar.wisdom,
            maxValue: 100,
            color: Colors.blue,
            icon: Icons.psychology,
          ),
          const SizedBox(height: 12),

          // Intelligence
          AttributeBar(
            attributeName: 'Intelligence',
            currentValue: avatar.intelligence,
            maxValue: 100,
            color: Colors.purple,
            icon: Icons.school,
          ),
          const SizedBox(height: 16),

          // Overall stats
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  context,
                  'Total XP',
                  avatar.totalXP.toString(),
                  Icons.stars,
                ),
                _buildStatItem(
                  context,
                  'Level',
                  avatar.level.toString(),
                  Icons.trending_up,
                ),
                _buildStatItem(
                  context,
                  'Attributes',
                  '${avatar.strength + avatar.wisdom + avatar.intelligence}',
                  Icons.bar_chart,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        Icon(
          icon,
          color: colorScheme.primary,
          size: 24,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}