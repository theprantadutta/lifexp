import 'package:flutter/material.dart';

/// Widget that shows an animated XP gain indicator
class XPGainAnimation extends StatefulWidget {
  const XPGainAnimation({
    required this.xpAmount, required this.startPosition, super.key,
    this.onComplete,
    this.duration = const Duration(milliseconds: 2000),
  });

  final int xpAmount;
  final Offset startPosition;
  final VoidCallback? onComplete;
  final Duration duration;

  @override
  State<XPGainAnimation> createState() => _XPGainAnimationState();
}

class _XPGainAnimationState extends State<XPGainAnimation>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 1,
      end: 0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.7, 1, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -3),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 0.3, curve: Curves.elasticOut),
    ));

    _controller.forward().then((_) {
      widget.onComplete?.call();
    });
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

    return Positioned(
      left: widget.startPosition.dx,
      top: widget.startPosition.dy,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) => Transform.translate(
            offset: _slideAnimation.value * 50,
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Opacity(
                opacity: _fadeAnimation.value,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.stars,
                        color: colorScheme.onPrimary,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '+${widget.xpAmount} XP',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ),
    );
  }
}

/// Widget that manages multiple XP gain animations
class XPGainAnimationManager extends StatefulWidget {
  const XPGainAnimationManager({
    required this.child, super.key,
  });

  final Widget child;

  @override
  State<XPGainAnimationManager> createState() => _XPGainAnimationManagerState();

  /// Shows an XP gain animation at the specified position
  static void showXPGain(
    BuildContext context, {
    required int xpAmount,
    required Offset position,
  }) {
    final state = context.findAncestorStateOfType<_XPGainAnimationManagerState>();
    state?.showXPGain(xpAmount: xpAmount, position: position);
  }
}

class _XPGainAnimationManagerState extends State<XPGainAnimationManager> {
  final List<Widget> _activeAnimations = [];

  void showXPGain({
    required int xpAmount,
    required Offset position,
  }) {
    final key = UniqueKey();
    final animation = XPGainAnimation(
      key: key,
      xpAmount: xpAmount,
      startPosition: position,
      onComplete: () {
        setState(() {
          _activeAnimations.removeWhere((widget) => widget.key == key);
        });
      },
    );

    setState(() {
      _activeAnimations.add(animation);
    });
  }

  @override
  Widget build(BuildContext context) => Stack(
      children: [
        widget.child,
        ..._activeAnimations,
      ],
    );
}

/// Mixin to easily add XP gain animations to widgets
mixin XPGainAnimationMixin<T extends StatefulWidget> on State<T> {
  void showXPGain({
    required int xpAmount,
    Offset? position,
  }) {
    final renderBox = context.findRenderObject() as RenderBox?;
    final widgetPosition = renderBox?.localToGlobal(Offset.zero) ?? Offset.zero;
    final widgetSize = renderBox?.size ?? Size.zero;
    
    final animationPosition = position ?? 
        Offset(
          widgetPosition.dx + widgetSize.width / 2,
          widgetPosition.dy + widgetSize.height / 2,
        );

    XPGainAnimationManager.showXPGain(
      context,
      xpAmount: xpAmount,
      position: animationPosition,
    );
  }
}