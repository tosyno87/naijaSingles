part of 'language_bloc.dart';

/// Base class for language events
abstract class LanguageEvent extends Equatable {
  const LanguageEvent();

  @override
  List<Object?> get props => [];
}

/// Event to set locale
class LanguageLocaleChanged extends LanguageEvent {
  final Locale locale;
  final BuildContext context;

  const LanguageLocaleChanged(this.locale, this.context);

  @override
  List<Object?> get props => [locale];
}
