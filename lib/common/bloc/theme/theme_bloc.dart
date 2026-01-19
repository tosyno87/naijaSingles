import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/theme_prefrences.dart';

part 'theme_event.dart';
part 'theme_state.dart';

/// BLoC for managing app theme
/// Replaces ThemeProvider with BLoC pattern
class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  ThemeBloc() : super(const ThemeInitial()) {
    on<ThemeInitialized>(_onThemeInitialized);
    on<ThemeModeChanged>(_onThemeModeChanged);

    // Initialize theme automatically when bloc is created
    add(const ThemeInitialized());
  }

  final ThemePreferences _preferences = ThemePreferences();

  Future<void> _onThemeInitialized(
    ThemeInitialized event,
    Emitter<ThemeState> emit,
  ) async {
    try {
      final savedTheme = await _preferences.getTheme();
      emit(ThemeLoaded(savedTheme));
    } catch (e) {
      emit(ThemeError(e.toString()));
    }
  }

  void _onThemeModeChanged(
    ThemeModeChanged event,
    Emitter<ThemeState> emit,
  ) {
    final themeMode = event.themeMode;
    _preferences.setTheme(themeMode);
    emit(ThemeLoaded(themeMode));
  }

  /// Get current theme mode from state
  ThemeMode? get currentThemeMode {
    if (state is ThemeLoaded) {
      return (state as ThemeLoaded).themeMode;
    }
    return null;
  }

  /// Get if dark mode is active
  bool get isDarkMode {
    if (state is ThemeLoaded) {
      return (state as ThemeLoaded).isDarkMode;
    }
    return false;
  }
}
