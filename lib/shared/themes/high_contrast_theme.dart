import 'package:flutter/material.dart';

/// High contrast theme system for users with visual impairments
class HighContrastTheme {
  /// Create high contrast light theme
  static ThemeData createHighContrastLight() {
    const primaryColor = Color(0xFF000000); // Pure black
    const onPrimaryColor = Color(0xFFFFFFFF); // Pure white
    const secondaryColor = Color(0xFF0000FF); // Pure blue
    const errorColor = Color(0xFFFF0000); // Pure red
    const successColor = Color(0xFF008000); // Pure green
    const warningColor = Color(0xFFFF8000); // Pure orange
    
    const colorScheme = ColorScheme.light(
      primary: primaryColor,
      secondary: secondaryColor,
      onSecondary: onPrimaryColor,
      error: errorColor,
      surfaceContainerHighest: Color(0xFFF0F0F0),
      outline: primaryColor,
      outlineVariant: Color(0xFF808080),
    );
    
    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      
      // High contrast text theme
      textTheme: _createHighContrastTextTheme(primaryColor),
      
      // High contrast app bar theme
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: onPrimaryColor,
        elevation: 4,
        titleTextStyle: TextStyle(
          color: onPrimaryColor,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      
      // High contrast card theme
      cardTheme: CardTheme(
        color: onPrimaryColor,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(width: 2),
        ),
      ),
      
      // High contrast button themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: onPrimaryColor,
          elevation: 4,
          side: const BorderSide(width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          textStyle: const TextStyle(
            decoration: TextDecoration.underline,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      
      // High contrast input decoration theme
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(
          borderSide: BorderSide(width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: secondaryColor, width: 3),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: errorColor, width: 2),
        ),
        labelStyle: TextStyle(
          color: primaryColor,
          fontWeight: FontWeight.bold,
        ),
        hintStyle: TextStyle(
          color: Color(0xFF808080),
          fontWeight: FontWeight.normal,
        ),
      ),
      
      // High contrast chip theme
      chipTheme: ChipThemeData(
        backgroundColor: onPrimaryColor,
        selectedColor: primaryColor,
        labelStyle: const TextStyle(
          color: primaryColor,
          fontWeight: FontWeight.bold,
        ),
        secondaryLabelStyle: const TextStyle(
          color: onPrimaryColor,
          fontWeight: FontWeight.bold,
        ),
        side: const BorderSide(width: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      
      // High contrast switch theme
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return onPrimaryColor;
          }
          return const Color(0xFF808080);
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor;
          }
          return const Color(0xFFE0E0E0);
        }),
        trackOutlineColor: WidgetStateProperty.all(primaryColor),
      ),
      
      // High contrast checkbox theme
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor;
          }
          return onPrimaryColor;
        }),
        checkColor: WidgetStateProperty.all(onPrimaryColor),
        side: const BorderSide(width: 2),
      ),
      
      // High contrast radio theme
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor;
          }
          return onPrimaryColor;
        }),
      ),
      
      // High contrast slider theme
      sliderTheme: SliderThemeData(
        activeTrackColor: primaryColor,
        inactiveTrackColor: const Color(0xFFE0E0E0),
        thumbColor: primaryColor,
        overlayColor: primaryColor.withValues(alpha: 0.2),
        trackHeight: 6,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
      ),
      
      // High contrast progress indicator theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryColor,
        linearTrackColor: Color(0xFFE0E0E0),
        circularTrackColor: Color(0xFFE0E0E0),
      ),
      
      // High contrast divider theme
      dividerTheme: const DividerThemeData(
        color: primaryColor,
        thickness: 2,
      ),
      
      // High contrast list tile theme
      listTileTheme: ListTileThemeData(
        textColor: primaryColor,
        iconColor: primaryColor,
        tileColor: onPrimaryColor,
        selectedTileColor: const Color(0xFFF0F0F0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(),
        ),
      ),
      
      // High contrast bottom navigation bar theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: onPrimaryColor,
        selectedItemColor: primaryColor,
        unselectedItemColor: Color(0xFF808080),
        selectedLabelStyle: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
        unselectedLabelStyle: TextStyle(
          fontWeight: FontWeight.normal,
          fontSize: 12,
        ),
      ),
      
      // High contrast tab bar theme
      tabBarTheme: const TabBarTheme(
        labelColor: primaryColor,
        unselectedLabelColor: Color(0xFF808080),
        indicatorColor: primaryColor,
        indicatorSize: TabBarIndicatorSize.tab,
        labelStyle: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
        unselectedLabelStyle: TextStyle(
          fontWeight: FontWeight.normal,
          fontSize: 14,
        ),
      ),
    );
  }
  
  /// Create high contrast dark theme
  static ThemeData createHighContrastDark() {
    const primaryColor = Color(0xFFFFFFFF); // Pure white
    const onPrimaryColor = Color(0xFF000000); // Pure black
    const secondaryColor = Color(0xFF00FFFF); // Pure cyan
    const errorColor = Color(0xFFFF4444); // Bright red
    const successColor = Color(0xFF44FF44); // Bright green
    const warningColor = Color(0xFFFFAA00); // Bright orange
    const backgroundColor = Color(0xFF000000); // Pure black
    
    const colorScheme = ColorScheme.dark(
      primary: primaryColor,
      secondary: secondaryColor,
      error: errorColor,
      surface: backgroundColor,
      surfaceContainerHighest: Color(0xFF1A1A1A),
      outline: primaryColor,
      outlineVariant: Color(0xFF808080),
    );
    
    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      
      // High contrast text theme
      textTheme: _createHighContrastTextTheme(primaryColor),
      
      // High contrast app bar theme
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundColor,
        foregroundColor: primaryColor,
        elevation: 4,
        titleTextStyle: TextStyle(
          color: primaryColor,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      
      // High contrast card theme
      cardTheme: CardTheme(
        color: backgroundColor,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: primaryColor, width: 2),
        ),
      ),
      
      // High contrast button themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: onPrimaryColor,
          elevation: 4,
          side: const BorderSide(color: primaryColor, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          textStyle: const TextStyle(
            decoration: TextDecoration.underline,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      
      // High contrast input decoration theme
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: secondaryColor, width: 3),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: errorColor, width: 2),
        ),
        labelStyle: TextStyle(
          color: primaryColor,
          fontWeight: FontWeight.bold,
        ),
        hintStyle: TextStyle(
          color: Color(0xFF808080),
          fontWeight: FontWeight.normal,
        ),
      ),
    );
  }
  
  /// Create high contrast text theme
  static TextTheme _createHighContrastTextTheme(Color textColor) => TextTheme(
      displayLarge: TextStyle(
        color: textColor,
        fontSize: 57,
        fontWeight: FontWeight.bold,
        height: 1.2,
      ),
      displayMedium: TextStyle(
        color: textColor,
        fontSize: 45,
        fontWeight: FontWeight.bold,
        height: 1.2,
      ),
      displaySmall: TextStyle(
        color: textColor,
        fontSize: 36,
        fontWeight: FontWeight.bold,
        height: 1.2,
      ),
      headlineLarge: TextStyle(
        color: textColor,
        fontSize: 32,
        fontWeight: FontWeight.bold,
        height: 1.25,
      ),
      headlineMedium: TextStyle(
        color: textColor,
        fontSize: 28,
        fontWeight: FontWeight.bold,
        height: 1.25,
      ),
      headlineSmall: TextStyle(
        color: textColor,
        fontSize: 24,
        fontWeight: FontWeight.bold,
        height: 1.25,
      ),
      titleLarge: TextStyle(
        color: textColor,
        fontSize: 22,
        fontWeight: FontWeight.bold,
        height: 1.3,
      ),
      titleMedium: TextStyle(
        color: textColor,
        fontSize: 16,
        fontWeight: FontWeight.bold,
        height: 1.3,
      ),
      titleSmall: TextStyle(
        color: textColor,
        fontSize: 14,
        fontWeight: FontWeight.bold,
        height: 1.3,
      ),
      bodyLarge: TextStyle(
        color: textColor,
        fontSize: 16,
        fontWeight: FontWeight.w500,
        height: 1.4,
      ),
      bodyMedium: TextStyle(
        color: textColor,
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.4,
      ),
      bodySmall: TextStyle(
        color: textColor,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1.4,
      ),
      labelLarge: TextStyle(
        color: textColor,
        fontSize: 14,
        fontWeight: FontWeight.bold,
        height: 1.4,
      ),
      labelMedium: TextStyle(
        color: textColor,
        fontSize: 12,
        fontWeight: FontWeight.bold,
        height: 1.4,
      ),
      labelSmall: TextStyle(
        color: textColor,
        fontSize: 11,
        fontWeight: FontWeight.bold,
        height: 1.4,
      ),
    );
  
  /// Color blind friendly color palette
  static const ColorBlindFriendlyColors colorBlindFriendly = ColorBlindFriendlyColors();
}

