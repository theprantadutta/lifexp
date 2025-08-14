import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';

/// Service for managing accessibility features and screen reader support
class AccessibilityService {
  factory AccessibilityService() => _instance;
  AccessibilityService._internal();
  static final AccessibilityService _instance = AccessibilityService._internal();

  /// Check if screen reader is enabled
  bool get isScreenReaderEnabled => WidgetsBinding.instance.accessibilityFeatures.accessibleNavigation;

  /// Check if high contrast is enabled
  bool get isHighContrastEnabled => WidgetsBinding.instance.accessibilityFeatures.highContrast;

  /// Check if reduce motion is enabled
  bool get isReduceMotionEnabled => WidgetsBinding.instance.accessibilityFeatures.reduceMotion;

  /// Check if bold text is enabled
  bool get isBoldTextEnabled => WidgetsBinding.instance.accessibilityFeatures.boldText;

  /// Get text scale factor
  double get textScaleFactor => WidgetsBinding.instance.platformDispatcher.textScaleFactor;

  /// Announce message to screen reader
  void announce(String message, {TextDirection? textDirection}) {
    SemanticsService.announce(
      message,
      textDirection ?? TextDirection.ltr,
    );
  }

  /// Announce XP gain
  void announceXPGain(int xpGained, int totalXP) {
    announce('Gained $xpGained XP! Total XP is now $totalXP');
  }

  /// Announce level up
  void announceLevelUp(int newLevel, int xpGained) {
    announce('Congratulations! Level up! You are now level $newLevel and gained $xpGained XP');
  }

  /// Announce achievement unlock
  void announceAchievementUnlock(String achievementName, String description) {
    announce('Achievement unlocked: $achievementName. $description');
  }

  /// Announce task completion
  void announceTaskCompletion(String taskTitle, int xpReward, int streakCount) {
    final streakText = streakCount > 1 ? ' Streak: $streakCount days!' : '';
    announce('Task completed: $taskTitle. Earned $xpReward XP.$streakText');
  }

  /// Announce streak warning
  void announceStreakWarning(String taskTitle, int streakCount) {
    announce('Streak warning: Complete $taskTitle to maintain your $streakCount day streak');
  }

  /// Create semantic label for XP progress
  String createXPProgressLabel(int currentXP, int xpToNext, int level) {
    final percentage = ((currentXP / (currentXP + xpToNext)) * 100).round();
    return 'Level $level progress: $currentXP out of ${currentXP + xpToNext} XP, $percentage percent complete';
  }

  /// Create semantic label for task card
  String createTaskCardLabel({
    required String title,
    required String category,
    required String difficulty,
    required bool isCompleted,
    required int xpReward,
    int? streakCount,
    DateTime? dueDate,
  }) {
    final buffer = StringBuffer();
    
    if (isCompleted) {
      buffer.write('Completed task: ');
    } else {
      buffer.write('Task: ');
    }
    
    buffer.write(title);
    buffer.write(', Category: $category');
    buffer.write(', Difficulty: $difficulty');
    buffer.write(', XP reward: $xpReward');
    
    if (streakCount != null && streakCount > 0) {
      buffer.write(', Streak: $streakCount days');
    }
    
    if (dueDate != null && !isCompleted) {
      final now = DateTime.now();
      final difference = dueDate.difference(now);
      
      if (difference.isNegative) {
        buffer.write(', Overdue');
      } else if (difference.inDays == 0) {
        buffer.write(', Due today');
      } else if (difference.inDays == 1) {
        buffer.write(', Due tomorrow');
      } else {
        buffer.write(', Due in ${difference.inDays} days');
      }
    }
    
    return buffer.toString();
  }

  /// Create semantic label for achievement badge
  String createAchievementLabel({
    required String name,
    required String description,
    required bool isUnlocked,
    double? progress,
  }) {
    final buffer = StringBuffer();
    
    if (isUnlocked) {
      buffer.write('Unlocked achievement: ');
    } else {
      buffer.write('Locked achievement: ');
    }
    
    buffer.write(name);
    buffer.write(', $description');
    
    if (!isUnlocked && progress != null) {
      final percentage = (progress * 100).round();
      buffer.write(', Progress: $percentage percent');
    }
    
    return buffer.toString();
  }

  /// Create semantic label for avatar
  String createAvatarLabel({
    required int level,
    required int strength,
    required int wisdom,
    required int intelligence,
  }) => 'Avatar level $level, Strength: $strength, Wisdom: $wisdom, Intelligence: $intelligence';

  /// Create semantic label for attribute bar
  String createAttributeLabel({
    required String attributeName,
    required int currentValue,
    required int maxValue,
  }) {
    final percentage = ((currentValue / maxValue) * 100).round();
    return '$attributeName: $currentValue out of $maxValue, $percentage percent';
  }

  /// Create semantic hint for interactive elements
  String createInteractionHint(String action) => 'Double tap to $action';

  /// Create semantic label for navigation
  String createNavigationLabel(String screenName, {bool isSelected = false}) {
    final selectedText = isSelected ? ', selected' : '';
    return '$screenName tab$selectedText';
  }

  /// Create semantic label for progress chart
  String createChartLabel({
    required String chartType,
    required String timeRange,
    required List<double> values,
  }) {
    if (values.isEmpty) return '$chartType chart for $timeRange, no data available';
    
    final minValue = values.reduce((a, b) => a < b ? a : b);
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final avgValue = values.reduce((a, b) => a + b) / values.length;
    
    return '$chartType chart for $timeRange, ${values.length} data points, '
           'minimum: ${minValue.round()}, maximum: ${maxValue.round()}, '
           'average: ${avgValue.round()}';
  }

