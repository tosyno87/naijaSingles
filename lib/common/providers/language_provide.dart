// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class LanguageProvider extends ChangeNotifier {
  BuildContext context;
  Locale _currentLocale = const Locale('en', 'US');

  LanguageProvider(
    this.context,
  ) {
    context = context;
  }

  Locale get currentLocale => _currentLocale;

  void setLocale(Locale locale) {
    _currentLocale = locale;
    EasyLocalization.of(context)!
        .setLocale(locale); // Set the locale using EasyLocalization
    notifyListeners();
  }
}
