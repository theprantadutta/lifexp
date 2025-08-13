import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Collection of micro-interactions and polish animations
class MicroInteractions {
  /// Animated button with scale and haptic feedback
  static Widget animatedButton({
    required Widget child,
    required VoidCallback onPressed,
    Duration duration = const Duration(milliseconds: 150),
    double scaleDown = 0.95,
    bool enableHaptic = true,
  }) => _AnimatedButton(
      onPressed: onPressed,
      duration: duration,
      scaleDown: scaleDown,
      enableHaptic: enableHaptic,
      child: child,
    );

  /// Animated card with hover and press effects
  static Widget animatedCard({
    required Widget child,
    VoidCallback? onTap,
    Duration duration = const Duration(milliseconds: 200),
    double elevation = 2,
    double hoverElevation = 4,
    double pressElevation = 1,
    BorderRadius? borderRadius,
  }) => _AnimatedCard(
      onTap: onTap,
      duration: duration,
      elevation: elevation,
      hoverElevation: hoverElevation,
      pressElevation: pressElevation,
      borderRadius: borderRadius,
      child: child,
    );

  /// Animated icon with rotation or scale effects
  static Widget animatedIcon({
    required IconData icon,
    required bool isActive,
    Duration duration = const Duration(milliseconds: 300),
    double size = 24,
    Color? color,
    Color? activeColor,
    AnimationType animationType = AnimationType.scale,
  }) => _AnimatedIcon(
      icon: icon,
      isActive: isActive,
      duration: duration,
      size: size,
      color: color,
      activeColor: activeColor,
      animationType: animationType,
    );

  /// Ripple effect widget
  static Widget rippleEffect({
    required Widget child,
    VoidCallback? onTap,
    Color? rippleColor,
    BorderRadius? borderRadius,
  }) => Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: rippleColor?.withValues(alpha: 0.3),
        highlightColor: rippleColor?.withValues(alpha: 0.1),
        borderRadius: borderRadius,
        child: child,
      ),
    );

  /// Floating action button with custom animations
  static Widget floatingButton({
    required VoidCallback onPressed,
    required Widget child,
    Color? backgroundColor,
    Color? foregroundColor,
    double elevation = 6,
    bool mini = false,
    String? heroTag,
  }) => _FloatingButton(
      onPressed: onPressed,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      elevation: elevation,
      mini: mini,
      heroTag: heroTag,
      child: child,
    );
}

/// Animated button implementation
class _AnimatedButton extends StatefulWidget {

  const _AnimatedButton({
    required this.child,
    required this.onPressed,
    required this.duration,
    required this.scaleDown,
    required this.enableHaptic,
  });
  final Widget child;
  final VoidCallback onPressed;
  final Duration duration;
  final double scaleDown;
  final bool enableHaptic;

  @override
  State<_AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<_AnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1,
      end: widget.scaleDown,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
      onTapDown: (_) {
        _controller.forward();
        if (widget.enableHaptic) {
          HapticFeedback.lightImpact();
        }
      },
      onTapUp: (_) {
        _controller.reverse();
        widget.onPressed();
      },
      onTapCancel: () {
        _controller.reverse();
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
            scale: _scaleAnimation.value,
            child: widget.child,
          ),
      ),
    );
}

/// Animated card implementation
class _AnimatedCard extends StatefulWidget {

  const _AnimatedCard({
    required this.child,
    required this.duration, required this.elevation, required this.hoverElevation, required this.pressElevation, this.onTap,
    this.borderRadius,
  });
  final Widget child;
  final VoidCallback? onTap;
  final Duration duration;
  final double elevation;
  final double hoverElevation;
  final double pressElevation;
  final BorderRadius? borderRadius;

  @override
  State<_AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<_AnimatedCard> {
  bool _isHovered = false;
  bool _isPressed = false;

  double get _currentElevation {
    if (_isPressed) return widget.pressElevation;
    if (_isHovered) return widget.hoverElevation;
    return widget.elevation;
  }

  @override
  Widget build(BuildContext context) => MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          widget.onTap?.call();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedContainer(
          duration: widget.duration,
          curve: Curves.easeInOut,
          child: Card(
            elevation: _currentElevation,
            shape: RoundedRectangleBorder(
              borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
            ),
            child: widget.child,
          ),
        ),
      ),
    );
}

/// Animation types for animated icons
enum AnimationType {
  scale,
  rotation,
  fade,
  bounce,
}

/// Animated icon implementation
class _AnimatedIcon extends StatefulWidget {

  const _AnimatedIcon({
    required this.icon,
    required this.isActive,
    required this.duration,
    required this.size,
    required this.animationType, this.color,
    this.activeColor,
  });
  final IconData icon;
  final bool isActive;
  final Duration duration;
  final double size;
  final Color? color;
  final Color? activeColor;
  final AnimationType animationType;

  @override
  State<_AnimatedIcon> createState() => _AnimatedIconState();
}

