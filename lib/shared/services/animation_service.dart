import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// Service for managing celebration animations throughout the app
class AnimationService {
  static const Duration _defaultDuration = Duration(seconds: 3);

  /// Shows a level up celebration animation
  static void showLevelUpCelebration(
    BuildContext context, {
    int? newLevel,
    VoidCallback? onComplete,
  }) {
    _showCelebrationOverlay(
      context,
      animationPath: 'assets/animations/level_up.json',
      title: 'Level Up!',
      subtitle: newLevel != null ? 'Level $newLevel' : null,
      onComplete: onComplete,
    );
  }

  /// Shows an achievement unlock celebration animation
  static void showAchievementUnlock(
    BuildContext context, {
    required String achievementName,
    VoidCallback? onComplete,
  }) {
    _showCelebrationOverlay(
      context,
      animationPath: 'assets/animations/achievement_unlock.json',
      title: 'Achievement Unlocked!',
      subtitle: achievementName,
      onComplete: onComplete,
    );
  }

  /// Shows a task completion success animation
  static void showTaskCompletion(
    BuildContext context, {
    required int xpGained,
    VoidCallback? onComplete,
  }) {
    _showCelebrationOverlay(
      context,
      animationPath: 'assets/animations/task_complete.json',
      title: 'Task Complete!',
      subtitle: '+$xpGained XP',
      duration: const Duration(seconds: 2),
      onComplete: onComplete,
    );
  }

  /// Shows a streak milestone celebration
  static void showStreakMilestone(
    BuildContext context, {
    required int streakCount,
    VoidCallback? onComplete,
  }) {
    _showCelebrationOverlay(
      context,
      animationPath: 'assets/animations/streak_fire.json',
      title: 'Streak Milestone!',
      subtitle: '$streakCount days in a row!',
      onComplete: onComplete,
    );
  }

  /// Shows a generic celebration animation
  static void showGenericCelebration(
    BuildContext context, {
    required String title,
    String? subtitle,
    VoidCallback? onComplete,
  }) {
    _showCelebrationOverlay(
      context,
      animationPath: 'assets/animations/celebration.json',
      title: title,
      subtitle: subtitle,
      onComplete: onComplete,
    );
  }

  /// Internal method to show celebration overlay
  static void _showCelebrationOverlay(
    BuildContext context, {
    required String animationPath,
    required String title,
    String? subtitle,
    Duration duration = _defaultDuration,
    VoidCallback? onComplete,
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => CelebrationOverlay(
        animationPath: animationPath,
        title: title,
        subtitle: subtitle,
        duration: duration,
        onComplete: () {
          overlayEntry.remove();
          onComplete?.call();
        },
      ),
    );

    overlay.insert(overlayEntry);
  }
}

/// Widget that displays celebration animations as an overlay
class CelebrationOverlay extends StatefulWidget {
  const CelebrationOverlay({
    required this.animationPath, required this.title, super.key,
    this.subtitle,
    this.duration = const Duration(seconds: 3),
    this.onComplete,
  });

  final String animationPath;
  final String title;
  final String? subtitle;
  final Duration duration;
  final VoidCallback? onComplete;

  @override
  State<CelebrationOverlay> createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends State<CelebrationOverlay>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    // Start animations
    _fadeController.forward();
    _scaleController.forward();

    // Auto-dismiss after duration
    Future.delayed(widget.duration, () {
      if (mounted) {
        _dismissAnimation();
      }
    });
  }

  void _dismissAnimation() {
    _fadeController.reverse().then((_) {
      if (mounted) {
        widget.onComplete?.call();
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: _dismissAnimation,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.black.withValues(alpha: 0.7),
          child: AnimatedBuilder(
            animation: Listenable.merge([_fadeAnimation, _scaleAnimation]),
            builder: (context, child) => Opacity(
                opacity: _fadeAnimation.value,
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Lottie animation
                        SizedBox(
                          width: 200,
                          height: 200,
                          child: Lottie.asset(
                            widget.animationPath,
                            repeat: true,
                            animate: true,
                            fit: BoxFit.contain,
                            // Fallback to a simple icon if animation fails to load
                            errorBuilder: (context, error, stackTrace) => Container(
                                width: 200,
                                height: 200,
                                decoration: BoxDecoration(
                                  color: colorScheme.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.celebration,
                                  size: 100,
                                  color: colorScheme.onPrimary,
                                ),
                              ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Title
                        Text(
                          widget.title,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.5),
                                offset: const Offset(0, 2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),

                        // Subtitle
                        if (widget.subtitle != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            widget.subtitle!,
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
                              shadows: [
                                Shadow(
                                  color: Colors.black.withValues(alpha: 0.5),
                                  offset: const Offset(0, 1),
                                  blurRadius: 2,
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],

                        const SizedBox(height: 32),

                        // Tap to dismiss hint
                        Text(
                          'Tap to continue',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ),
        ),
      ),
    );
  }
}