/// Color blind friendly color palette
class ColorBlindFriendlyColors {
  const ColorBlindFriendlyColors();
  
  // Primary colors that work for most types of color blindness
  Color get blue => const Color(0xFF0173B2);
  Color get orange => const Color(0xFFDE8F05);
  Color get green => const Color(0xFF029E73);
  Color get red => const Color(0xFFD55E00);
  Color get purple => const Color(0xFFCC78BC);
  Color get brown => const Color(0xFF8B4513);
  Color get pink => const Color(0xFFE377C2);
  Color get gray => const Color(0xFF7F7F7F);
  Color get yellow => const Color(0xFFF0E442);
  Color get lightBlue => const Color(0xFF56B4E9);
  
  /// Get color by category with patterns for additional differentiation
  Color getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'health':
        return green;
      case 'fitness':
        return blue;
      case 'learning':
        return purple;
      case 'work':
        return orange;
      case 'finance':
        return brown;
      case 'social':
        return pink;
      case 'creative':
        return yellow;
      case 'mindfulness':
        return lightBlue;
      default:
        return gray;
    }
  }
  
  /// Get pattern for additional visual differentiation
  String getCategoryPattern(String category) {
    switch (category.toLowerCase()) {
      case 'health':
        return '●●●'; // Solid dots
      case 'fitness':
        return '▲▲▲'; // Triangles
      case 'learning':
        return '■■■'; // Squares
      case 'work':
        return '♦♦♦'; // Diamonds
      case 'finance':
        return '▼▼▼'; // Down triangles
      case 'social':
        return '●○●'; // Mixed dots
      case 'creative':
        return '★★★'; // Stars
      case 'mindfulness':
        return '◆◆◆'; // Filled diamonds
      default:
        return '───'; // Lines
    }
  }
}