import 'package:flutter/material.dart';

/// Custom theme data for LifeXP app with gamification-focused colors
class LifeXPTheme {
  // Seed colors for Material 3 color schemes
  static const Color _primarySeedLight = Color(
    0xFF6366F1,
  ); // Indigo for XP/progress
  static const Color _primarySeedDark = Color(
    0xFF818CF8,
  ); // Lighter indigo for dark mode

  static const Color _secondarySeedLight = Color(
    0xFF10B981,
  ); // Emerald for achievements
  static const Color _secondarySeedDark = Color(
    0xFF34D399,
  ); // Lighter emerald for dark mode

  static const Color _tertiarySeedLight = Color(
    0xFFF59E0B,
  ); // Amber for rewards
  static const Color _tertiarySeedDark = Color(
    0xFFFBBF24,
  ); // Lighter amber for dark mode

  // Custom gamification colors
  static const Map<String, Color> _customColorsLight = {
    'xpPrimary': Color(0xFF6366F1),
    'xpSecondary': Color(0xFF8B5CF6),
    'xpGradientStart': Color(0xFF6366F1),
    'xpGradientEnd': Color(0xFF8B5CF6),
    'achievementGold': Color(0xFFFFD700),
    'achievementSilver': Color(0xFFC0C0C0),
    'achievementBronze': Color(0xFFCD7F32),
    'streakFire': Color(0xFFFF6B35),
    'healthCategory': Color(0xFF10B981),
    'financeCategory': Color(0xFF059669),
    'workCategory': Color(0xFF3B82F6),
    'customCategory': Color(0xFF8B5CF6),
    'worldGrass': Color(0xFF22C55E),
    'worldWater': Color(0xFF06B6D4),
    'worldMountain': Color(0xFF6B7280),
    'worldDesert': Color(0xFFF59E0B),
  };

  static const Map<String, Color> _customColorsDark = {
    'xpPrimary': Color(0xFF818CF8),
    'xpSecondary': Color(0xFFA78BFA),
    'xpGradientStart': Color(0xFF818CF8),
    'xpGradientEnd': Color(0xFFA78BFA),
    'achievementGold': Color(0xFFFFD700),
    'achievementSilver': Color(0xFFC0C0C0),
    'achievementBronze': Color(0xFFCD7F32),
    'streakFire': Color(0xFFFF8A65),
    'healthCategory': Color(0xFF34D399),
    'financeCategory': Color(0xFF10B981),
    'workCategory': Color(0xFF60A5FA),
    'customCategory': Color(0xFFA78BFA),
    'worldGrass': Color(0xFF4ADE80),
    'worldWater': Color(0xFF22D3EE),
    'worldMountain': Color(0xFF9CA3AF),
    'worldDesert': Color(0xFFFBBF24),
  };

  // Theme data getters
  static ThemeData get lightTheme => _buildTheme(
    colorScheme: ColorScheme.fromSeed(
      seedColor: _primarySeedLight,
      secondary: _secondarySeedLight,
      tertiary: _tertiarySeedLight,
    ),
    customColors: _customColorsLight,
    brightness: Brightness.light,
  );

  static ThemeData get darkTheme => _buildTheme(
    colorScheme: ColorScheme.fromSeed(
      seedColor: _primarySeedDark,
      brightness: Brightness.dark,
      secondary: _secondarySeedDark,
      tertiary: _tertiarySeedDark,
    ),
    customColors: _customColorsDark,
    brightness: Brightness.dark,
  );

