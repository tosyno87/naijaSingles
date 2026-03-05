part of 'theme_bloc.dart';

/// Base class for theme states
abstract class ThemeState extends Equatable {
  const ThemeState();

  @override
  List<Object?> get props => [];
}

/// Initial state - theme not loaded
class ThemeInitial extends ThemeState {
  const ThemeInitial();
}

/// Theme loaded with current mode
class ThemeLoaded extends ThemeState {
  const ThemeLoaded(this.themeMode);
  final ThemeMode themeMode;

  @override
  List<Object?> get props => [themeMode];

  /// Get if dark mode is active
  bool get isDarkMode {
    if (themeMode == ThemeMode.system) {
      final brightness =
          SchedulerBinding.instance.platformDispatcher.platformBrightness;
      return brightness == Brightness.dark;
    } else {
      return themeMode == ThemeMode.dark;
    }
  }
}

/// Error loading theme
class ThemeError extends ThemeState {
  const ThemeError(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}