class _AnimatedIconState extends State<_AnimatedIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    switch (widget.animationType) {
      case AnimationType.scale:
        _animation = Tween<double>(begin: 1, end: 1.2).animate(
          CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
        );
        break;
      case AnimationType.rotation:
        _animation = Tween<double>(begin: 0, end: 1).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
        );
        break;
      case AnimationType.fade:
        _animation = Tween<double>(begin: 0.5, end: 1).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
        );
        break;
      case AnimationType.bounce:
        _animation = Tween<double>(begin: 1, end: 1.3).animate(
          CurvedAnimation(parent: _controller, curve: Curves.bounceOut),
        );
        break;
    }

    if (widget.isActive) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(_AnimatedIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
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
    final iconColor = widget.isActive
        ? (widget.activeColor ?? theme.colorScheme.primary)
        : (widget.color ?? theme.colorScheme.onSurface.withValues(alpha: 0.6));

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final Widget iconWidget = Icon(
          widget.icon,
          size: widget.size,
          color: iconColor,
        );

        switch (widget.animationType) {
          case AnimationType.scale:
          case AnimationType.bounce:
            return Transform.scale(
              scale: _animation.value,
              child: iconWidget,
            );
          case AnimationType.rotation:
            return Transform.rotate(
              angle: _animation.value * 2 * 3.14159,
              child: iconWidget,
            );
          case AnimationType.fade:
            return Opacity(
              opacity: _animation.value,
              child: iconWidget,
            );
        }
      },
    );
  }
}

/// Floating button implementation
class _FloatingButton extends StatefulWidget {

  const _FloatingButton({
    required this.onPressed,
    required this.child,
    required this.elevation, required this.mini, this.backgroundColor,
    this.foregroundColor,
    this.heroTag,
  });
  final VoidCallback onPressed;
  final Widget child;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double elevation;
  final bool mini;
  final String? heroTag;

  @override
  State<_FloatingButton> createState() => _FloatingButtonState();
}

class _FloatingButtonState extends State<_FloatingButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1,
      end: 0.9,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 0.1,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
      onTapDown: (_) {
        _controller.forward();
        HapticFeedback.mediumImpact();
      },
      onTapUp: (_) {
        _controller.reverse();
        widget.onPressed();
      },
      onTapCancel: () {
        _controller.reverse();
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) => Transform.scale(
            scale: _scaleAnimation.value,
            child: Transform.rotate(
              angle: _rotationAnimation.value,
              child: FloatingActionButton(
                onPressed: null, // Handled by GestureDetector
                backgroundColor: widget.backgroundColor,
                foregroundColor: widget.foregroundColor,
                elevation: widget.elevation,
                mini: widget.mini,
                heroTag: widget.heroTag,
                child: widget.child,
              ),
            ),
          ),
      ),
    );
}

/// Staggered animation for lists
class StaggeredAnimation extends StatefulWidget {

  const StaggeredAnimation({
    required this.children, super.key,
    this.delay = const Duration(milliseconds: 100),
    this.duration = const Duration(milliseconds: 300),
    this.direction = Axis.vertical,
  });
  final List<Widget> children;
  final Duration delay;
  final Duration duration;
  final Axis direction;

  @override
  State<StaggeredAnimation> createState() => _StaggeredAnimationState();
}

class _StaggeredAnimationState extends State<StaggeredAnimation>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<Offset>> _slideAnimations;
  late List<Animation<double>> _fadeAnimations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      widget.children.length,
      (index) => AnimationController(
        duration: widget.duration,
        vsync: this,
      ),
    );

    _slideAnimations = _controllers.map((controller) => Tween<Offset>(
        begin: widget.direction == Axis.vertical
            ? const Offset(0, 0.5)
            : const Offset(0.5, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.easeOut,
      ))).toList();

    _fadeAnimations = _controllers.map((controller) => Tween<double>(
        begin: 0,
        end: 1,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.easeOut,
      ))).toList();

    _startAnimations();
  }

  void _startAnimations() {
    for (var i = 0; i < _controllers.length; i++) {
      Future.delayed(widget.delay * i, () {
        if (mounted) {
          _controllers[i].forward();
        }
      });
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
      children: List.generate(widget.children.length, (index) => AnimatedBuilder(
          animation: _controllers[index],
          builder: (context, child) => SlideTransition(
              position: _slideAnimations[index],
              child: FadeTransition(
                opacity: _fadeAnimations[index],
                child: widget.children[index],
              ),
            ),
        )),
    );
}

/// Pulse animation widget
class PulseAnimation extends StatefulWidget {

  const PulseAnimation({
    required this.child, super.key,
    this.duration = const Duration(milliseconds: 1000),
    this.minScale = 0.95,
    this.maxScale = 1.05,
  });
  final Widget child;
  final Duration duration;
  final double minScale;
  final double maxScale;

  @override
  State<PulseAnimation> createState() => _PulseAnimationState();
}

class _PulseAnimationState extends State<PulseAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _animation = Tween<double>(
      begin: widget.minScale,
      end: widget.maxScale,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: _animation,
      builder: (context, child) => Transform.scale(
          scale: _animation.value,
          child: widget.child,
        ),
    );
}

/// Shake animation widget
class ShakeAnimation extends StatefulWidget {

  const ShakeAnimation({
    required this.child, super.key,
    this.duration = const Duration(milliseconds: 500),
    this.offset = 10.0,
  });
  final Widget child;
  final Duration duration;
  final double offset;

  @override
  State<ShakeAnimation> createState() => _ShakeAnimationState();
}

class _ShakeAnimationState extends State<ShakeAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _animation = Tween<double>(
      begin: -widget.offset,
      end: widget.offset,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticIn,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void shake() {
    _controller.forward().then((_) {
      _controller.reverse();
    });
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: _animation,
      builder: (context, child) => Transform.translate(
          offset: Offset(_animation.value, 0),
          child: widget.child,
        ),
    );
}