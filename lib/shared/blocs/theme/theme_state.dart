import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../../themes/lifexp_theme.dart';

/// State for theme management
class ThemeState extends Equatable {

  const ThemeState({
    required this.currentThemeType,
    required this.themeData,
    required this.isDarkMode,
    required this.unlockedThemes,
    this.isLoading = false,
    this.error,
  });

  /// Initial state with light theme
  factory ThemeState.initial() => ThemeState(
      currentThemeType: LifeXPThemeType.light,
      themeData: LifeXPTheme.lightTheme,
      isDarkMode: false,
      unlockedThemes: const [LifeXPThemeType.light, LifeXPThemeType.dark],
    );
  final LifeXPThemeType currentThemeType;
  final ThemeData themeData;
  final bool isDarkMode;
  final List<LifeXPThemeType> unlockedThemes;
  final bool isLoading;
  final String? error;

  /// Loading state
  ThemeState copyWithLoading() => copyWith(isLoading: true);

  /// Success state
  ThemeState copyWithSuccess({
    LifeXPThemeType? currentThemeType,
    ThemeData? themeData,
    bool? isDarkMode,
    List<LifeXPThemeType>? unlockedThemes,
  }) => copyWith(
      currentThemeType: currentThemeType,
      themeData: themeData,
      isDarkMode: isDarkMode,
      unlockedThemes: unlockedThemes,
      isLoading: false,
    );

  /// Error state
  ThemeState copyWithError(String error) => copyWith(isLoading: false, error: error);

  /// Copy with method
  ThemeState copyWith({
    LifeXPThemeType? currentThemeType,
    ThemeData? themeData,
    bool? isDarkMode,
    List<LifeXPThemeType>? unlockedThemes,
    bool? isLoading,
    String? error,
  }) => ThemeState(
      currentThemeType: currentThemeType ?? this.currentThemeType,
      themeData: themeData ?? this.themeData,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      unlockedThemes: unlockedThemes ?? this.unlockedThemes,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );

  /// Check if a theme is unlocked
  bool isThemeUnlocked(LifeXPThemeType themeType) => unlockedThemes.contains(themeType);

  /// Get available themes (unlocked only)
  List<LifeXPThemeType> get availableThemes => LifeXPTheme.availableThemes
        .where(isThemeUnlocked)
        .toList();

  /// Get locked themes
  List<LifeXPThemeType> get lockedThemes => LifeXPTheme.availableThemes
        .where((theme) => !isThemeUnlocked(theme))
        .toList();

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
