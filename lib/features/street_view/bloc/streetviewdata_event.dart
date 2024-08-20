part of 'streetviewdata_bloc.dart';

abstract class StreetviewdataEvent extends Equatable {
  const StreetviewdataEvent();

  @override
  List<Object> get props => [];
}

class LoadStreetViewDataEvent extends StreetviewdataEvent {
  final UserModel user;

  const LoadStreetViewDataEvent({required this.user});

  @override
  List<Object> get props => [user];
}
