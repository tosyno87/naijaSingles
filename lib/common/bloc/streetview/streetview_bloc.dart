import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/streetview_prefrences.dart';

part 'streetview_event.dart';
part 'streetview_state.dart';

/// BLoC for managing street view preferences
/// Replaces StreetViewProvider with BLoC pattern
class StreetViewBloc extends Bloc<StreetViewEvent, StreetViewState> {
  StreetViewBloc(this.userId) : super(const StreetViewInitial()) {
    on<StreetViewInitialized>(_onStreetViewInitialized);
    on<StreetViewModeChanged>(_onStreetViewModeChanged);

    // Initialize street view automatically when bloc is created
    add(const StreetViewInitialized());
  }

  final String userId;
  final StretViewPreferences _preferences = StretViewPreferences(userId);

  Future<void> _onStreetViewInitialized(
    StreetViewInitialized event,
    Emitter<StreetViewState> emit,
  ) async {
    try {
      final savedView = await _preferences.getView();
      emit(StreetViewLoaded(savedView));
    } catch (e) {
      emit(StreetViewError(e.toString()));
    }
  }

  void _onStreetViewModeChanged(
    StreetViewModeChanged event,
    Emitter<StreetViewState> emit,
  ) {
    final value = event.value;
    String streetMode;

    switch (value) {
      case 'None':
        streetMode = 'None';
        break;
      case 'Everyone':
        streetMode = 'Everyone';
        break;
      case 'My Matches':
        streetMode = 'My Matches';
        break;
      case 'Only':
        streetMode = 'Only';
        break;
      default:
        streetMode = 'None';
    }

    _preferences.setView(value, event.userIds);
    emit(StreetViewLoaded(streetMode));
  }

  /// Get current street mode from state
  String? get currentStreetMode {
    if (state is StreetViewLoaded) {
      return (state as StreetViewLoaded).streetMode;
    }
    return null;
  }
}