  /// Create semantic label for world tile
  String createWorldTileLabel({
    required String tileName,
    required bool isUnlocked,
    required String tileType,
    int? unlockRequirement,
  }) {
    final buffer = StringBuffer();
    
    if (isUnlocked) {
      buffer.write('Unlocked $tileType: ');
    } else {
      buffer.write('Locked $tileType: ');
    }
    
    buffer.write(tileName);
    
    if (!isUnlocked && unlockRequirement != null) {
      buffer.write(', Requires $unlockRequirement XP to unlock');
    }
    
    return buffer.toString();
  }

  /// Create reading order for complex layouts
  List<Widget> createReadingOrder(List<Widget> children) => children.map((child) => Semantics(
        sortKey: const OrdinalSortKey(0),
        child: child,
      )).toList();

  /// Create focus traversal order
  Map<LogicalKeySet, Intent> get focusTraversalShortcuts => {
    LogicalKeySet(LogicalKeyboardKey.tab): const NextFocusIntent(),
    LogicalKeySet(LogicalKeyboardKey.tab, LogicalKeyboardKey.shift): const PreviousFocusIntent(),
    LogicalKeySet(LogicalKeyboardKey.arrowDown): const DirectionalFocusIntent(TraversalDirection.down),
    LogicalKeySet(LogicalKeyboardKey.arrowUp): const DirectionalFocusIntent(TraversalDirection.up),
    LogicalKeySet(LogicalKeyboardKey.arrowLeft): const DirectionalFocusIntent(TraversalDirection.left),
    LogicalKeySet(LogicalKeyboardKey.arrowRight): const DirectionalFocusIntent(TraversalDirection.right),
  };

  /// Provide haptic feedback for accessibility
  void provideHapticFeedback() {
    HapticFeedback.vibrate();
  }

  /// Create accessible button
  Widget createAccessibleButton({
    required Widget child,
    required VoidCallback onPressed,
    required String semanticLabel,
    String? semanticHint,
    bool excludeSemantics = false,
  }) => Semantics(
      label: semanticLabel,
      hint: semanticHint ?? createInteractionHint('activate'),
      button: true,
      enabled: true,
      excludeSemantics: excludeSemantics,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: () {
            provideHapticFeedback();
            onPressed();
          },
          child: child,
        ),
      ),
    );

  /// Create accessible slider
  Widget createAccessibleSlider({
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
    required String semanticLabel,
    String? semanticHint,
    int? divisions,
  }) => Semantics(
      label: semanticLabel,
      hint: semanticHint ?? 'Swipe up or down to adjust value',
      slider: true,
      value: value.toString(),
      increasedValue: value < max ? (value + ((max - min) / (divisions ?? 100))).toString() : null,
      decreasedValue: value > min ? (value - ((max - min) / (divisions ?? 100))).toString() : null,
      child: Slider(
        value: value,
        min: min,
        max: max,
        divisions: divisions,
        onChanged: onChanged,
      ),
    );

  /// Create accessible text field
  Widget createAccessibleTextField({
    required TextEditingController controller,
    required String labelText,
    String? hintText,
    String? errorText,
    bool obscureText = false,
    TextInputType? keyboardType,
    ValueChanged<String>? onChanged,
  }) => Semantics(
      label: labelText,
      hint: hintText,
      textField: true,
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: labelText,
          hintText: hintText,
          errorText: errorText,
        ),
      ),
    );

  /// Create accessible list
  Widget createAccessibleList({
    required List<Widget> children,
    required String semanticLabel,
    ScrollController? controller,
  }) => Semantics(
      label: semanticLabel,
      child: ListView(
        controller: controller,
        children: children.asMap().entries.map((entry) {
          final index = entry.key;
          final child = entry.value;
          
          return Semantics(
            sortKey: OrdinalSortKey(index.toDouble()),
            child: child,
          );
        }).toList(),
      ),
    );

  /// Create accessible dialog
  Widget createAccessibleDialog({
    required Widget child,
    required String title,
    String? semanticLabel,
  }) => Semantics(
      label: semanticLabel ?? title,
      namesRoute: true,
      child: AlertDialog(
        title: Semantics(
          header: true,
          child: Text(title),
        ),
        content: child,
      ),
    );

  /// Create accessible app bar
  PreferredSizeWidget createAccessibleAppBar({
    required String title,
    List<Widget>? actions,
    Widget? leading,
    bool automaticallyImplyLeading = true,
  }) => AppBar(
      title: Semantics(
        header: true,
        child: Text(title),
      ),
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
      actions: actions?.map((action) => Semantics(
          button: true,
          child: action,
        )).toList(),
    );

  /// Create accessible bottom navigation
  Widget createAccessibleBottomNavigation({
    required List<BottomNavigationBarItem> items,
    required int currentIndex,
    required ValueChanged<int> onTap,
  }) => Semantics(
      label: 'Navigation bar',
      child: BottomNavigationBar(
        items: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          
          return BottomNavigationBarItem(
            icon: Semantics(
              label: createNavigationLabel(
                item.label ?? 'Tab ${index + 1}',
                isSelected: index == currentIndex,
              ),
              button: true,
              selected: index == currentIndex,
              child: item.icon,
            ),
            label: item.label,
          );
        }).toList(),
        currentIndex: currentIndex,
        onTap: onTap,
      ),
    );
}