import 'package:flutter/material.dart';

/// Service for managing responsive text scaling and accessibility features
class TextScalingService {
  static const double _minScaleFactor = 0.8;
  static const double _maxScaleFactor = 3;
  static const double _defaultScaleFactor = 1;
  
  /// Get the current system text scale factor
  static double getSystemTextScaleFactor(BuildContext context) => MediaQuery.of(context).textScaler.scale(1);
  
  /// Get clamped text scale factor within accessibility limits
  static double getClampedTextScaleFactor(BuildContext context) {
    final systemScale = getSystemTextScaleFactor(context);
    return systemScale.clamp(_minScaleFactor, _maxScaleFactor);
  }
  
  /// Check if large text is enabled
  static bool isLargeTextEnabled(BuildContext context) => getSystemTextScaleFactor(context) > 1.3;
  
  /// Check if extra large text is enabled
  static bool isExtraLargeTextEnabled(BuildContext context) => getSystemTextScaleFactor(context) > 2.0;
  
  /// Get responsive font size based on scale factor
  static double getResponsiveFontSize(BuildContext context, double baseFontSize) {
    final scaleFactor = getClampedTextScaleFactor(context);
    return baseFontSize * scaleFactor;
  }
  
  /// Get responsive padding based on text scale
  static EdgeInsets getResponsivePadding(BuildContext context, EdgeInsets basePadding) {
    final scaleFactor = getClampedTextScaleFactor(context);
    
    // Increase padding for larger text
    if (scaleFactor > 1.5) {
      return basePadding * 1.5;
    } else if (scaleFactor > 1.2) {
      return basePadding * 1.2;
    }
    
    return basePadding;
  }
  
  /// Get responsive spacing based on text scale
  static double getResponsiveSpacing(BuildContext context, double baseSpacing) {
    final scaleFactor = getClampedTextScaleFactor(context);
    
    // Increase spacing for larger text
    if (scaleFactor > 1.5) {
      return baseSpacing * 1.5;
    } else if (scaleFactor > 1.2) {
      return baseSpacing * 1.2;
    }
    
    return baseSpacing;
  }
  
  /// Get responsive icon size based on text scale
  static double getResponsiveIconSize(BuildContext context, double baseIconSize) {
    final scaleFactor = getClampedTextScaleFactor(context);
    
    // Scale icons with text, but not as aggressively
    final iconScaleFactor = 1.0 + ((scaleFactor - 1.0) * 0.5);
    return baseIconSize * iconScaleFactor.clamp(0.8, 2.0);
  }
  
  /// Get responsive button height based on text scale
  static double getResponsiveButtonHeight(BuildContext context, double baseHeight) {
    final scaleFactor = getClampedTextScaleFactor(context);
    
    // Ensure buttons are tall enough for larger text
    if (scaleFactor > 1.5) {
      return baseHeight * 1.4;
    } else if (scaleFactor > 1.2) {
      return baseHeight * 1.2;
    }
    
    return baseHeight;
  }
  
  /// Get responsive minimum touch target size
  static double getResponsiveTouchTarget(BuildContext context) {
    final scaleFactor = getClampedTextScaleFactor(context);
    
    // Ensure touch targets are large enough
    const baseTouchTarget = 44.0; // Material Design minimum
    return (baseTouchTarget * scaleFactor).clamp(44.0, 88.0);
  }
  
  /// Create responsive text style
  static TextStyle createResponsiveTextStyle(
    BuildContext context,
    TextStyle baseStyle,
  ) {
    final scaleFactor = getClampedTextScaleFactor(context);
    
    return baseStyle.copyWith(
      fontSize: (baseStyle.fontSize ?? 14) * scaleFactor,
      height: _getResponsiveLineHeight(scaleFactor, baseStyle.height ?? 1.4),
    );
  }
  
  /// Get responsive line height
  static double _getResponsiveLineHeight(double scaleFactor, double baseHeight) {
    // Adjust line height for better readability with larger text
    if (scaleFactor > 2.0) {
      return baseHeight * 0.9; // Tighter line height for very large text
    } else if (scaleFactor > 1.5) {
      return baseHeight * 0.95;
    }
    
    return baseHeight;
  }
  
