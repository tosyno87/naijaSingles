part of 'streetview_bloc.dart';

/// Base class for street view states
abstract class StreetViewState extends Equatable {
  const StreetViewState();

  @override
  List<Object?> get props => [];
}

/// Initial state - street view not loaded
class StreetViewInitial extends StreetViewState {
  const StreetViewInitial();
}

/// Street view loaded with current mode
class StreetViewLoaded extends StreetViewState {

  const StreetViewLoaded(this.streetMode);
  final String streetMode;

  @override
  List<Object?> get props => [streetMode];
}

/// Error loading street view
class StreetViewError extends StreetViewState {

  const StreetViewError(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}
