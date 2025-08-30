import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Service for managing haptic feedback throughout the app
class HapticFeedbackService {
  factory HapticFeedbackService() => _instance;
  HapticFeedbackService._internal();
  static final HapticFeedbackService _instance = HapticFeedbackService._internal();

  bool _isEnabled = true;
  
  /// Enable or disable haptic feedback
  void setEnabled(bool enabled) {
    _isEnabled = enabled;
  }
  
  /// Check if haptic feedback is enabled
  bool get isEnabled => _isEnabled;

  /// Light impact feedback for subtle interactions
  Future<void> lightImpact() async {
    if (!_isEnabled) return;
    
    try {
      await HapticFeedback.lightImpact();
    } catch (e) {
      if (kDebugMode) {
        developer.log('Light impact failed: $e', name: 'HapticFeedbackService');
      }
    }
  }

  /// Medium impact feedback for standard interactions
  Future<void> mediumImpact() async {
    if (!_isEnabled) return;
    
    try {
      await HapticFeedback.mediumImpact();
    } catch (e) {
      if (kDebugMode) {
        developer.log('Medium impact failed: $e', name: 'HapticFeedbackService');
      }
    }
  }

  /// Heavy impact feedback for significant interactions
  Future<void> heavyImpact() async {
    if (!_isEnabled) return;
    
    try {
      await HapticFeedback.heavyImpact();
    } catch (e) {
      if (kDebugMode) {
        developer.log('Heavy impact failed: $e', name: 'HapticFeedbackService');
      }
    }
  }

  /// Selection click feedback for UI selections
  Future<void> selectionClick() async {
    if (!_isEnabled) return;
    
    try {
      await HapticFeedback.selectionClick();
    } catch (e) {
      if (kDebugMode) {
        developer.log('Selection click failed: $e', name: 'HapticFeedbackService');
      }
    }
  }

  /// Vibrate for notifications and alerts
  Future<void> vibrate() async {
    if (!_isEnabled) return;
    
    try {
      await HapticFeedback.vibrate();
    } catch (e) {
      if (kDebugMode) {
        developer.log('Vibrate failed: $e', name: 'HapticFeedbackService');
      }
    }
  }

  // Gamification-specific feedback methods

  /// Feedback for task completion
  Future<void> taskCompleted() async {
    await mediumImpact();
  }

  /// Feedback for XP gain
  Future<void> xpGained() async {
    await lightImpact();
  }

  /// Feedback for level up
  Future<void> levelUp() async {
    // Double impact for emphasis
    await heavyImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    await heavyImpact();
  }

  /// Feedback for achievement unlock
  Future<void> achievementUnlocked() async {
    // Triple impact pattern for special events
    await mediumImpact();
    await Future.delayed(const Duration(milliseconds: 80));
    await mediumImpact();
    await Future.delayed(const Duration(milliseconds: 80));
    await heavyImpact();
  }

  /// Feedback for streak milestone
  Future<void> streakMilestone() async {
    await heavyImpact();
  }

  /// Feedback for button press
  Future<void> buttonPress() async {
    await lightImpact();
  }

  /// Feedback for navigation
  Future<void> navigation() async {
    await selectionClick();
  }

  /// Feedback for error or failure
  Future<void> error() async {
    await vibrate();
  }

  /// Feedback for success
  Future<void> success() async {
    await mediumImpact();
  }

  /// Feedback for warning
  Future<void> warning() async {
    await lightImpact();
  }

  /// Feedback for world tile unlock
  Future<void> worldTileUnlocked() async {
    await mediumImpact();
    await Future.delayed(const Duration(milliseconds: 150));
    await lightImpact();
  }

  /// Feedback for attribute increase
  Future<void> attributeIncrease() async {
    await lightImpact();
  }

  /// Feedback for streak warning
  Future<void> streakWarning() async {
    // Gentle double tap
    await lightImpact();
    await Future.delayed(const Duration(milliseconds: 200));
    await lightImpact();
  }

  /// Feedback for daily goal completion
  Future<void> dailyGoalCompleted() async {
    // Celebratory pattern
    await mediumImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    await lightImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    await mediumImpact();
  }

  /// Feedback for category milestone
  Future<void> categoryMilestone() async {
    await mediumImpact();
  }

