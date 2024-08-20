part of 'match_bloc.dart';

abstract class MatchUserState extends Equatable {
  const MatchUserState();

  @override
  List<Object> get props => [];
}

class MatchUserInitial extends MatchUserState {}

class MatchUserLoadingState extends MatchUserState {}

class MatchUserLoadedState extends MatchUserState {
  final List<UserModel> users;

  const MatchUserLoadedState(this.users);

  @override
  List<Object> get props => [users];
}

class MatchUserFailedState extends MatchUserState {}
