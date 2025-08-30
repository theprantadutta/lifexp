import 'package:flutter/material.dart';

/// Service for managing UI density and spacing for accessibility
class UIDensityService {
  /// UI density levels
  static const VisualDensity compactDensity = VisualDensity(horizontal: -2, vertical: -2);
  static const VisualDensity standardDensity = VisualDensity.standard;
  static const VisualDensity comfortableDensity = VisualDensity(horizontal: 1, vertical: 1);
  static const VisualDensity spaciousDensity = VisualDensity(horizontal: 2, vertical: 2);
  
  /// Get appropriate density based on accessibility needs
  static VisualDensity getAccessibilityDensity(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    
    // Use comfortable density for large text
    if (mediaQuery.textScaler.scale(1) > 1.3) {
      return comfortableDensity;
    }
    
    // Use spacious density for extra large text
    if (mediaQuery.textScaler.scale(1) > 2.0) {
      return spaciousDensity;
    }
    
    return standardDensity;
  }
  
  /// Get spacing multiplier based on density
  static double getSpacingMultiplier(VisualDensity density) {
    final densityValue = (density.horizontal + density.vertical) / 2;
    
    if (densityValue <= -2) return 0.75; // Compact
    if (densityValue <= -1) return 0.85; // Semi-compact
    if (densityValue >= 2) return 1.5;   // Spacious
    if (densityValue >= 1) return 1.25;  // Comfortable
    
    return 1; // Standard
  }
  
  /// Get responsive spacing based on density
  static double getResponsiveSpacing(
    BuildContext context,
    double baseSpacing, {
    VisualDensity? customDensity,
  }) {
    final density = customDensity ?? Theme.of(context).visualDensity;
    final multiplier = getSpacingMultiplier(density);
    return baseSpacing * multiplier;
  }
  
  /// Get responsive padding based on density
  static EdgeInsets getResponsivePadding(
    BuildContext context,
    EdgeInsets basePadding, {
    VisualDensity? customDensity,
  }) {
    final density = customDensity ?? Theme.of(context).visualDensity;
    final multiplier = getSpacingMultiplier(density);
    
    return EdgeInsets.fromLTRB(
      basePadding.left * multiplier,
      basePadding.top * multiplier,
      basePadding.right * multiplier,
      basePadding.bottom * multiplier,
    );
  }
  
  /// Get responsive margin based on density
  static EdgeInsets getResponsiveMargin(
    BuildContext context,
    EdgeInsets baseMargin, {
    VisualDensity? customDensity,
  }) => getResponsivePadding(context, baseMargin, customDensity: customDensity);
  
  /// Get responsive button size based on density
  static Size getResponsiveButtonSize(
    BuildContext context,
    Size baseSize, {
    VisualDensity? customDensity,
  }) {
    final density = customDensity ?? Theme.of(context).visualDensity;
    final multiplier = getSpacingMultiplier(density);
    
    return Size(
      baseSize.width * multiplier,
      baseSize.height * multiplier,
    );
  }
  
  /// Get responsive icon size based on density
  static double getResponsiveIconSize(
    BuildContext context,
    double baseIconSize, {
    VisualDensity? customDensity,
  }) {
    final density = customDensity ?? Theme.of(context).visualDensity;
    final multiplier = getSpacingMultiplier(density);
    return baseIconSize * multiplier;
  }
  
  /// Create theme with responsive density
  static ThemeData createDensityAwareTheme(
    BuildContext context,
    ThemeData baseTheme, {
    VisualDensity? customDensity,
  }) {
    final density = customDensity ?? getAccessibilityDensity(context);
    final spacingMultiplier = getSpacingMultiplier(density);
    
    return baseTheme.copyWith(
      visualDensity: density,
      
      // Responsive button themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: baseTheme.elevatedButtonTheme.style?.copyWith(
          padding: WidgetStateProperty.all(
            getResponsivePadding(
              context,
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              customDensity: density,
            ),
          ),
          minimumSize: WidgetStateProperty.all(
            getResponsiveButtonSize(
              context,
              const Size(64, 40),
              customDensity: density,
            ),
          ),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: baseTheme.outlinedButtonTheme.style?.copyWith(
          padding: WidgetStateProperty.all(
            getResponsivePadding(
              context,
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              customDensity: density,
            ),
          ),
          minimumSize: WidgetStateProperty.all(
            getResponsiveButtonSize(
              context,
              const Size(64, 40),
              customDensity: density,
            ),
          ),
        ),
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: baseTheme.textButtonTheme.style?.copyWith(
          padding: WidgetStateProperty.all(
            getResponsivePadding(
              context,
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              customDensity: density,
            ),
          ),
          minimumSize: WidgetStateProperty.all(
            getResponsiveButtonSize(
              context,
              const Size(64, 40),
              customDensity: density,
            ),
          ),
        ),
      ),
      
      // Responsive input decoration theme
      inputDecorationTheme: baseTheme.inputDecorationTheme.copyWith(
        contentPadding: getResponsivePadding(
          context,
          const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          customDensity: density,
        ),
        isDense: density == compactDensity,
      ),
      
      // Responsive list tile theme
      listTileTheme: baseTheme.listTileTheme.copyWith(
        contentPadding: getResponsivePadding(
          context,
          const EdgeInsets.symmetric(horizontal: 16),
          customDensity: density,
        ),
        minVerticalPadding: getResponsiveSpacing(context, 4, customDensity: density),
        dense: density == compactDensity,
      ),
      
      // Responsive card theme
      cardTheme: baseTheme.cardTheme.copyWith(
        margin: getResponsiveMargin(
          context,
          const EdgeInsets.all(4),
          customDensity: density,
        ),
      ),
      
      // Responsive chip theme
      chipTheme: baseTheme.chipTheme.copyWith(
        padding: getResponsivePadding(
          context,
          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          customDensity: density,
        ),
        labelPadding: getResponsivePadding(
          context,
          const EdgeInsets.symmetric(horizontal: 4),
          customDensity: density,
        ),
      ),
      
      // Responsive app bar theme
      appBarTheme: baseTheme.appBarTheme.copyWith(
        toolbarHeight: kToolbarHeight * spacingMultiplier,
        titleSpacing: 16 * spacingMultiplier,
      ),
      
      // Responsive tab bar theme
      tabBarTheme: baseTheme.tabBarTheme.copyWith(
        labelPadding: getResponsivePadding(
          context,
          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          customDensity: density,
        ),
      ),
      
      // Responsive bottom navigation bar theme
      bottomNavigationBarTheme: baseTheme.bottomNavigationBarTheme.copyWith(
        type: density == compactDensity 
            ? BottomNavigationBarType.fixed 
            : BottomNavigationBarType.fixed,
      ),
    );
  }
}