  /// Feedback for perfect week
  Future<void> perfectWeek() async {
    // Special celebration pattern
    await heavyImpact();
    await Future.delayed(const Duration(milliseconds: 120));
    await mediumImpact();
    await Future.delayed(const Duration(milliseconds: 80));
    await mediumImpact();
    await Future.delayed(const Duration(milliseconds: 80));
    await heavyImpact();
  }

  /// Feedback for app launch
  Future<void> appLaunch() async {
    await lightImpact();
  }

  /// Feedback for refresh action
  Future<void> refresh() async {
    await selectionClick();
  }

  /// Feedback for swipe action
  Future<void> swipe() async {
    await lightImpact();
  }

  /// Feedback for long press
  Future<void> longPress() async {
    await mediumImpact();
  }

  /// Feedback for drag start
  Future<void> dragStart() async {
    await lightImpact();
  }

  /// Feedback for drag end
  Future<void> dragEnd() async {
    await mediumImpact();
  }

  /// Feedback for toggle switch
  Future<void> toggle() async {
    await selectionClick();
  }

  /// Feedback for slider change
  Future<void> sliderChange() async {
    await lightImpact();
  }

  /// Feedback for tab switch
  Future<void> tabSwitch() async {
    await selectionClick();
  }

  /// Feedback for modal open
  Future<void> modalOpen() async {
    await lightImpact();
  }

  /// Feedback for modal close
  Future<void> modalClose() async {
    await lightImpact();
  }

  /// Feedback for form submission
  Future<void> formSubmit() async {
    await mediumImpact();
  }

  /// Feedback for search
  Future<void> search() async {
    await lightImpact();
  }

  /// Feedback for filter applied
  Future<void> filterApplied() async {
    await selectionClick();
  }

  /// Feedback for sort changed
  Future<void> sortChanged() async {
    await selectionClick();
  }

  /// Custom feedback pattern
  Future<void> customPattern(List<HapticFeedbackType> pattern, {Duration delay = const Duration(milliseconds: 100)}) async {
    if (!_isEnabled) return;
    
    for (var i = 0; i < pattern.length; i++) {
      switch (pattern[i]) {
        case HapticFeedbackType.light:
          await lightImpact();
          break;
        case HapticFeedbackType.medium:
          await mediumImpact();
          break;
        case HapticFeedbackType.heavy:
          await heavyImpact();
          break;
        case HapticFeedbackType.selection:
          await selectionClick();
          break;
        case HapticFeedbackType.vibrate:
          await vibrate();
          break;
      }
      
      // Add delay between patterns (except for the last one)
      if (i < pattern.length - 1) {
        await Future.delayed(delay);
      }
    }
  }
}

/// Enum for haptic feedback types
enum HapticFeedbackType {
  light,
  medium,
  heavy,
  selection,
  vibrate,
}

/// Mixin for widgets that need haptic feedback
mixin HapticFeedbackMixin<T extends StatefulWidget> on State<T> {
  final HapticFeedbackService _hapticService = HapticFeedbackService();
  
  /// Provide haptic feedback
  Future<void> hapticFeedback(HapticFeedbackType type) async {
    switch (type) {
      case HapticFeedbackType.light:
        await _hapticService.lightImpact();
        break;
      case HapticFeedbackType.medium:
        await _hapticService.mediumImpact();
        break;
      case HapticFeedbackType.heavy:
        await _hapticService.heavyImpact();
        break;
      case HapticFeedbackType.selection:
        await _hapticService.selectionClick();
        break;
      case HapticFeedbackType.vibrate:
        await _hapticService.vibrate();
        break;
    }
  }
  
  /// Quick access to common feedback methods
  Future<void> onTaskCompleted() => _hapticService.taskCompleted();
  Future<void> onXPGained() => _hapticService.xpGained();
  Future<void> onLevelUp() => _hapticService.levelUp();
  Future<void> onAchievementUnlocked() => _hapticService.achievementUnlocked();
  Future<void> onButtonPress() => _hapticService.buttonPress();
  Future<void> onNavigation() => _hapticService.navigation();
  Future<void> onError() => _hapticService.error();
  Future<void> onSuccess() => _hapticService.success();
}