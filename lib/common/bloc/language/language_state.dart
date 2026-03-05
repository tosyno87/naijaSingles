part of 'language_bloc.dart';

/// Base class for language states
abstract class LanguageState extends Equatable {
  const LanguageState();

  Locale get locale;

  @override
  List<Object?> get props => [locale];
}

/// Initial state - default locale
class LanguageInitial extends LanguageState {
  const LanguageInitial(this.locale);
  @override
  final Locale locale;

  @override
  List<Object?> get props => [locale];
}

/// Locale changed
class LanguageChanged extends LanguageState {
  const LanguageChanged(this.locale);
  @override
  final Locale locale;

  @override
  List<Object?> get props => [locale];
}
