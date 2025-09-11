import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Provides locale management for the app.
class LanguageProvider extends ChangeNotifier {
  /// The [BuildContext] used by EasyLocalization.
  BuildContext context;

  /// Currently selected locale.
  Locale _currentLocale = const Locale('en', 'US');

  /// Creates a [LanguageProvider].
  LanguageProvider(this.context);

  /// Returns the current locale.
  Locale get currentLocale => _currentLocale;

  /// Sets a new locale and notifies listeners.
  void setLocale(Locale locale) {
    _currentLocale = locale;
    EasyLocalization.of(context)!.setLocale(locale);
    notifyListeners();
  }
}