  // Unlockable themes (can be expanded with more themes)
  static ThemeData get oceanTheme => _buildTheme(
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF0EA5E9), // Sky blue
      secondary: const Color(0xFF06B6D4), // Cyan
      tertiary: const Color(0xFF8B5CF6), // Purple
    ),
    customColors: {
      ..._customColorsLight,
      'xpPrimary': const Color(0xFF0EA5E9),
      'xpSecondary': const Color(0xFF06B6D4),
      'xpGradientStart': const Color(0xFF0EA5E9),
      'xpGradientEnd': const Color(0xFF06B6D4),
    },
    brightness: Brightness.light,
  );

  static ThemeData get forestTheme => _buildTheme(
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF059669), // Emerald
      secondary: const Color(0xFF10B981), // Green
      tertiary: const Color(0xFF84CC16), // Lime
    ),
    customColors: {
      ..._customColorsLight,
      'xpPrimary': const Color(0xFF059669),
      'xpSecondary': const Color(0xFF10B981),
      'xpGradientStart': const Color(0xFF059669),
      'xpGradientEnd': const Color(0xFF10B981),
    },
    brightness: Brightness.light,
  );

  static ThemeData get sunsetTheme => _buildTheme(
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFFEF4444), // Red
      secondary: const Color(0xFFF97316), // Orange
      tertiary: const Color(0xFFF59E0B), // Amber
    ),
    customColors: {
      ..._customColorsLight,
      'xpPrimary': const Color(0xFFEF4444),
      'xpSecondary': const Color(0xFFF97316),
      'xpGradientStart': const Color(0xFFEF4444),
      'xpGradientEnd': const Color(0xFFF97316),
    },
    brightness: Brightness.light,
  );

  // Helper method to build theme with custom colors
  static ThemeData _buildTheme({
    required ColorScheme colorScheme,
    required Map<String, Color> customColors,
    required Brightness brightness,
  }) => ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: brightness,

      // App bar theme
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),

      // Card theme
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: colorScheme.surface,
      ),

      // Elevated button theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),

      // Floating action button theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      // Bottom navigation bar theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurface.withValues(alpha: 0.6),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      // Navigation drawer theme
      drawerTheme: DrawerThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: colorScheme.surfaceTint,
      ),

      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        filled: true,
        fillColor: colorScheme.surface,
      ),

      // Text theme
      textTheme: TextTheme(
        displayLarge: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
        displayMedium: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
        displaySmall: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 24,
          fontWeight: FontWeight.w600,
        ),
        headlineLarge: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
        headlineMedium: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        headlineSmall: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        titleSmall: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 16,
          fontWeight: FontWeight.normal,
        ),
        bodyMedium: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 14,
          fontWeight: FontWeight.normal,
        ),
        bodySmall: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 12,
          fontWeight: FontWeight.normal,
        ),
        labelLarge: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        labelMedium: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        labelSmall: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),

      // Extensions for custom colors
      extensions: [LifeXPColors(customColors)],
    );

  // Available theme types
  static const List<LifeXPThemeType> availableThemes = [
    LifeXPThemeType.light,
    LifeXPThemeType.dark,
    LifeXPThemeType.ocean,
    LifeXPThemeType.forest,
    LifeXPThemeType.sunset,
  ];

  // Get theme by type
  static ThemeData getThemeByType(LifeXPThemeType type) {
    switch (type) {
      case LifeXPThemeType.light:
        return lightTheme;
      case LifeXPThemeType.dark:
        return darkTheme;
      case LifeXPThemeType.ocean:
        return oceanTheme;
      case LifeXPThemeType.forest:
        return forestTheme;
      case LifeXPThemeType.sunset:
        return sunsetTheme;
    }
  }
}

/// Theme extension for custom colors
class LifeXPColors extends ThemeExtension<LifeXPColors> {

  const LifeXPColors(this.colors);
  final Map<String, Color> colors;

  Color get xpPrimary => colors['xpPrimary']!;
  Color get xpSecondary => colors['xpSecondary']!;
  Color get xpGradientStart => colors['xpGradientStart']!;
  Color get xpGradientEnd => colors['xpGradientEnd']!;
  Color get achievementGold => colors['achievementGold']!;
  Color get achievementSilver => colors['achievementSilver']!;
  Color get achievementBronze => colors['achievementBronze']!;
  Color get streakFire => colors['streakFire']!;
  Color get healthCategory => colors['healthCategory']!;
  Color get financeCategory => colors['financeCategory']!;
  Color get workCategory => colors['workCategory']!;
  Color get customCategory => colors['customCategory']!;
  Color get worldGrass => colors['worldGrass']!;
  Color get worldWater => colors['worldWater']!;
  Color get worldMountain => colors['worldMountain']!;
  Color get worldDesert => colors['worldDesert']!;

  @override
  LifeXPColors copyWith({Map<String, Color>? colors}) => LifeXPColors(colors ?? this.colors);

  @override
  LifeXPColors lerp(ThemeExtension<LifeXPColors>? other, double t) {
    if (other is! LifeXPColors) return this;

    final lerpedColors = <String, Color>{};
    for (final key in colors.keys) {
      lerpedColors[key] = Color.lerp(colors[key], other.colors[key], t)!;
    }

    return LifeXPColors(lerpedColors);
  }
}

/// Available theme types
enum LifeXPThemeType { light, dark, ocean, forest, sunset }

/// Extension to get theme type display name
extension LifeXPThemeTypeExtension on LifeXPThemeType {
  String get displayName {
    switch (this) {
      case LifeXPThemeType.light:
        return 'Light';
      case LifeXPThemeType.dark:
        return 'Dark';
      case LifeXPThemeType.ocean:
        return 'Ocean';
      case LifeXPThemeType.forest:
        return 'Forest';
      case LifeXPThemeType.sunset:
        return 'Sunset';
    }
  }

  String get description {
    switch (this) {
      case LifeXPThemeType.light:
        return 'Clean and bright interface';
      case LifeXPThemeType.dark:
        return 'Comfortable night viewing';
      case LifeXPThemeType.ocean:
        return 'Calm blue waters theme';
      case LifeXPThemeType.forest:
        return 'Natural green forest theme';
      case LifeXPThemeType.sunset:
        return 'Warm sunset colors theme';
    }
  }

  bool get isUnlockable {
    switch (this) {
      case LifeXPThemeType.light:
      case LifeXPThemeType.dark:
        return false;
      case LifeXPThemeType.ocean:
      case LifeXPThemeType.forest:
      case LifeXPThemeType.sunset:
        return true;
    }
  }

  int get unlockLevel {
    switch (this) {
      case LifeXPThemeType.light:
      case LifeXPThemeType.dark:
        return 0;
      case LifeXPThemeType.ocean:
        return 10;
      case LifeXPThemeType.forest:
        return 20;
      case LifeXPThemeType.sunset:
        return 30;
    }
  }
}
