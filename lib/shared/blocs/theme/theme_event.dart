import 'package:equatable/equatable.dart';
import '../../themes/lifexp_theme.dart';

/// Events for theme management
abstract class ThemeEvent extends Equatable {
  const ThemeEvent();

  @override
  List<Object?> get props => [];
}

/// Event to change the current theme
class ChangeThemeEvent extends ThemeEvent {
  final LifeXPThemeType themeType;

  const ChangeThemeEvent(this.themeType);

  @override
  List<Object?> get props => [themeType];
}

/// Event to toggle between light and dark mode
class ToggleDarkModeEvent extends ThemeEvent {
  const ToggleDarkModeEvent();
}

/// Event to unlock a new theme
class UnlockThemeEvent extends ThemeEvent {
  final LifeXPThemeType themeType;

  const UnlockThemeEvent(this.themeType);

  @override
  List<Object?> get props => [themeType];
}

/// Event to load theme from storage
class LoadThemeEvent extends ThemeEvent {
  const LoadThemeEvent();
}

/// Event to reset theme to default
class ResetThemeEvent extends ThemeEvent {
  const ResetThemeEvent();
}
