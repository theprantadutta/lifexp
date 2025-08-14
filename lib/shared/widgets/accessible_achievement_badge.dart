import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../../data/models/achievement.dart';
import '../services/accessibility_service.dart';

/// Accessible achievement badge with comprehensive screen reader support
class AccessibleAchievementBadge extends StatelessWidget {

  const AccessibleAchievementBadge({
    required this.achievement, super.key,
    this.onTap,
    this.size = 80,
    this.showProgress = true,
    this.showDescription = true,
    this.compact = false,
  });
  final Achievement achievement;
  final VoidCallback? onTap;
  final double size;
  final bool showProgress;
  final bool showDescription;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accessibilityService = AccessibilityService();
    
    final semanticLabel = accessibilityService.createAchievementLabel(
      name: achievement.title,
      description: achievement.description,
      isUnlocked: achievement.isUnlocked,
      progress: achievement.progress.toDouble(),
    );
    
    return Semantics(
      label: semanticLabel,
      hint: achievement.isUnlocked 
          ? 'Achievement unlocked' 
          : showProgress 
              ? 'Achievement progress: ${(achievement.progress * 100).round()}%'
              : 'Achievement locked',
      button: onTap != null,
      enabled: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(compact ? 8 : 12),
        child: Container(
          width: compact ? size * 0.8 : size,
          padding: compact 
              ? const EdgeInsets.all(8)
              : const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(compact ? 8 : 12),
            color: achievement.isUnlocked
                ? theme.colorScheme.primaryContainer
                : theme.colorScheme.surfaceContainerHighest,
            border: Border.all(
              color: achievement.isUnlocked
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outline.withValues(alpha: 0.3),
              width: achievement.isUnlocked ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Badge icon/image
              Stack(
                alignment: Alignment.center,
                children: [
                  // Background circle
                  Container(
                    width: compact ? size * 0.5 : size * 0.6,
                    height: compact ? size * 0.5 : size * 0.6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: achievement.isUnlocked
                          ? theme.colorScheme.primary
                          : theme.colorScheme.surfaceContainerHighest,
                      border: Border.all(
                        color: achievement.isUnlocked
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.outline.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                  ),
                  
                  // Icon
                  Semantics(
                    excludeSemantics: true,
                    child: Icon(
                      _getAchievementIcon(achievement.type),
                      size: compact ? size * 0.25 : size * 0.3,
                      color: achievement.isUnlocked
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                  
                  // Progress indicator for locked achievements
                  if (!achievement.isUnlocked && showProgress && achievement.progress > 0)
                    Positioned.fill(
                      child: Semantics(
                        excludeSemantics: true,
                        child: CircularProgressIndicator(
                          value: achievement.progress.toDouble(),
                          strokeWidth: 3,
                          backgroundColor: Colors.transparent,
                          valueColor: AlwaysStoppedAnimation(
                            theme.colorScheme.primary.withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                    ),
                  
                  // Lock overlay for locked achievements
                  if (!achievement.isUnlocked)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Semantics(
                        excludeSemantics: true,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: theme.colorScheme.surface,
                            border: Border.all(
                              color: theme.colorScheme.outline,
                            ),
                          ),
                          child: Icon(
                            Icons.lock,
                            size: 12,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              
              if (!compact) ...[
                const SizedBox(height: 8),
                
                // Achievement name
                Semantics(
                  header: true,
                  child: Text(
                    achievement.title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: achievement.isUnlocked
                          ? theme.colorScheme.onPrimaryContainer
                          : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                
                // Achievement description
                if (showDescription) ...[
                  const SizedBox(height: 4),
                  Semantics(
                    label: 'Description: ${achievement.description}',
                    child: Text(
                      achievement.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: achievement.isUnlocked
                            ? theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.8)
                            : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                
                // Progress text for locked achievements
                if (!achievement.isUnlocked && showProgress) ...[
                  const SizedBox(height: 4),
                  Semantics(
                    label: 'Progress: ${(achievement.progress * 100).round()} percent complete',
                    child: Text(
                      '${(achievement.progress * 100).round()}%',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
                
                // Unlock date for unlocked achievements
                if (achievement.isUnlocked && achievement.unlockedAt != null) ...[
                  const SizedBox(height: 4),
                  Semantics(
                    label: 'Unlocked on ${_formatDate(achievement.unlockedAt!)}',
                    child: Text(
                      'Unlocked ${_formatDate(achievement.unlockedAt!)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  IconData _getAchievementIcon(AchievementType type) {
    switch (type) {
      case AchievementType.total:
        return Icons.task_alt;
      case AchievementType.streak:
        return Icons.local_fire_department;
      case AchievementType.level:
        return Icons.stars;
      case AchievementType.category:
        return Icons.category;
      case AchievementType.milestone:
        return Icons.flag;
      case AchievementType.special:
        return Icons.diamond;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'today';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return weeks == 1 ? '1 week ago' : '$weeks weeks ago';
    } else {
      final months = (difference.inDays / 30).floor();
      return months == 1 ? '1 month ago' : '$months months ago';
    }
  }
}

/// Accessible achievement grid with proper focus management
class AccessibleAchievementGrid extends StatelessWidget {

  const AccessibleAchievementGrid({
    required this.achievements, super.key,
    this.onAchievementTap,
    this.crossAxisCount = 2,
    this.childAspectRatio = 0.8,
    this.showProgress = true,
    this.showDescription = true,
    this.emptyMessage,
  });
  final List<Achievement> achievements;
  final Function(Achievement)? onAchievementTap;
  final int crossAxisCount;
  final double childAspectRatio;
  final bool showProgress;
  final bool showDescription;
  final String? emptyMessage;

  @override
  Widget build(BuildContext context) {
    final accessibilityService = AccessibilityService();
    
    if (achievements.isEmpty) {
      return Semantics(
        label: emptyMessage ?? 'No achievements available',
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.emoji_events,
                  size: 64,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  emptyMessage ?? 'No achievements yet',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    final unlockedCount = achievements.where((a) => a.isUnlocked).length;
    
    return Semantics(
      label: '${achievements.length} achievements, $unlockedCount unlocked',
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          childAspectRatio: childAspectRatio,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: achievements.length,
        itemBuilder: (context, index) {
          final achievement = achievements[index];
          
          return Semantics(
            sortKey: OrdinalSortKey(index.toDouble()),
            child: AccessibleAchievementBadge(
              achievement: achievement,
              onTap: onAchievementTap != null 
                  ? () => onAchievementTap!(achievement) 
                  : null,
              showProgress: showProgress,
              showDescription: showDescription,
            ),
          );
        },
      ),
    );
  }
}

/// Accessible achievement list for linear layout
class AccessibleAchievementList extends StatelessWidget {

  const AccessibleAchievementList({
    required this.achievements, super.key,
    this.onAchievementTap,
    this.showProgress = true,
    this.showDescription = true,
    this.emptyMessage,
  });
  final List<Achievement> achievements;
  final Function(Achievement)? onAchievementTap;
  final bool showProgress;
  final bool showDescription;
  final String? emptyMessage;

  @override
  Widget build(BuildContext context) {
    final accessibilityService = AccessibilityService();
    
    if (achievements.isEmpty) {
      return Semantics(
        label: emptyMessage ?? 'No achievements available',
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text(
              emptyMessage ?? 'No achievements yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
        ),
      );
    }
    
    return accessibilityService.createAccessibleList(
      semanticLabel: '${achievements.length} achievements',
      children: achievements.asMap().entries.map((entry) {
        final index = entry.key;
        final achievement = entry.value;
        
        return Semantics(
          sortKey: OrdinalSortKey(index.toDouble()),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: AccessibleAchievementBadge(
              achievement: achievement,
              onTap: onAchievementTap != null 
                  ? () => onAchievementTap!(achievement) 
                  : null,
              size: 60,
              showProgress: showProgress,
              showDescription: showDescription,
              compact: true,
            ),
          ),
        );
      }).toList(),
    );
  }
}