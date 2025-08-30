import 'package:flutter/material.dart';

/// Custom page route with slide transition
class SlidePageRoute<T> extends PageRouteBuilder<T> {
  SlidePageRoute({
    required this.child,
    this.direction = SlideDirection.rightToLeft,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeInOut,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => child,
          transitionDuration: duration,
          reverseTransitionDuration: duration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            Offset begin;
            const end = Offset.zero;

            switch (direction) {
              case SlideDirection.rightToLeft:
                begin = const Offset(1, 0);
                break;
              case SlideDirection.leftToRight:
                begin = const Offset(-1, 0);
                break;
              case SlideDirection.topToBottom:
                begin = const Offset(0, -1);
                break;
              case SlideDirection.bottomToTop:
                begin = const Offset(0, 1);
                break;
            }

            final tween = Tween(begin: begin, end: end);
            final offsetAnimation = animation.drive(
              tween.chain(CurveTween(curve: curve)),
            );

            return SlideTransition(
              position: offsetAnimation,
              child: child,
            );
          },
        );

  final Widget child;
  final SlideDirection direction;
  final Duration duration;
  final Curve curve;
}

/// Fade page route transition
class FadePageRoute<T> extends PageRouteBuilder<T> {
  FadePageRoute({
    required this.child,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeInOut,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => child,
          transitionDuration: duration,
          reverseTransitionDuration: duration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) => FadeTransition(
              opacity: animation.drive(
                CurveTween(curve: curve),
              ),
              child: child,
            ),
        );

  final Widget child;
  final Duration duration;
  final Curve curve;
}

/// Scale page route transition
class ScalePageRoute<T> extends PageRouteBuilder<T> {
  ScalePageRoute({
    required this.child,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeInOut,
    this.alignment = Alignment.center,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => child,
          transitionDuration: duration,
          reverseTransitionDuration: duration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) => ScaleTransition(
              scale: animation.drive(
                Tween(begin: 0.0, end: 1.0).chain(
                  CurveTween(curve: curve),
                ),
              ),
              alignment: alignment,
              child: child,
            ),
        );

  final Widget child;
  final Duration duration;
  final Curve curve;
  final Alignment alignment;
}

/// Hero page route with custom transitions
class HeroPageRoute<T> extends PageRouteBuilder<T> {
  HeroPageRoute({
    required this.child,
    this.duration = const Duration(milliseconds: 400),
    this.curve = Curves.easeInOut,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => child,
          transitionDuration: duration,
          reverseTransitionDuration: duration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) => FadeTransition(
              opacity: animation.drive(
                CurveTween(curve: curve),
              ),
              child: SlideTransition(
                position: animation.drive(
                  Tween(
                    begin: const Offset(0, 0.1),
                    end: Offset.zero,
                  ).chain(CurveTween(curve: curve)),
                ),
                child: child,
              ),
            ),
        );

  final Widget child;
  final Duration duration;
  final Curve curve;
}

/// Slide direction enum
enum SlideDirection {
  rightToLeft,
  leftToRight,
  topToBottom,
  bottomToTop,
}

/// Navigation helper with custom transitions
class AppNavigator {
  /// Navigate with slide transition
  static Future<T?> slideToPage<T>(
    BuildContext context,
    Widget page, {
    SlideDirection direction = SlideDirection.rightToLeft,
    Duration duration = const Duration(milliseconds: 300),
    bool replace = false,
  }) {
    final route = SlidePageRoute<T>(
      child: page,
      direction: direction,
      duration: duration,
    );

    if (replace) {
      return Navigator.of(context).pushReplacement(route);
    } else {
      return Navigator.of(context).push(route);
    }
  }

  /// Navigate with fade transition
  static Future<T?> fadeToPage<T>(
    BuildContext context,
    Widget page, {
    Duration duration = const Duration(milliseconds: 300),
    bool replace = false,
  }) {
    final route = FadePageRoute<T>(
      child: page,
      duration: duration,
    );

    if (replace) {
      return Navigator.of(context).pushReplacement(route);
    } else {
      return Navigator.of(context).push(route);
    }
  }

