import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../themes/lifexp_theme.dart';
import 'theme_event.dart';
import 'theme_state.dart';

/// BLoC for managing app theme state
class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  static const String _themeTypeKey = 'theme_type';
  static const String _isDarkModeKey = 'is_dark_mode';
  static const String _unlockedThemesKey = 'unlocked_themes';

  ThemeBloc() : super(ThemeState.initial()) {
    on<LoadThemeEvent>(_onLoadTheme);
    on<ChangeThemeEvent>(_onChangeTheme);
    on<ToggleDarkModeEvent>(_onToggleDarkMode);
    on<UnlockThemeEvent>(_onUnlockTheme);
    on<ResetThemeEvent>(_onResetTheme);
  }

  /// Load theme from storage
  Future<void> _onLoadTheme(
    LoadThemeEvent event,
    Emitter<ThemeState> emit,
  ) async {
    try {
      emit(state.copyWithLoading());

      final prefs = await SharedPreferences.getInstance();

      // Load theme type
      final themeTypeString = prefs.getString(_themeTypeKey);
      LifeXPThemeType themeType = LifeXPThemeType.light;
      if (themeTypeString != null) {
        themeType = LifeXPThemeType.values.firstWhere(
          (type) => type.toString() == themeTypeString,
          orElse: () => LifeXPThemeType.light,
        );
      }

      // Load dark mode preference
      final isDarkMode = prefs.getBool(_isDarkModeKey) ?? false;

      // Load unlocked themes
      final unlockedThemesStrings =
          prefs.getStringList(_unlockedThemesKey) ??
          [LifeXPThemeType.light.toString(), LifeXPThemeType.dark.toString()];
      final unlockedThemes = unlockedThemesStrings
          .map(
            (themeString) => LifeXPThemeType.values.firstWhere(
              (type) => type.toString() == themeString,
              orElse: () => LifeXPThemeType.light,
            ),
          )
          .toList();

      // If current theme is not unlocked, fallback to light theme
      if (!unlockedThemes.contains(themeType)) {
        themeType = LifeXPThemeType.light;
      }

      // Apply dark mode override if needed
      final finalThemeType = isDarkMode && themeType == LifeXPThemeType.light
          ? LifeXPThemeType.dark
          : themeType;

      final themeData = LifeXPTheme.getThemeByType(finalThemeType);

      emit(
        state.copyWithSuccess(
          currentThemeType: finalThemeType,
          themeData: themeData,
          isDarkMode: isDarkMode,
          unlockedThemes: unlockedThemes,
        ),
      );
    } catch (e) {
      emit(state.copyWithError('Failed to load theme: ${e.toString()}'));
    }
  }

  /// Change theme
  Future<void> _onChangeTheme(
    ChangeThemeEvent event,
    Emitter<ThemeState> emit,
  ) async {
    try {
      // Check if theme is unlocked
      if (!state.isThemeUnlocked(event.themeType)) {
        emit(
          state.copyWithError(
            'Theme ${event.themeType.displayName} is not unlocked',
          ),
        );
        return;
      }

      emit(state.copyWithLoading());

      final themeData = LifeXPTheme.getThemeByType(event.themeType);
      final isDarkMode = event.themeType == LifeXPThemeType.dark;

      // Save to storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeTypeKey, event.themeType.toString());
      await prefs.setBool(_isDarkModeKey, isDarkMode);

      emit(
        state.copyWithSuccess(
          currentThemeType: event.themeType,
          themeData: themeData,
          isDarkMode: isDarkMode,
        ),
      );
    } catch (e) {
      emit(state.copyWithError('Failed to change theme: ${e.toString()}'));
    }
  }

  /// Toggle dark mode
  Future<void> _onToggleDarkMode(
    ToggleDarkModeEvent event,
    Emitter<ThemeState> emit,
  ) async {
    try {
      emit(state.copyWithLoading());

      final newIsDarkMode = !state.isDarkMode;
      final newThemeType = newIsDarkMode
          ? LifeXPThemeType.dark
          : LifeXPThemeType.light;

      final themeData = LifeXPTheme.getThemeByType(newThemeType);

      // Save to storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeTypeKey, newThemeType.toString());
      await prefs.setBool(_isDarkModeKey, newIsDarkMode);

      emit(
        state.copyWithSuccess(
          currentThemeType: newThemeType,
          themeData: themeData,
          isDarkMode: newIsDarkMode,
        ),
      );
    } catch (e) {
      emit(state.copyWithError('Failed to toggle dark mode: ${e.toString()}'));
    }
  }

  /// Unlock a new theme
  Future<void> _onUnlockTheme(
    UnlockThemeEvent event,
    Emitter<ThemeState> emit,
  ) async {
    try {
      // Check if theme is already unlocked
      if (state.isThemeUnlocked(event.themeType)) {
        return;
      }

      emit(state.copyWithLoading());

      final newUnlockedThemes = [...state.unlockedThemes, event.themeType];

      // Save to storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        _unlockedThemesKey,
        newUnlockedThemes.map((theme) => theme.toString()).toList(),
      );

      emit(state.copyWithSuccess(unlockedThemes: newUnlockedThemes));
    } catch (e) {
      emit(state.copyWithError('Failed to unlock theme: ${e.toString()}'));
    }
  }

  /// Reset theme to default
  Future<void> _onResetTheme(
    ResetThemeEvent event,
    Emitter<ThemeState> emit,
  ) async {
    try {
      emit(state.copyWithLoading());

      // Clear storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_themeTypeKey);
      await prefs.remove(_isDarkModeKey);
      await prefs.remove(_unlockedThemesKey);

      // Reset to initial state
      final initialState = ThemeState.initial();
      emit(initialState);
    } catch (e) {
      emit(state.copyWithError('Failed to reset theme: ${e.toString()}'));
    }
  }

  /// Unlock theme based on user level (helper method)
  void unlockThemeByLevel(int userLevel) {
    for (final themeType in LifeXPTheme.availableThemes) {
      if (themeType.isUnlockable &&
          userLevel >= themeType.unlockLevel &&
          !state.isThemeUnlocked(themeType)) {
        add(UnlockThemeEvent(themeType));
      }
    }
  }
}
