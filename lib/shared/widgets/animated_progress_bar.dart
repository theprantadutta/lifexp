import 'package:flutter/material.dart';

/// Animated progress bar with smooth filling animations
class AnimatedProgressBar extends StatefulWidget {
  const AnimatedProgressBar({
    required this.progress, super.key,
    this.height = 20,
    this.backgroundColor,
    this.progressColor,
    this.gradient,
    this.borderRadius,
    this.animationDuration = const Duration(milliseconds: 800),
    this.animationCurve = Curves.easeInOut,
    this.showPercentage = false,
    this.textStyle,
    this.milestoneMarkers = const [],
  });

  final double progress; // 0.0 to 1.0
  final double height;
  final Color? backgroundColor;
  final Color? progressColor;
  final Gradient? gradient;
  final BorderRadius? borderRadius;
  final Duration animationDuration;
  final Curve animationCurve;
  final bool showPercentage;
  final TextStyle? textStyle;
  final List<double> milestoneMarkers; // Progress values for milestone markers

  @override
  State<AnimatedProgressBar> createState() => _AnimatedProgressBarState();
}

class _AnimatedProgressBarState extends State<AnimatedProgressBar>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnimation;
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  double _currentProgress = 0;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _progressAnimation = Tween<double>(
      begin: 0,
      end: widget.progress,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.animationCurve,
    ));

    _glowAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));

    _controller.forward();
    _currentProgress = widget.progress;
  }

  @override
  void didUpdateWidget(AnimatedProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.progress != oldWidget.progress) {
      _progressAnimation = Tween<double>(
        begin: _currentProgress,
        end: widget.progress,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: widget.animationCurve,
      ));

      _controller.reset();
      _controller.forward();
      _currentProgress = widget.progress;

      // Show glow effect when progress increases significantly
      if (widget.progress > oldWidget.progress + 0.1) {
        _glowController.forward().then((_) {
          _glowController.reverse();
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final backgroundColor = widget.backgroundColor ?? 
        colorScheme.surfaceContainerHighest;
    final progressColor = widget.progressColor ?? colorScheme.primary;
    final borderRadius = widget.borderRadius ?? 
        BorderRadius.circular(widget.height / 2);

    return AnimatedBuilder(
      animation: Listenable.merge([_progressAnimation, _glowAnimation]),
      builder: (context, child) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                // Background
                Container(
                  height: widget.height,
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: borderRadius,
                  ),
                ),

                // Progress fill
                FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: _progressAnimation.value.clamp(0.0, 1.0),
                  child: Container(
                    height: widget.height,
                    decoration: BoxDecoration(
                      color: widget.gradient == null ? progressColor : null,
                      gradient: widget.gradient,
                      borderRadius: borderRadius,
                      boxShadow: _glowAnimation.value > 0
                          ? [
                              BoxShadow(
                                color: progressColor.withValues(
                                  alpha: _glowAnimation.value * 0.6,
                                ),
                                blurRadius: 8 * _glowAnimation.value,
                                spreadRadius: 2 * _glowAnimation.value,
                              ),
                            ]
                          : null,
                    ),
                  ),
                ),

                // Milestone markers
                if (widget.milestoneMarkers.isNotEmpty)
                  ...widget.milestoneMarkers.map((milestone) => Positioned(
                      left: milestone * MediaQuery.of(context).size.width * 0.8,
                      top: 0,
                      bottom: 0,
                      child: Container(
                        width: 2,
                        color: colorScheme.outline.withValues(alpha: 0.5),
                      ),
                    )),

                // Percentage text
                if (widget.showPercentage)
                  Positioned.fill(
                    child: Center(
                      child: Text(
                        '${(_progressAnimation.value * 100).toInt()}%',
                        style: widget.textStyle ??
                            theme.textTheme.labelSmall?.copyWith(
                              color: _progressAnimation.value > 0.5
                                  ? colorScheme.onPrimary
                                  : colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
    );
  }
}

/// XP Progress bar with level indicators
class XPProgressBar extends StatefulWidget {
  const XPProgressBar({
    required this.currentXP, required this.xpToNextLevel, required this.level, super.key,
    this.height = 24,
    this.showLevel = true,
    this.showXPText = true,
  });

  final int currentXP;
  final int xpToNextLevel;
  final int level;
  final double height;
  final bool showLevel;
  final bool showXPText;

  @override
  State<XPProgressBar> createState() => _XPProgressBarState();
}

class _XPProgressBarState extends State<XPProgressBar> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final totalXP = widget.currentXP + widget.xpToNextLevel;
    final progress = totalXP > 0 ? widget.currentXP / totalXP : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Level and XP info
        if (widget.showLevel || widget.showXPText)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (widget.showLevel)
                  Text(
                    'Level ${widget.level}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                if (widget.showXPText)
                  Text(
                    '${widget.currentXP} / $totalXP XP',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),

        // Progress bar
        AnimatedProgressBar(
          progress: progress,
          height: widget.height,
          gradient: LinearGradient(
            colors: [
              colorScheme.primary,
              colorScheme.secondary,
            ],
          ),
        ),
      ],
    );
  }
}

