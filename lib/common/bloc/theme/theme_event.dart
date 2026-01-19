part of 'theme_bloc.dart';

/// Base class for theme events
abstract class ThemeEvent extends Equatable {
  const ThemeEvent();

  @override
  List<Object?> get props => [];
}

/// Event to initialize theme from preferences
class ThemeInitialized extends ThemeEvent {
  const ThemeInitialized();
}

/// Event to toggle theme mode
class ThemeModeChanged extends ThemeEvent {
  final ThemeMode themeMode;

  const ThemeModeChanged(this.themeMode);

  @override
  List<Object?> get props => [themeMode];
}
