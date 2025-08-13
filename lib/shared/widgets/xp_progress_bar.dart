import 'package:flutter/material.dart';
import '../themes/theme_extensions.dart';

/// A customizable XP progress bar with smooth animations
class XPProgressBar extends StatefulWidget {

  const XPProgressBar({
    required this.currentXP, required this.maxXP, super.key,
    this.height = 24,
    this.borderRadius = 12,
    this.showText = true,
    this.label,
    this.animationDuration = const Duration(milliseconds: 800),
    this.showGlow = true,
  });
  final int currentXP;
  final int maxXP;
  final double height;
  final double borderRadius;
  final bool showText;
  final String? label;
  final Duration animationDuration;
  final bool showGlow;

  @override
  State<XPProgressBar> createState() => _XPProgressBarState();
}

class _XPProgressBarState extends State<XPProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _progressAnimation =
        Tween<double>(begin: 0, end: widget.currentXP / widget.maxXP).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _glowAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.forward();
  }

  @override
  void didUpdateWidget(XPProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentXP != widget.currentXP ||
        oldWidget.maxXP != widget.maxXP) {
      _progressAnimation =
          Tween<double>(
            begin: _progressAnimation.value,
            end: widget.currentXP / widget.maxXP,
          ).animate(
            CurvedAnimation(
              parent: _animationController,
              curve: Curves.easeOutCubic,
            ),
          );
      _animationController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
        ],
        AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) => Container(
              height: widget.height,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(widget.borderRadius),
                boxShadow: widget.showGlow
                    ? [
                        BoxShadow(
                          color: context.xpPrimary.withValues(
                            alpha: 0.3 * _glowAnimation.value,
                          ),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(widget.borderRadius),
                child: Stack(
                  children: [
                    // Background
                    Container(
                      width: double.infinity,
                      height: widget.height,
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(
                          widget.borderRadius,
                        ),
                      ),
                    ),
                    // Progress fill
                    FractionallySizedBox(
                      widthFactor: _progressAnimation.value.clamp(0.0, 1.0),
                      child: Container(
                        height: widget.height,
                        decoration: BoxDecoration(
                          gradient: context.xpGradient,
                          borderRadius: BorderRadius.circular(
                            widget.borderRadius,
                          ),
                        ),
                      ),
                    ),
                    // Shimmer effect
                    if (_progressAnimation.value > 0)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                              widget.borderRadius,
                            ),
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                Colors.white.withValues(alpha: 0.2),
                                Colors.transparent,
                              ],
                              stops: const [0.0, 0.5, 1.0],
                            ),
                          ),
                        ),
                      ),
                    // Text overlay
                    if (widget.showText)
                      Positioned.fill(
                        child: Center(
                          child: Text(
                            '${widget.currentXP} / ${widget.maxXP} XP',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: _progressAnimation.value > 0.5
                                      ? Colors.white
                                      : Theme.of(context).colorScheme.onSurface,
                                  fontWeight: FontWeight.w600,
                                  shadows: _progressAnimation.value > 0.5
                                      ? [
                                          const Shadow(
                                            color: Colors.black26,
                                            offset: Offset(0, 1),
                                            blurRadius: 2,
                                          ),
                                        ]
                                      : null,
                                ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ),
      ],
    );
}

/// A simplified XP progress bar for smaller spaces
class CompactXPProgressBar extends StatelessWidget {

  const CompactXPProgressBar({
    required this.currentXP, required this.maxXP, super.key,
    this.height = 8,
    this.width = 100,
  });
  final int currentXP;
  final int maxXP;
  final double height;
  final double width;

  @override
  Widget build(BuildContext context) {
    final progress = currentXP / maxXP;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(height / 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(height / 2),
        child: FractionallySizedBox(
          widthFactor: progress.clamp(0.0, 1.0),
          alignment: Alignment.centerLeft,
          child: Container(
            decoration: BoxDecoration(
              gradient: context.xpGradient,
              borderRadius: BorderRadius.circular(height / 2),
            ),
          ),
        ),
      ),
    );
  }
}
