part of 'streetviewdata_bloc.dart';

abstract class StreetviewdataState extends Equatable {
  const StreetviewdataState();

  @override
  List<Object> get props => [];
}

class StreetviewdataInitial extends StreetviewdataState {}

class StreetViewDataLoadingState extends StreetviewdataState {}

class StreetViewDataLoadedState extends StreetviewdataState {
  final List<String> userIds;
  final String option;
  const StreetViewDataLoadedState(this.userIds, this.option);

  @override
  List<Object> get props => [userIds, option];
}

class StreetViewDataFailedState extends StreetviewdataState {}
