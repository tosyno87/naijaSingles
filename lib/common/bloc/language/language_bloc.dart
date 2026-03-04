import 'package:easy_localization/easy_localization.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'language_event.dart';
part 'language_state.dart';

/// BLoC for managing app language/locale (delegates to EasyLocalization).
class LanguageBloc extends Bloc<LanguageEvent, LanguageState> {
  LanguageBloc() : super(const LanguageInitial(Locale('en', 'US'))) {
    on<LanguageLocaleChanged>(_onLanguageLocaleChanged);
  }

  void _onLanguageLocaleChanged(
    LanguageLocaleChanged event,
    Emitter<LanguageState> emit,
  ) {
    EasyLocalization.of(event.context)?.setLocale(event.locale);
    emit(LanguageChanged(event.locale));
  }

  /// Get current locale from state
  Locale get currentLocale => state.locale;
}
