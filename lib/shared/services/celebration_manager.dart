import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../widgets/particle_celebration.dart';
import 'animation_service.dart';

/// Manager for coordinating celebration animations and effects
class CelebrationManager {
  /// Shows a complete level up celebration with multiple effects
  static Future<void> celebrateLevelUp(
    BuildContext context, {
    required int newLevel,
    required int xpGained,
  }) async {
    // Haptic feedback
    HapticFeedback.heavyImpact();

    // Show confetti first
    _showConfettiOverlay(context);

    // Wait a bit then show the main celebration
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (context.mounted) {
      AnimationService.showLevelUpCelebration(
        context,
        newLevel: newLevel,
      );
    }

    // Play sound effect (if available)
    _playLevelUpSound();
  }

  /// Shows achievement unlock celebration
  static Future<void> celebrateAchievementUnlock(
    BuildContext context, {
    required String achievementName,
    required String achievementDescription,
  }) async {
    // Haptic feedback
    HapticFeedback.mediumImpact();

    // Show particle effects
    _showParticleOverlay(context);

    // Show achievement notification
    AnimationService.showAchievementUnlock(
      context,
      achievementName: achievementName,
    );

    // Play sound effect
    _playAchievementSound();
  }

  /// Shows task completion celebration
  static Future<void> celebrateTaskCompletion(
    BuildContext context, {
    required int xpGained,
    bool isStreakMilestone = false,
    int? streakCount,
  }) async {
    // Light haptic feedback
    HapticFeedback.lightImpact();

    if (isStreakMilestone && streakCount != null) {
      // Show streak milestone celebration
      AnimationService.showStreakMilestone(
        context,
        streakCount: streakCount,
      );
      _playStreakSound();
    } else {
      // Show regular task completion
      AnimationService.showTaskCompletion(
        context,
        xpGained: xpGained,
      );
      _playTaskCompleteSound();
    }
  }

  /// Shows a custom celebration
  static Future<void> celebrateCustom(
    BuildContext context, {
    required String title,
    String? subtitle,
    CelebrationType type = CelebrationType.generic,
  }) async {
    HapticFeedback.selectionClick();

    switch (type) {
      case CelebrationType.confetti:
        _showConfettiOverlay(context);
        break;
      case CelebrationType.particles:
        _showParticleOverlay(context);
        break;
      case CelebrationType.generic:
        break;
    }

    AnimationService.showGenericCelebration(
      context,
      title: title,
      subtitle: subtitle,
    );
  }

  /// Shows confetti overlay
  static void _showConfettiOverlay(BuildContext context) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned.fill(
        child: IgnorePointer(
          child: ConfettiCelebration(
            onComplete: () => overlayEntry.remove(),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);
  }

  /// Shows particle overlay
  static void _showParticleOverlay(BuildContext context) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned.fill(
        child: IgnorePointer(
          child: ParticleCelebration(
            onComplete: () => overlayEntry.remove(),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);
  }

  /// Plays level up sound effect
  static void _playLevelUpSound() {
    // TODO: Implement sound effects
    // SystemSound.play(SystemSoundType.alert);
  }

  /// Plays achievement sound effect
  static void _playAchievementSound() {
    // TODO: Implement sound effects
    // SystemSound.play(SystemSoundType.alert);
  }

  /// Plays task complete sound effect
  static void _playTaskCompleteSound() {
    // TODO: Implement sound effects
    // SystemSound.play(SystemSoundType.click);
  }

  /// Plays streak sound effect
  static void _playStreakSound() {
    // TODO: Implement sound effects
    // SystemSound.play(SystemSoundType.alert);
  }
}

/// Types of celebration effects
enum CelebrationType {
  generic,
  confetti,
  particles,
}

/// Mixin to easily add celebrations to widgets
mixin CelebrationMixin<T extends StatefulWidget> on State<T> {
  /// Celebrate level up
  void celebrateLevelUp({
    required int newLevel,
    required int xpGained,
  }) {
    CelebrationManager.celebrateLevelUp(
      context,
      newLevel: newLevel,
      xpGained: xpGained,
    );
  }

  /// Celebrate achievement unlock
  void celebrateAchievementUnlock({
    required String achievementName,
    required String achievementDescription,
  }) {
    CelebrationManager.celebrateAchievementUnlock(
      context,
      achievementName: achievementName,
      achievementDescription: achievementDescription,
    );
  }

  /// Celebrate task completion
  void celebrateTaskCompletion({
    required int xpGained,
    bool isStreakMilestone = false,
    int? streakCount,
  }) {
    CelebrationManager.celebrateTaskCompletion(
      context,
      xpGained: xpGained,
      isStreakMilestone: isStreakMilestone,
      streakCount: streakCount,
    );
  }

  /// Show custom celebration
  void celebrateCustom({
    required String title,
    String? subtitle,
    CelebrationType type = CelebrationType.generic,
  }) {
    CelebrationManager.celebrateCustom(
      context,
      title: title,
      subtitle: subtitle,
      type: type,
    );
  }
}