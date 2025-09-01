import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../shared/blocs/achievement/achievement_bloc.dart';
import '../../../shared/blocs/achievement/achievement_state.dart';
import '../../../shared/widgets/achievement_badge.dart';

/// Gallery displaying user's achievements with unlock animations
class AchievementGallery extends StatefulWidget {
  const AchievementGallery({super.key});

  @override
  State<AchievementGallery> createState() => _AchievementGalleryState();
}

class _AchievementGalleryState extends State<AchievementGallery> {
  String _selectedFilter = 'all';
  final List<String> _filters = ['all', 'unlocked', 'locked'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return BlocBuilder<AchievementBloc, AchievementState>(
      builder: (context, state) {
        if (state is AchievementLoading) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (state is AchievementError) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: colorScheme.onErrorContainer,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Failed to load achievements',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onErrorContainer,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        if (state is! AchievementLoaded) {
          return const SizedBox.shrink();
        }

        final achievements = state.achievements;
        final unlockedAchievements = achievements.where((a) => a.isUnlocked).toList();
        final lockedAchievements = achievements.where((a) => !a.isUnlocked).toList();
        
        // Filter achievements based on selected filter
        List filteredAchievements;
        switch (_selectedFilter) {
          case 'unlocked':
            filteredAchievements = unlockedAchievements;
            break;
          case 'locked':
            filteredAchievements = lockedAchievements;
            break;
          default:
            filteredAchievements = achievements;
        }

        if (achievements.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.emoji_events_outlined,
                  size: 48,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 16),
                Text(
                  'No achievements yet',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Complete tasks to unlock your first achievement!',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return DecoratedBox(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            children: [
              // Filter tabs
              Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: _filters.map((filter) {
                    final isSelected = _selectedFilter == filter;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedFilter = filter),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? colorScheme.primary.withValues(alpha: 0.2)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              filter == 'all' 
                                  ? 'All (${achievements.length})' 
                                  : filter == 'unlocked' 
                                      ? 'Unlocked (${unlockedAchievements.length})' 
                                      : 'Locked (${lockedAchievements.length})',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: isSelected
                                    ? colorScheme.primary
                                    : colorScheme.onSurfaceVariant,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              
              // Achievement grid
              Padding(
                padding: const EdgeInsets.all(16),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final crossAxisCount = constraints.maxWidth > 600 ? 4 : 3;
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.8,
                      ),
                      itemCount: filteredAchievements.length,
                      itemBuilder: (context, index) {
                        final achievement = filteredAchievements[index];
                        // Check if this achievement was recently unlocked
                        final isRecentlyUnlocked = state.recentUnlocks
                            .any((recent) => recent.id == achievement.id);
                        
                        return GestureDetector(
                          onTap: () => _showAchievementDetails(context, achievement),
                          child: AchievementBadge(
                            title: achievement.title,
                            description: achievement.description,
                            iconPath: 'assets/icons/achievement.png',
                            isUnlocked: achievement.isUnlocked,
                            tier: achievement.tier,
                            showUnlockAnimation: isRecentlyUnlocked,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAchievementDetails(BuildContext context, achievement) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            AchievementBadge(
              title: achievement.title,
              description: achievement.description,
              iconPath: 'assets/icons/achievement.png',
              isUnlocked: achievement.isUnlocked,
              tier: achievement.tier,
              size: 40,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                achievement.title,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              achievement.description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            
            if (achievement.isUnlocked) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Unlocked!',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.lock_outline,
                          color: colorScheme.onSurfaceVariant,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Progress',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: achievement.progress,
                      backgroundColor: colorScheme.outline.withValues(alpha: 0.3),
                      valueColor: AlwaysStoppedAnimation(colorScheme.primary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${(achievement.progress * 100).toInt()}% complete',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
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
}