/// Widget that provides responsive spacing based on UI density
class DensityAwareSpacing extends StatelessWidget {

  const DensityAwareSpacing({
    required this.spacing, super.key,
    this.direction = Axis.vertical,
    this.customDensity,
  });

  const DensityAwareSpacing.vertical(
    this.spacing, {
    super.key,
    this.customDensity,
  }) : direction = Axis.vertical;

  const DensityAwareSpacing.horizontal(
    this.spacing, {
    super.key,
    this.customDensity,
  }) : direction = Axis.horizontal;
  final double spacing;
  final Axis direction;
  final VisualDensity? customDensity;

  @override
  Widget build(BuildContext context) {
    final responsiveSpacing = UIDensityService.getResponsiveSpacing(
      context,
      spacing,
      customDensity: customDensity,
    );

    return SizedBox(
      width: direction == Axis.horizontal ? responsiveSpacing : null,
      height: direction == Axis.vertical ? responsiveSpacing : null,
    );
  }
}

/// Widget that provides responsive padding based on UI density
class DensityAwarePadding extends StatelessWidget {

  const DensityAwarePadding({
    required this.padding, required this.child, super.key,
    this.customDensity,
  });

  DensityAwarePadding.all(
    double padding, {
    required this.child, super.key,
    this.customDensity,
  }) : padding = EdgeInsets.all(padding);

  DensityAwarePadding.symmetric({
    required this.child, super.key,
    double vertical = 0,
    double horizontal = 0,
    this.customDensity,
  }) : padding = EdgeInsets.symmetric(vertical: vertical, horizontal: horizontal);
  final EdgeInsets padding;
  final Widget child;
  final VisualDensity? customDensity;

  @override
  Widget build(BuildContext context) {
    final responsivePadding = UIDensityService.getResponsivePadding(
      context,
      padding,
      customDensity: customDensity,
    );

    return Padding(
      padding: responsivePadding,
      child: child,
    );
  }
}

/// Widget that provides responsive container based on UI density
class DensityAwareContainer extends StatelessWidget {

  const DensityAwareContainer({
    super.key,
    this.child,
    this.padding,
    this.margin,
    this.color,
    this.decoration,
    this.width,
    this.height,
    this.alignment,
    this.customDensity,
  });
  final Widget? child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Color? color;
  final Decoration? decoration;
  final double? width;
  final double? height;
  final AlignmentGeometry? alignment;
  final VisualDensity? customDensity;

  @override
  Widget build(BuildContext context) {
    final responsivePadding = padding != null
        ? UIDensityService.getResponsivePadding(context, padding!, customDensity: customDensity)
        : null;
    
    final responsiveMargin = margin != null
        ? UIDensityService.getResponsiveMargin(context, margin!, customDensity: customDensity)
        : null;

    return Container(
      padding: responsivePadding,
      margin: responsiveMargin,
      color: color,
      decoration: decoration,
      width: width,
      height: height,
      alignment: alignment,
      child: child,
    );
  }
}

/// Mixin for widgets that need UI density awareness
mixin UIDensityMixin<T extends StatefulWidget> on State<T> {
  /// Get current visual density
  VisualDensity get visualDensity => Theme.of(context).visualDensity;
  
  /// Get spacing multiplier
  double get spacingMultiplier => UIDensityService.getSpacingMultiplier(visualDensity);
  
  /// Get responsive spacing
  double getResponsiveSpacing(double baseSpacing) => UIDensityService.getResponsiveSpacing(context, baseSpacing);
  
  /// Get responsive padding
  EdgeInsets getResponsivePadding(EdgeInsets basePadding) => UIDensityService.getResponsivePadding(context, basePadding);
  
  /// Get responsive margin
  EdgeInsets getResponsiveMargin(EdgeInsets baseMargin) => UIDensityService.getResponsiveMargin(context, baseMargin);
  
  /// Get responsive icon size
  double getResponsiveIconSize(double baseIconSize) => UIDensityService.getResponsiveIconSize(context, baseIconSize);
}