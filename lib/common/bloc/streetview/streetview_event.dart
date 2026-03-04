part of 'streetview_bloc.dart';

/// Base class for street view events
abstract class StreetViewEvent extends Equatable {
  const StreetViewEvent();

  @override
  List<Object?> get props => [];
}

/// Event to initialize street view from preferences
class StreetViewInitialized extends StreetViewEvent {
  const StreetViewInitialized();
}

/// Event to toggle street view mode
class StreetViewModeChanged extends StreetViewEvent {

  const StreetViewModeChanged(this.value, this.userIds);
  final String value;
  final List<String> userIds;

  @override
  List<Object?> get props => [value, userIds];
}
