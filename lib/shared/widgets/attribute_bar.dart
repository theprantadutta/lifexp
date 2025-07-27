import 'package:flutter/material.dart';
import '../themes/theme_extensions.dart';

/// A widget for displaying character attributes with gradient fills
class AttributeBar extends StatefulWidget {
  final String attributeName;
  final int currentValue;
  final int maxValue;
  final IconData icon;
  final Color? color;
  final double height;
  final bool showText;
  final bool showIcon;
  final Duration animationDuration;

  const AttributeBar({
    super.key,
    required this.attributeName,
    required this.currentValue,
    required this.maxValue,
    required this.icon,
    this.color,
    this.height = 32,
    this.showText = true,
    this.showIcon = true,
    this.animationDuration = const Duration(milliseconds: 1000),
  });

  @override
  State<AttributeBar> createState() => _AttributeBarState();
}

class _AttributeBarState extends State<AttributeBar>
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
        Tween<double>(
          begin: 0.0,
          end: widget.currentValue / widget.maxValue,
        ).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.forward();
  }

  @override
  void didUpdateWidget(AttributeBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentValue != widget.currentValue ||
        oldWidget.maxValue != widget.maxValue) {
      _progressAnimation =
          Tween<double>(
            begin: _progressAnimation.value,
            end: widget.currentValue / widget.maxValue,
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

  Color _getAttributeColor(BuildContext context) {
    if (widget.color != null) return widget.color!;

    switch (widget.attributeName.toLowerCase()) {
      case 'strength':
        return const Color(0xFFEF4444); // Red
      case 'wisdom':
        return const Color(0xFF8B5CF6); // Purple
      case 'intelligence':
        return const Color(0xFF3B82F6); // Blue
      default:
        return context.xpPrimary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final attributeColor = _getAttributeColor(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header with icon and name
        Row(
          children: [
            if (widget.showIcon) ...[
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: attributeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(widget.icon, size: 16, color: attributeColor),
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                widget.attributeName,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: attributeColor,
                ),
              ),
            ),
            if (widget.showText)
              Text(
                '${widget.currentValue}/${widget.maxValue}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        // Progress bar
        AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Container(
              height: widget.height,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(widget.height / 2),
                boxShadow: [
                  BoxShadow(
                    color: attributeColor.withValues(
                      alpha: 0.2 * _glowAnimation.value,
                    ),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(widget.height / 2),
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
                        borderRadius: BorderRadius.circular(widget.height / 2),
                      ),
                    ),
                    // Progress fill with gradient
                    FractionallySizedBox(
                      widthFactor: _progressAnimation.value.clamp(0.0, 1.0),
                      child: Container(
                        height: widget.height,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              attributeColor,
                              attributeColor.withValues(alpha: 0.8),
                              attributeColor,
                            ],
                            stops: const [0.0, 0.5, 1.0],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(
                            widget.height / 2,
                          ),
                        ),
                      ),
                    ),
                    // Animated shine effect
                    if (_progressAnimation.value > 0)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                              widget.height / 2,
                            ),
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                Colors.white.withValues(alpha: 0.3),
                                Colors.transparent,
                              ],
                              stops: const [0.0, 0.5, 1.0],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                          ),
                        ),
                      ),
                    // Milestone markers
                    if (widget.maxValue >= 10)
                      ...List.generate((widget.maxValue / 10).floor(), (index) {
                        final position = (index + 1) * 10 / widget.maxValue;
                        return Positioned(
                          left:
                              position *
                              MediaQuery.of(context).size.width *
                              0.8,
                          top: 0,
                          bottom: 0,
                          child: Container(
                            width: 1,
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                        );
                      }),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

/// A compact attribute display for smaller spaces
class CompactAttributeBar extends StatelessWidget {
  final String attributeName;
  final int currentValue;
  final int maxValue;
  final IconData icon;
  final Color? color;

  const CompactAttributeBar({
    super.key,
    required this.attributeName,
    required this.currentValue,
    required this.maxValue,
    required this.icon,
    this.color,
  });

  Color _getAttributeColor(BuildContext context) {
    if (color != null) return color!;

    switch (attributeName.toLowerCase()) {
      case 'strength':
        return const Color(0xFFEF4444); // Red
      case 'wisdom':
        return const Color(0xFF8B5CF6); // Purple
      case 'intelligence':
        return const Color(0xFF3B82F6); // Blue
      default:
        return context.xpPrimary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final attributeColor = _getAttributeColor(context);
    final progress = currentValue / maxValue;

    return Row(
      children: [
        Icon(icon, size: 16, color: attributeColor),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    attributeName,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: attributeColor,
                    ),
                  ),
                  Text(
                    '$currentValue/$maxValue',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Container(
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: FractionallySizedBox(
                    widthFactor: progress.clamp(0.0, 1.0),
                    alignment: Alignment.centerLeft,
                    child: Container(
                      decoration: BoxDecoration(
                        color: attributeColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A circular attribute display
class CircularAttributeBar extends StatefulWidget {
  final String attributeName;
  final int currentValue;
  final int maxValue;
  final IconData icon;
  final Color? color;
  final double size;

  const CircularAttributeBar({
    super.key,
    required this.attributeName,
    required this.currentValue,
    required this.maxValue,
    required this.icon,
    this.color,
    this.size = 80,
  });

  @override
  State<CircularAttributeBar> createState() => _CircularAttributeBarState();
}

class _CircularAttributeBarState extends State<CircularAttributeBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _progressAnimation =
        Tween<double>(
          begin: 0.0,
          end: widget.currentValue / widget.maxValue,
        ).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController.forward();
  }

  @override
  void didUpdateWidget(CircularAttributeBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentValue != widget.currentValue ||
        oldWidget.maxValue != widget.maxValue) {
      _progressAnimation =
          Tween<double>(
            begin: _progressAnimation.value,
            end: widget.currentValue / widget.maxValue,
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

  Color _getAttributeColor(BuildContext context) {
    if (widget.color != null) return widget.color!;

    switch (widget.attributeName.toLowerCase()) {
      case 'strength':
        return const Color(0xFFEF4444); // Red
      case 'wisdom':
        return const Color(0xFF8B5CF6); // Purple
      case 'intelligence':
        return const Color(0xFF3B82F6); // Blue
      default:
        return context.xpPrimary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final attributeColor = _getAttributeColor(context);

    return Column(
      children: [
        SizedBox(
          width: widget.size,
          height: widget.size,
          child: AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  // Background circle
                  SizedBox(
                    width: widget.size,
                    height: widget.size,
                    child: CircularProgressIndicator(
                      value: 1.0,
                      strokeWidth: 6,
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                      ),
                    ),
                  ),
                  // Progress circle
                  SizedBox(
                    width: widget.size,
                    height: widget.size,
                    child: CircularProgressIndicator(
                      value: _progressAnimation.value,
                      strokeWidth: 6,
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation<Color>(attributeColor),
                    ),
                  ),
                  // Icon and value
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        widget.icon,
                        size: widget.size * 0.25,
                        color: attributeColor,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${widget.currentValue}',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: attributeColor,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.attributeName,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: attributeColor,
          ),
        ),
      ],
    );
  }
}