  /// Navigate with scale transition
  static Future<T?> scaleToPage<T>(
    BuildContext context,
    Widget page, {
    Duration duration = const Duration(milliseconds: 300),
    Alignment alignment = Alignment.center,
    bool replace = false,
  }) {
    final route = ScalePageRoute<T>(
      child: page,
      duration: duration,
      alignment: alignment,
    );

    if (replace) {
      return Navigator.of(context).pushReplacement(route);
    } else {
      return Navigator.of(context).push(route);
    }
  }

  /// Navigate with hero transition
  static Future<T?> heroToPage<T>(
    BuildContext context,
    Widget page, {
    Duration duration = const Duration(milliseconds: 400),
    bool replace = false,
  }) {
    final route = HeroPageRoute<T>(
      child: page,
      duration: duration,
    );

    if (replace) {
      return Navigator.of(context).pushReplacement(route);
    } else {
      return Navigator.of(context).push(route);
    }
  }
}

/// Animated container that smoothly transitions between states
class AnimatedStateContainer extends StatefulWidget {
  const AnimatedStateContainer({
    required this.child, super.key,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeInOut,
    this.alignment = Alignment.center,
  });

  final Widget child;
  final Duration duration;
  final Curve curve;
  final Alignment alignment;

  @override
  State<AnimatedStateContainer> createState() => _AnimatedStateContainerState();
}

class _AnimatedStateContainerState extends State<AnimatedStateContainer>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  Widget? _currentChild;
  Widget? _previousChild;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));

    _currentChild = widget.child;
    _controller.forward();
  }

  @override
  void didUpdateWidget(AnimatedStateContainer oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.child != oldWidget.child) {
      _previousChild = _currentChild;
      _currentChild = widget.child;

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
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Stack(
          alignment: widget.alignment,
          children: [
            // Previous child fading out
            if (_previousChild != null)
              Opacity(
                opacity: 1.0 - _fadeAnimation.value,
                child: _previousChild,
              ),

            // Current child fading in
            FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: _currentChild,
              ),
            ),
          ],
        ),
    );
}

/// Loading transition widget
class LoadingTransition extends StatefulWidget {
  const LoadingTransition({
    required this.isLoading, required this.child, super.key,
    this.loadingWidget,
    this.duration = const Duration(milliseconds: 300),
  });

  final bool isLoading;
  final Widget child;
  final Widget? loadingWidget;
  final Duration duration;

  @override
  State<LoadingTransition> createState() => _LoadingTransitionState();
}

class _LoadingTransitionState extends State<LoadingTransition>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    if (!widget.isLoading) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(LoadingTransition oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isLoading != oldWidget.isLoading) {
      if (widget.isLoading) {
        _controller.reverse();
      } else {
        _controller.forward();
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
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) => Stack(
          children: [
            // Loading widget
            if (widget.isLoading)
              widget.loadingWidget ??
                  const Center(
                    child: CircularProgressIndicator(),
                  ),

            // Content
            Opacity(
              opacity: _fadeAnimation.value,
              child: widget.child,
            ),
          ],
        ),
    );
  }
}

/// Staggered animation for lists
class StaggeredListAnimation extends StatelessWidget {
  const StaggeredListAnimation({
    required this.children, super.key,
    this.staggerDelay = const Duration(milliseconds: 100),
    this.animationDuration = const Duration(milliseconds: 300),
    this.curve = Curves.easeOut,
  });

  final List<Widget> children;
  final Duration staggerDelay;
  final Duration animationDuration;
  final Curve curve;

  @override
  Widget build(BuildContext context) => Column(
      children: children.asMap().entries.map((entry) {
        final index = entry.key;
        final child = entry.value;

        return TweenAnimationBuilder<double>(
          duration: animationDuration + (staggerDelay * index),
          tween: Tween(begin: 0, end: 1),
          curve: curve,
          builder: (context, value, child) => Transform.translate(
              offset: Offset(0, 20 * (1 - value)),
              child: Opacity(
                opacity: value,
                child: child,
              ),
            ),
          child: child,
        );
      }).toList(),
    );
}