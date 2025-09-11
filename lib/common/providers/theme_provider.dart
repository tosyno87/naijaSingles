import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../data/theme_prefrences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode themeMode = ThemeMode.system;
  final ThemePreferences _preferences = ThemePreferences();

  ThemeProvider() {
    initializeTheme();
  }
  Future<void> initializeTheme() async {
    final savedTheme = await _preferences.getTheme();
    if (savedTheme != null) {
      themeMode = savedTheme;
    }
    notifyListeners();
  }

  bool get isDarkMode {
    if (themeMode == ThemeMode.system) {
      final brightness =
          SchedulerBinding.instance.platformDispatcher.platformBrightness;
      return brightness == Brightness.dark;
    } else {
      return themeMode == ThemeMode.dark;
    }
  }

  void toggleTheme(ThemeMode value) {
    final value1 = value.name;
    switch (value1) {
      case 'dark':
        themeMode = ThemeMode.dark;
        break;
      case 'light':
        themeMode = ThemeMode.light;
        break;
      case 'system':
        themeMode = ThemeMode.system;
        break;
      default:
        themeMode = ThemeMode.system;
    }
    // themeMode = value.name == 'dark' ? ThemeMode.dark : ThemeMode.light;
    _preferences.setTheme(value);

    notifyListeners();
  }
}
