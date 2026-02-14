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
  @override
  final Locale locale;

  const LanguageInitial(this.locale);

  @override
  List<Object?> get props => [locale];
}

/// Locale changed
class LanguageChanged extends LanguageState {
  @override
  final Locale locale;

  const LanguageChanged(this.locale);

  @override
  List<Object?> get props => [locale];
}
