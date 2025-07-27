import 'package:flutter/material.dart';
import '../themes/theme_extensions.dart';

/// A badge widget for displaying achievements with unlock animations
class AchievementBadge extends StatefulWidget {
  final String title;
  final String description;
  final String iconPath;
  final String tier; // gold, silver, bronze
  final bool isUnlocked;
  final DateTime? unlockedAt;
  final VoidCallback? onTap;
  final double size;
  final bool showUnlockAnimation;

  const AchievementBadge({
    super.key,
    required this.title,
    required this.description,
    required this.iconPath,
    this.tier = 'bronze',
    this.isUnlocked = false,
    this.unlockedAt,
    this.onTap,
    this.size = 80,
    this.showUnlockAnimation = true,
  });

  @override
  State<AchievementBadge> createState() => _AchievementBadgeState();
}

class _AchievementBadgeState extends State<AchievementBadge>
    with TickerProviderStateMixin {
  late AnimationController _unlockController;
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _unlockController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _unlockController,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _unlockController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeInOut),
      ),
    );

    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _unlockController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
      ),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (widget.isUnlocked && widget.showUnlockAnimation) {
      _unlockController.forward();
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(AchievementBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isUnlocked &&
        widget.isUnlocked &&
        widget.showUnlockAnimation) {
      _unlockController.forward();
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _unlockController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tierColor = context.getAchievementColor(widget.tier);

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([_unlockController, _pulseController]),
        builder: (context, child) {
          return Transform.scale(
            scale: widget.isUnlocked
                ? _scaleAnimation.value * _pulseAnimation.value
                : 1.0,
            child: Transform.rotate(
              angle: widget.isUnlocked ? _rotationAnimation.value * 0.1 : 0.0,
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: widget.isUnlocked
                      ? [
                          BoxShadow(
                            color: tierColor.withValues(
                              alpha: 0.4 * _glowAnimation.value,
                            ),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                          BoxShadow(
                            color: tierColor.withValues(
                              alpha: 0.2 * _glowAnimation.value,
                            ),
                            blurRadius: 40,
                            spreadRadius: 10,
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Background circle
                    Container(
                      width: widget.size,
                      height: widget.size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: widget.isUnlocked
                            ? RadialGradient(
                                colors: [
                                  tierColor,
                                  tierColor.withValues(alpha: 0.8),
                                ],
                                stops: const [0.0, 1.0],
                              )
                            : RadialGradient(
                                colors: [
                                  Theme.of(
                                    context,
                                  ).colorScheme.surfaceContainerHighest,
                                  Theme.of(
                                    context,
                                  ).colorScheme.surfaceContainer,
                                ],
                                stops: const [0.0, 1.0],
                              ),
                        border: Border.all(
                          color: widget.isUnlocked
                              ? tierColor.withValues(alpha: 0.3)
                              : Theme.of(
                                  context,
                                ).colorScheme.outline.withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                    ),
                    // Icon or placeholder
                    if (widget.isUnlocked)
                      Icon(
                        Icons.emoji_events, // Placeholder icon
                        size: widget.size * 0.4,
                        color: Colors.white,
                      )
                    else
                      Icon(
                        Icons.lock,
                        size: widget.size * 0.3,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                    // Shine effect for unlocked badges
                    if (widget.isUnlocked)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withValues(
                                  alpha: 0.3 * _glowAnimation.value,
                                ),
                                Colors.transparent,
                                Colors.white.withValues(
                                  alpha: 0.1 * _glowAnimation.value,
                                ),
                              ],
                              stops: const [0.0, 0.5, 1.0],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// A compact achievement badge for lists
class CompactAchievementBadge extends StatelessWidget {
  final String title;
  final String tier;
  final bool isUnlocked;
  final VoidCallback? onTap;

  const CompactAchievementBadge({
    super.key,
    required this.title,
    this.tier = 'bronze',
    this.isUnlocked = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tierColor = context.getAchievementColor(tier);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isUnlocked
              ? tierColor.withValues(alpha: 0.1)
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isUnlocked
                ? tierColor.withValues(alpha: 0.3)
                : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isUnlocked ? Icons.emoji_events : Icons.lock,
              size: 16,
              color: isUnlocked
                  ? tierColor
                  : Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.4),
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: isUnlocked
                    ? tierColor
                    : Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.6),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Achievement badge with detailed information
class DetailedAchievementBadge extends StatelessWidget {
  final String title;
  final String description;
  final String tier;
  final bool isUnlocked;
  final DateTime? unlockedAt;
  final double progress;
  final VoidCallback? onTap;

  const DetailedAchievementBadge({
    super.key,
    required this.title,
    required this.description,
    this.tier = 'bronze',
    this.isUnlocked = false,
    this.unlockedAt,
    this.progress = 0.0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tierColor = context.getAchievementColor(tier);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Badge
              AchievementBadge(
                title: title,
                description: description,
                iconPath: '',
                tier: tier,
                isUnlocked: isUnlocked,
                unlockedAt: unlockedAt,
                size: 60,
                showUnlockAnimation: false,
              ),
              const SizedBox(width: 16),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isUnlocked
                            ? null
                            : Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    if (!isUnlocked && progress > 0) ...[
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation<Color>(tierColor),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${(progress * 100).toInt()}% complete',
                        style: Theme.of(
                          context,
                        ).textTheme.labelSmall?.copyWith(color: tierColor),
                      ),
                    ],
                    if (isUnlocked && unlockedAt != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.check_circle, size: 16, color: tierColor),
                          const SizedBox(width: 4),
                          Text(
                            'Unlocked ${_formatDate(unlockedAt!)}',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: tierColor,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'just now';
    }
  }
}