/// Attribute progress bar with icon
class AttributeProgressBar extends StatelessWidget {
  const AttributeProgressBar({
    required this.attributeName, required this.currentValue, required this.maxValue, required this.icon, super.key,
    this.color,
    this.height = 20,
  });

  final String attributeName;
  final int currentValue;
  final int maxValue;
  final IconData icon;
  final Color? color;
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final progress = maxValue > 0 ? currentValue / maxValue : 0.0;
    final attributeColor = color ?? colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Attribute name and value
        Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: attributeColor,
            ),
            const SizedBox(width: 8),
            Text(
              attributeName,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const Spacer(),
            Text(
              '$currentValue / $maxValue',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),

        // Progress bar
        AnimatedProgressBar(
          progress: progress,
          height: height,
          progressColor: attributeColor,
          backgroundColor: attributeColor.withValues(alpha: 0.2),
        ),
      ],
    );
  }
}

/// Circular progress indicator with animation
class AnimatedCircularProgress extends StatefulWidget {
  const AnimatedCircularProgress({
    required this.progress, super.key,
    this.size = 100,
    this.strokeWidth = 8,
    this.backgroundColor,
    this.progressColor,
    this.gradient,
    this.animationDuration = const Duration(milliseconds: 1000),
    this.child,
  });

  final double progress; // 0.0 to 1.0
  final double size;
  final double strokeWidth;
  final Color? backgroundColor;
  final Color? progressColor;
  final Gradient? gradient;
  final Duration animationDuration;
  final Widget? child;

  @override
  State<AnimatedCircularProgress> createState() => _AnimatedCircularProgressState();
}

class _AnimatedCircularProgressState extends State<AnimatedCircularProgress>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _progressAnimation = Tween<double>(
      begin: 0,
      end: widget.progress,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _controller.forward();
  }

  @override
  void didUpdateWidget(AnimatedCircularProgress oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.progress != oldWidget.progress) {
      _progressAnimation = Tween<double>(
        begin: _progressAnimation.value,
        end: widget.progress,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ));

      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AnimatedBuilder(
      animation: _progressAnimation,
      builder: (context, child) => SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Background circle
              SizedBox(
                width: widget.size,
                height: widget.size,
                child: CircularProgressIndicator(
                  value: 1,
                  strokeWidth: widget.strokeWidth,
                  backgroundColor: widget.backgroundColor ??
                      colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation(
                    widget.backgroundColor ??
                        colorScheme.surfaceContainerHighest,
                  ),
                ),
              ),

              // Progress circle
              SizedBox(
                width: widget.size,
                height: widget.size,
                child: CircularProgressIndicator(
                  value: _progressAnimation.value,
                  strokeWidth: widget.strokeWidth,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation(
                    widget.progressColor ?? colorScheme.primary,
                  ),
                ),
              ),

              // Center content
              if (widget.child != null) widget.child!,
            ],
          ),
        ),
    );
  }
}