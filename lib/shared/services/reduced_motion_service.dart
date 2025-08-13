import 'package:flutter/material.dart';

/// Service for managing reduced motion accessibility features
class ReducedMotionService {
  /// Check if reduce motion is enabled system-wide
  static bool isReduceMotionEnabled(BuildContext context) => MediaQuery.of(context).accessibilityFeatures.reduceMotion;
  
  /// Get animation duration based on reduce motion setting
  static Duration getAnimationDuration(
    BuildContext context,
    Duration normalDuration,
  ) {
    if (isReduceMotionEnabled(context)) {
      return Duration.zero; // No animation
    }
    return normalDuration;
  }
  
  /// Get reduced animation duration (shorter but not zero)
  static Duration getReducedAnimationDuration(
    BuildContext context,
    Duration normalDuration,
  ) {
    if (isReduceMotionEnabled(context)) {
      return Duration(milliseconds: (normalDuration.inMilliseconds * 0.2).round());
    }
    return normalDuration;
  }
  
  /// Get curve based on reduce motion setting
  static Curve getAnimationCurve(BuildContext context, Curve normalCurve) {
    if (isReduceMotionEnabled(context)) {
      return Curves.linear; // Simple linear curve
    }
    return normalCurve;
  }
  
  /// Create accessible animated container
  static Widget createAccessibleAnimatedContainer({
    required BuildContext context,
    required Widget child,
    required Duration duration,
    Curve curve = Curves.easeInOut,
    Color? color,
    Decoration? decoration,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    AlignmentGeometry? alignment,
    double? width,
    double? height,
  }) => AnimatedContainer(
      duration: getAnimationDuration(context, duration),
      curve: getAnimationCurve(context, curve),
      color: color,
      decoration: decoration,
      padding: padding,
      margin: margin,
      alignment: alignment,
      width: width,
      height: height,
      child: child,
    );
  
  /// Create accessible animated opacity
  static Widget createAccessibleAnimatedOpacity({
    required BuildContext context,
    required Widget child,
    required double opacity,
    required Duration duration,
    Curve curve = Curves.easeInOut,
  }) => AnimatedOpacity(
      opacity: opacity,
      duration: getAnimationDuration(context, duration),
      curve: getAnimationCurve(context, curve),
      child: child,
    );
  
  /// Create accessible animated positioned
  static Widget createAccessibleAnimatedPositioned({
    required BuildContext context,
    required Widget child,
    required Duration duration,
    Curve curve = Curves.easeInOut,
    double? left,
    double? top,
    double? right,
    double? bottom,
    double? width,
    double? height,
  }) => AnimatedPositioned(
      duration: getAnimationDuration(context, duration),
      curve: getAnimationCurve(context, curve),
      left: left,
      top: top,
      right: right,
      bottom: bottom,
      width: width,
      height: height,
      child: child,
    );
  
  /// Create accessible animated scale
  static Widget createAccessibleAnimatedScale({
    required BuildContext context,
    required Widget child,
    required double scale,
    required Duration duration,
    Curve curve = Curves.easeInOut,
    Alignment alignment = Alignment.center,
  }) => AnimatedScale(
      scale: scale,
      duration: getAnimationDuration(context, duration),
      curve: getAnimationCurve(context, curve),
      alignment: alignment,
      child: child,
    );
  
  /// Create accessible animated rotation
  static Widget createAccessibleAnimatedRotation({
    required BuildContext context,
    required Widget child,
    required double turns,
    required Duration duration,
    Curve curve = Curves.easeInOut,
    Alignment alignment = Alignment.center,
  }) => AnimatedRotation(
      turns: turns,
      duration: getAnimationDuration(context, duration),
      curve: getAnimationCurve(context, curve),
      alignment: alignment,
      child: child,
    );
  
  /// Create accessible slide transition
  static Widget createAccessibleSlideTransition({
    required BuildContext context,
    required Animation<Offset> position,
    required Widget child,
    TextDirection? textDirection,
  }) {
    if (isReduceMotionEnabled(context)) {
      // Return child without transition
      return child;
    }
    
    return SlideTransition(
      position: position,
      textDirection: textDirection,
      child: child,
    );
  }
  
  /// Create accessible fade transition
  static Widget createAccessibleFadeTransition({
    required BuildContext context,
    required Animation<double> opacity,
    required Widget child,
  }) {
    if (isReduceMotionEnabled(context)) {
      // Return child at full opacity
      return child;
    }
    
    return FadeTransition(
      opacity: opacity,
      child: child,
    );
  }
  
  /// Create accessible scale transition
  static Widget createAccessibleScaleTransition({
    required BuildContext context,
    required Animation<double> scale,
    required Widget child,
    Alignment alignment = Alignment.center,
  }) {
    if (isReduceMotionEnabled(context)) {
      // Return child without scaling
      return child;
    }
    
    return ScaleTransition(
      scale: scale,
      alignment: alignment,
      child: child,
    );
  }
  
