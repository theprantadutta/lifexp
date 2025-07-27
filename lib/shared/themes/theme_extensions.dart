import 'package:flutter/material.dart';
import 'lifexp_theme.dart';

/// Extension to easily access LifeXP custom colors from BuildContext
extension LifeXPThemeExtension on BuildContext {
  /// Get the current LifeXP custom colors
  LifeXPColors get lifexpColors {
    final extension = Theme.of(this).extension<LifeXPColors>();
    if (extension == null) {
      throw StateError('LifeXPColors extension not found in current theme');
    }
    return extension;
  }

  /// Quick access to common colors
  Color get xpPrimary => lifexpColors.xpPrimary;
  Color get xpSecondary => lifexpColors.xpSecondary;
  Color get streakFire => lifexpColors.streakFire;
  Color get achievementGold => lifexpColors.achievementGold;

  /// Get category color by name
  Color getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'health':
        return lifexpColors.healthCategory;
      case 'finance':
        return lifexpColors.financeCategory;
      case 'work':
        return lifexpColors.workCategory;
      case 'custom':
      default:
        return lifexpColors.customCategory;
    }
  }

  /// Get achievement color by tier
  Color getAchievementColor(String tier) {
    switch (tier.toLowerCase()) {
      case 'gold':
        return lifexpColors.achievementGold;
      case 'silver':
        return lifexpColors.achievementSilver;
      case 'bronze':
        return lifexpColors.achievementBronze;
      default:
        return lifexpColors.achievementBronze;
    }
  }

  /// Get world element color
  Color getWorldColor(String element) {
    switch (element.toLowerCase()) {
      case 'grass':
        return lifexpColors.worldGrass;
      case 'water':
        return lifexpColors.worldWater;
      case 'mountain':
        return lifexpColors.worldMountain;
      case 'desert':
        return lifexpColors.worldDesert;
      default:
        return lifexpColors.worldGrass;
    }
  }

  /// Create XP gradient
  LinearGradient get xpGradient => LinearGradient(
    colors: [lifexpColors.xpGradientStart, lifexpColors.xpGradientEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Create category gradient
  LinearGradient getCategoryGradient(String category) {
    final baseColor = getCategoryColor(category);
    return LinearGradient(
      colors: [baseColor, baseColor.withValues(alpha: 0.7)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }
}
