part of 'language_bloc.dart';

import 'package:flutter/material.dart';

/// Base class for language states
abstract class LanguageState extends Equatable {
  const LanguageState();

  @override
  List<Object?> get props => [];
}

/// Initial state - default locale
class LanguageInitial extends LanguageState {
  final Locale locale;

  const LanguageInitial(this.locale);

  @override
  List<Object?> get props => [locale];
}

/// Locale changed
class LanguageChanged extends LanguageState {
  final Locale locale;

  const LanguageChanged(this.locale);

  @override
  List<Object?> get props => [locale];
}
