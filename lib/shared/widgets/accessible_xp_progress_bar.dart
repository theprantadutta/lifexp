import 'package:flutter/material.dart';
import '../services/accessibility_service.dart';

/// Accessible XP progress bar with comprehensive screen reader support
class AccessibleXPProgressBar extends StatelessWidget {

  const AccessibleXPProgressBar({
    required this.currentXP, required this.xpToNext, required this.level, super.key,
    this.height = 20,
    this.backgroundColor,
    this.progressColor,
    this.showText = true,
    this.animated = true,
    this.animationDuration = const Duration(milliseconds: 500),
  });
  final int currentXP;
  final int xpToNext;
  final int level;
  final double height;
  final Color? backgroundColor;
  final Color? progressColor;
  final bool showText;
  final bool animated;
  final Duration animationDuration;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accessibilityService = AccessibilityService();
    
    final totalXP = currentXP + xpToNext;
    final progress = totalXP > 0 ? currentXP / totalXP : 0.0;
    final percentage = (progress * 100).round();
    
    final semanticLabel = accessibilityService.createXPProgressLabel(
      currentXP,
      xpToNext,
      level,
    );
    
    return Semantics(
      label: semanticLabel,
      value: '$percentage percent',
      hint: 'Experience points progress bar',
      slider: true,
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showText) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Level $level',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '$currentXP / $totalXP XP',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 4),
            ],
            Container(
              height: height,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(height / 2),
                color: backgroundColor ?? theme.colorScheme.surfaceContainerHighest,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(height / 2),
                child: Stack(
                  children: [
                    // Background
                    Container(
                      width: double.infinity,
                      height: height,
                      color: backgroundColor ?? theme.colorScheme.surfaceContainerHighest,
                    ),
                    // Progress
                    if (animated)
                      AnimatedContainer(
                        duration: animationDuration,
                        width: MediaQuery.of(context).size.width * progress,
                        height: height,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              progressColor ?? theme.colorScheme.primary,
                              (progressColor ?? theme.colorScheme.primary).withValues(alpha: 0.8),
                            ],
                          ),
                        ),
                      )
                    else
                      Container(
                        width: MediaQuery.of(context).size.width * progress,
                        height: height,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              progressColor ?? theme.colorScheme.primary,
                              (progressColor ?? theme.colorScheme.primary).withValues(alpha: 0.8),
                            ],
                          ),
                        ),
                      ),
                    // Shine effect for visual appeal
                    if (progress > 0)
                      Positioned(
                        left: 0,
                        top: 0,
                        bottom: 0,
                        width: MediaQuery.of(context).size.width * progress,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(height / 2),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.white.withValues(alpha: 0.3),
                                Colors.transparent,
                                Colors.white.withValues(alpha: 0.1),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (showText) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$percentage% complete',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  if (xpToNext > 0)
                    Text(
                      '$xpToNext XP to next level',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Accessible circular XP progress indicator
class AccessibleCircularXPProgress extends StatelessWidget {

  const AccessibleCircularXPProgress({
    required this.currentXP, required this.xpToNext, required this.level, super.key,
    this.size = 80,
    this.strokeWidth = 8,
    this.backgroundColor,
    this.progressColor,
    this.showText = true,
    this.animated = true,
  });
  final int currentXP;
  final int xpToNext;
  final int level;
  final double size;
  final double strokeWidth;
  final Color? backgroundColor;
  final Color? progressColor;
  final bool showText;
  final bool animated;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accessibilityService = AccessibilityService();
    
    final totalXP = currentXP + xpToNext;
    final progress = totalXP > 0 ? currentXP / totalXP : 0.0;
    final percentage = (progress * 100).round();
    
    final semanticLabel = accessibilityService.createXPProgressLabel(
      currentXP,
      xpToNext,
      level,
    );
    
    return Semantics(
      label: semanticLabel,
      value: '$percentage percent',
      hint: 'Circular experience points progress indicator',
      child: ExcludeSemantics(
        child: SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Background circle
              SizedBox(
                width: size,
                height: size,
                child: CircularProgressIndicator(
                  value: 1,
                  strokeWidth: strokeWidth,
                  backgroundColor: backgroundColor ?? theme.colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation(
                    backgroundColor ?? theme.colorScheme.surfaceContainerHighest,
                  ),
                ),
              ),
              // Progress circle
              SizedBox(
                width: size,
                height: size,
                child: animated
                    ? AnimatedBuilder(
                        animation: AnimationController(
                          duration: const Duration(milliseconds: 1000),
                          vsync: Navigator.of(context),
                        )..forward(),
                        builder: (context, child) => CircularProgressIndicator(
                            value: progress,
                            strokeWidth: strokeWidth,
                            backgroundColor: Colors.transparent,
                            valueColor: AlwaysStoppedAnimation(
                              progressColor ?? theme.colorScheme.primary,
                            ),
                          ),
                      )
                    : CircularProgressIndicator(
                        value: progress,
                        strokeWidth: strokeWidth,
                        backgroundColor: Colors.transparent,
                        valueColor: AlwaysStoppedAnimation(
                          progressColor ?? theme.colorScheme.primary,
                        ),
                      ),
              ),
              // Center content
              if (showText)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$level',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      'LEVEL',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Accessible attribute progress bar
class AccessibleAttributeBar extends StatelessWidget {

  const AccessibleAttributeBar({
    required this.attributeName, required this.currentValue, required this.maxValue, required this.color, required this.icon, super.key,
    this.showText = true,
    this.height = 16,
  });
  final String attributeName;
  final int currentValue;
  final int maxValue;
  final Color color;
  final IconData icon;
  final bool showText;
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accessibilityService = AccessibilityService();
    
    final progress = maxValue > 0 ? currentValue / maxValue : 0.0;
    final percentage = (progress * 100).round();
    
    final semanticLabel = accessibilityService.createAttributeLabel(
      attributeName: attributeName,
      currentValue: currentValue,
      maxValue: maxValue,
    );
    
    return Semantics(
      label: semanticLabel,
      value: '$percentage percent',
      hint: '$attributeName attribute progress',
      slider: true,
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showText) ...[
              Row(
                children: [
                  Icon(
                    icon,
                    size: 16,
                    color: color,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    attributeName,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '$currentValue / $maxValue',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
            ],
            Container(
              height: height,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(height / 2),
                color: theme.colorScheme.surfaceContainerHighest,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(height / 2),
                child: Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      height: height,
                      color: theme.colorScheme.surfaceContainerHighest,
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 800),
                      width: MediaQuery.of(context).size.width * progress,
                      height: height,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            color,
                            color.withValues(alpha: 0.7),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}