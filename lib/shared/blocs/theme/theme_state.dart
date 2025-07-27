import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../../themes/lifexp_theme.dart';

/// State for theme management
class ThemeState extends Equatable {
  final LifeXPThemeType currentThemeType;
  final ThemeData themeData;
  final bool isDarkMode;
  final List<LifeXPThemeType> unlockedThemes;
  final bool isLoading;
  final String? error;

  const ThemeState({
    required this.currentThemeType,
    required this.themeData,
    required this.isDarkMode,
    required this.unlockedThemes,
    this.isLoading = false,
    this.error,
  });

  /// Initial state with light theme
  factory ThemeState.initial() {
    return ThemeState(
      currentThemeType: LifeXPThemeType.light,
      themeData: LifeXPTheme.lightTheme,
      isDarkMode: false,
      unlockedThemes: const [LifeXPThemeType.light, LifeXPThemeType.dark],
    );
  }

  /// Loading state
  ThemeState copyWithLoading() {
    return copyWith(isLoading: true, error: null);
  }

  /// Success state
  ThemeState copyWithSuccess({
    LifeXPThemeType? currentThemeType,
    ThemeData? themeData,
    bool? isDarkMode,
    List<LifeXPThemeType>? unlockedThemes,
  }) {
    return copyWith(
      currentThemeType: currentThemeType,
      themeData: themeData,
      isDarkMode: isDarkMode,
      unlockedThemes: unlockedThemes,
      isLoading: false,
      error: null,
    );
  }

  /// Error state
  ThemeState copyWithError(String error) {
    return copyWith(isLoading: false, error: error);
  }

  /// Copy with method
  ThemeState copyWith({
    LifeXPThemeType? currentThemeType,
    ThemeData? themeData,
    bool? isDarkMode,
    List<LifeXPThemeType>? unlockedThemes,
    bool? isLoading,
    String? error,
  }) {
    return ThemeState(
      currentThemeType: currentThemeType ?? this.currentThemeType,
      themeData: themeData ?? this.themeData,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      unlockedThemes: unlockedThemes ?? this.unlockedThemes,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  /// Check if a theme is unlocked
  bool isThemeUnlocked(LifeXPThemeType themeType) {
    return unlockedThemes.contains(themeType);
  }

  /// Get available themes (unlocked only)
  List<LifeXPThemeType> get availableThemes {
    return LifeXPTheme.availableThemes
        .where((theme) => isThemeUnlocked(theme))
        .toList();
  }

  /// Get locked themes
  List<LifeXPThemeType> get lockedThemes {
    return LifeXPTheme.availableThemes
        .where((theme) => !isThemeUnlocked(theme))
        .toList();
  }

  @override
  List<Object?> get props => [
    currentThemeType,
    themeData,
    isDarkMode,
    unlockedThemes,
    isLoading,
    error,
  ];
}