  /// Create accessible rotation transition
  static Widget createAccessibleRotationTransition({
    required BuildContext context,
    required Animation<double> turns,
    required Widget child,
    Alignment alignment = Alignment.center,
  }) {
    if (isReduceMotionEnabled(context)) {
      // Return child without rotation
      return child;
    }
    
    return RotationTransition(
      turns: turns,
      alignment: alignment,
      child: child,
    );
  }
  
  /// Create accessible page route with reduced motion
  static PageRoute<T> createAccessiblePageRoute<T>({
    required BuildContext context,
    required Widget child,
    RouteSettings? settings,
    bool maintainState = true,
    bool fullscreenDialog = false,
  }) {
    if (isReduceMotionEnabled(context)) {
      // Use instant transition
      return PageRouteBuilder<T>(
        settings: settings,
        pageBuilder: (context, animation, secondaryAnimation) => child,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
        maintainState: maintainState,
        fullscreenDialog: fullscreenDialog,
      );
    }
    
    // Use standard material page route
    return MaterialPageRoute<T>(
      builder: (context) => child,
      settings: settings,
      maintainState: maintainState,
      fullscreenDialog: fullscreenDialog,
    );
  }
  
  /// Create accessible hero widget
  static Widget createAccessibleHero({
    required BuildContext context,
    required Object tag,
    required Widget child,
    Duration? flightDuration,
  }) => Hero(
      tag: tag,
      flightShuttleBuilder: isReduceMotionEnabled(context)
          ? (context, animation, direction, fromContext, toContext) {
              // Return the destination widget immediately
              return toContext.widget;
            }
          : null,
      child: child,
    );
  
  /// Create accessible list view with reduced scroll physics
  static Widget createAccessibleListView({
    required BuildContext context,
    required List<Widget> children,
    ScrollController? controller,
    Axis scrollDirection = Axis.vertical,
    bool reverse = false,
    bool? primary,
    ScrollPhysics? physics,
    bool shrinkWrap = false,
    EdgeInsetsGeometry? padding,
  }) {
    var accessiblePhysics = physics;
    
    if (isReduceMotionEnabled(context)) {
      // Use clamping scroll physics to reduce bouncing
      accessiblePhysics = const ClampingScrollPhysics();
    }
    
    return ListView(
      controller: controller,
      scrollDirection: scrollDirection,
      reverse: reverse,
      primary: primary,
      physics: accessiblePhysics,
      shrinkWrap: shrinkWrap,
      padding: padding,
      children: children,
    );
  }
  
  /// Create accessible grid view with reduced scroll physics
  static Widget createAccessibleGridView({
    required BuildContext context,
    required SliverGridDelegate gridDelegate,
    required List<Widget> children,
    ScrollController? controller,
    Axis scrollDirection = Axis.vertical,
    bool reverse = false,
    bool? primary,
    ScrollPhysics? physics,
    bool shrinkWrap = false,
    EdgeInsetsGeometry? padding,
  }) {
    var accessiblePhysics = physics;
    
    if (isReduceMotionEnabled(context)) {
      // Use clamping scroll physics to reduce bouncing
      accessiblePhysics = const ClampingScrollPhysics();
    }
    
    return GridView(
      gridDelegate: gridDelegate,
      controller: controller,
      scrollDirection: scrollDirection,
      reverse: reverse,
      primary: primary,
      physics: accessiblePhysics,
      shrinkWrap: shrinkWrap,
      padding: padding,
      children: children,
    );
  }
}

/// Widget that automatically adapts animations based on reduce motion setting
class AccessibleAnimatedWidget extends StatelessWidget {

  const AccessibleAnimatedWidget({
    required this.child, required this.duration, super.key,
    this.curve = Curves.easeInOut,
    this.onAnimationComplete,
  });
  final Widget child;
  final Duration duration;
  final Curve curve;
  final VoidCallback? onAnimationComplete;

  @override
  Widget build(BuildContext context) {
    if (ReducedMotionService.isReduceMotionEnabled(context)) {
      // Call completion callback immediately if no animation
      WidgetsBinding.instance.addPostFrameCallback((_) {
        onAnimationComplete?.call();
      });
      return child;
    }

    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: curve,
      switchOutCurve: curve,
      child: child,
    );
  }
}

/// Mixin for widgets that need reduced motion awareness
mixin ReducedMotionMixin<T extends StatefulWidget> on State<T> {
  /// Check if reduce motion is enabled
  bool get isReduceMotionEnabled => ReducedMotionService.isReduceMotionEnabled(context);
  
  /// Get animation duration with reduce motion consideration
  Duration getAnimationDuration(Duration normalDuration) => ReducedMotionService.getAnimationDuration(context, normalDuration);
  
  /// Get reduced animation duration
  Duration getReducedAnimationDuration(Duration normalDuration) => ReducedMotionService.getReducedAnimationDuration(context, normalDuration);
  
  /// Get animation curve with reduce motion consideration
  Curve getAnimationCurve(Curve normalCurve) => ReducedMotionService.getAnimationCurve(context, normalCurve);
}