  /// Create responsive theme data with proper text scaling
  static ThemeData createResponsiveTheme(BuildContext context, ThemeData baseTheme) {
    final scaleFactor = getClampedTextScaleFactor(context);
    
    // Create responsive text theme
    final responsiveTextTheme = _createResponsiveTextTheme(context, baseTheme.textTheme);
    
    return baseTheme.copyWith(
      textTheme: responsiveTextTheme,
      
      // Responsive app bar theme
      appBarTheme: baseTheme.appBarTheme.copyWith(
        titleTextStyle: createResponsiveTextStyle(
          context,
          baseTheme.appBarTheme.titleTextStyle ?? baseTheme.textTheme.titleLarge!,
        ),
        toolbarHeight: getResponsiveButtonHeight(context, kToolbarHeight),
      ),
      
      // Responsive button themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: baseTheme.elevatedButtonTheme.style?.copyWith(
          minimumSize: WidgetStateProperty.all(
            Size(0, getResponsiveButtonHeight(context, 40)),
          ),
          padding: WidgetStateProperty.all(
            getResponsivePadding(context, const EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
          ),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: baseTheme.outlinedButtonTheme.style?.copyWith(
          minimumSize: WidgetStateProperty.all(
            Size(0, getResponsiveButtonHeight(context, 40)),
          ),
          padding: WidgetStateProperty.all(
            getResponsivePadding(context, const EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
          ),
        ),
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: baseTheme.textButtonTheme.style?.copyWith(
          minimumSize: WidgetStateProperty.all(
            Size(0, getResponsiveButtonHeight(context, 40)),
          ),
          padding: WidgetStateProperty.all(
            getResponsivePadding(context, const EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
          ),
        ),
      ),
      
      // Responsive input decoration theme
      inputDecorationTheme: baseTheme.inputDecorationTheme.copyWith(
        contentPadding: getResponsivePadding(
          context,
          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        labelStyle: createResponsiveTextStyle(
          context,
          baseTheme.inputDecorationTheme.labelStyle ?? baseTheme.textTheme.bodyMedium!,
        ),
        hintStyle: createResponsiveTextStyle(
          context,
          baseTheme.inputDecorationTheme.hintStyle ?? baseTheme.textTheme.bodyMedium!,
        ),
      ),
      
      // Responsive list tile theme
      listTileTheme: baseTheme.listTileTheme.copyWith(
        contentPadding: getResponsivePadding(
          context,
          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        minVerticalPadding: getResponsiveSpacing(context, 8),
        titleTextStyle: createResponsiveTextStyle(
          context,
          baseTheme.listTileTheme.titleTextStyle ?? baseTheme.textTheme.bodyLarge!,
        ),
        subtitleTextStyle: createResponsiveTextStyle(
          context,
          baseTheme.listTileTheme.subtitleTextStyle ?? baseTheme.textTheme.bodyMedium!,
        ),
      ),
      
      // Responsive chip theme
      chipTheme: baseTheme.chipTheme.copyWith(
        labelStyle: createResponsiveTextStyle(
          context,
          baseTheme.chipTheme.labelStyle ?? baseTheme.textTheme.bodyMedium!,
        ),
        labelPadding: getResponsivePadding(
          context,
          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        ),
      ),
      
      // Responsive tab bar theme
      tabBarTheme: baseTheme.tabBarTheme.copyWith(
        labelStyle: createResponsiveTextStyle(
          context,
          baseTheme.tabBarTheme.labelStyle ?? baseTheme.textTheme.bodyMedium!,
        ),
        unselectedLabelStyle: createResponsiveTextStyle(
          context,
          baseTheme.tabBarTheme.unselectedLabelStyle ?? baseTheme.textTheme.bodyMedium!,
        ),
        labelPadding: getResponsivePadding(
          context,
          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),
      
      // Responsive bottom navigation bar theme
      bottomNavigationBarTheme: baseTheme.bottomNavigationBarTheme.copyWith(
        selectedLabelStyle: createResponsiveTextStyle(
          context,
          baseTheme.bottomNavigationBarTheme.selectedLabelStyle ?? baseTheme.textTheme.bodySmall!,
        ),
        unselectedLabelStyle: createResponsiveTextStyle(
          context,
          baseTheme.bottomNavigationBarTheme.unselectedLabelStyle ?? baseTheme.textTheme.bodySmall!,
        ),
      ),
    );
  }
  
  /// Create responsive text theme
  static TextTheme _createResponsiveTextTheme(BuildContext context, TextTheme baseTextTheme) => TextTheme(
      displayLarge: createResponsiveTextStyle(context, baseTextTheme.displayLarge!),
      displayMedium: createResponsiveTextStyle(context, baseTextTheme.displayMedium!),
      displaySmall: createResponsiveTextStyle(context, baseTextTheme.displaySmall!),
      headlineLarge: createResponsiveTextStyle(context, baseTextTheme.headlineLarge!),
      headlineMedium: createResponsiveTextStyle(context, baseTextTheme.headlineMedium!),
      headlineSmall: createResponsiveTextStyle(context, baseTextTheme.headlineSmall!),
      titleLarge: createResponsiveTextStyle(context, baseTextTheme.titleLarge!),
      titleMedium: createResponsiveTextStyle(context, baseTextTheme.titleMedium!),
      titleSmall: createResponsiveTextStyle(context, baseTextTheme.titleSmall!),
      bodyLarge: createResponsiveTextStyle(context, baseTextTheme.bodyLarge!),
      bodyMedium: createResponsiveTextStyle(context, baseTextTheme.bodyMedium!),
      bodySmall: createResponsiveTextStyle(context, baseTextTheme.bodySmall!),
      labelLarge: createResponsiveTextStyle(context, baseTextTheme.labelLarge!),
      labelMedium: createResponsiveTextStyle(context, baseTextTheme.labelMedium!),
      labelSmall: createResponsiveTextStyle(context, baseTextTheme.labelSmall!),
    );
}

/// Widget that provides responsive text scaling
class ResponsiveText extends StatelessWidget {

  const ResponsiveText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap = true,
  });
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool softWrap;

  @override
  Widget build(BuildContext context) {
    final responsiveStyle = style != null
        ? TextScalingService.createResponsiveTextStyle(context, style!)
        : null;

    return Text(
      text,
      style: responsiveStyle,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      softWrap: softWrap,
    );
  }
}

/// Widget that provides responsive padding
class ResponsivePadding extends StatelessWidget {

  const ResponsivePadding({
    required this.padding, required this.child, super.key,
  });
  final EdgeInsets padding;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final responsivePadding = TextScalingService.getResponsivePadding(context, padding);

    return Padding(
      padding: responsivePadding,
      child: child,
    );
  }
}

/// Widget that provides responsive spacing
class ResponsiveSizedBox extends StatelessWidget {

  const ResponsiveSizedBox({
    super.key,
    this.width,
    this.height,
    this.child,
  });

  const ResponsiveSizedBox.height(double height, {super.key})
      : width = null,
        height = height,
        child = null;

  const ResponsiveSizedBox.width(double width, {super.key})
      : width = width,
        height = null,
        child = null;
  final double? width;
  final double? height;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final responsiveWidth = width != null
        ? TextScalingService.getResponsiveSpacing(context, width!)
        : null;
    final responsiveHeight = height != null
        ? TextScalingService.getResponsiveSpacing(context, height!)
        : null;

    return SizedBox(
      width: responsiveWidth,
      height: responsiveHeight,
      child: child,
    );
  }
}

/// Mixin for widgets that need responsive text scaling
mixin ResponsiveTextMixin<T extends StatefulWidget> on State<T> {
  /// Get responsive text style
  TextStyle getResponsiveTextStyle(TextStyle baseStyle) => TextScalingService.createResponsiveTextStyle(context, baseStyle);
  
  /// Get responsive padding
  EdgeInsets getResponsivePadding(EdgeInsets basePadding) => TextScalingService.getResponsivePadding(context, basePadding);
  
  /// Get responsive spacing
  double getResponsiveSpacing(double baseSpacing) => TextScalingService.getResponsiveSpacing(context, baseSpacing);
  
  /// Get responsive icon size
  double getResponsiveIconSize(double baseIconSize) => TextScalingService.getResponsiveIconSize(context, baseIconSize);
  
  /// Check if large text is enabled
  bool get isLargeTextEnabled => TextScalingService.isLargeTextEnabled(context);
  
  /// Check if extra large text is enabled
  bool get isExtraLargeTextEnabled => TextScalingService.isExtraLargeTextEnabled(context);
}