import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemePreferences {
  static const themekey = 'pref_key';

  setTheme(ThemeMode value) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    sharedPreferences.setString(themekey, value.name);
  }

  getTheme() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    final savedTheme = sharedPreferences.getString(themekey);
    log("savedtheme $savedTheme");
    if (savedTheme != null) {
      switch (savedTheme) {
        case 'dark':
          return ThemeMode.dark;
        case 'light':
          return ThemeMode.light;
        case 'system':
          return ThemeMode.system;
        default:
          return ThemeMode.system;
      }
    } else {
      return ThemeMode.system;
    }
  }
}
