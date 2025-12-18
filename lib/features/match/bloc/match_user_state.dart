part of 'match_user_bloc.dart';

abstract class MatchUserState extends Equatable {
  const MatchUserState();

  @override
  List<Object?> get props => [];
}

class MatchUserInitial extends MatchUserState {}

class MatchUserLoadingState extends MatchUserState {}

class MatchUserLoadedState extends MatchUserState {

  const MatchUserLoadedState(this.users);
  final List<UserModel> users;

  @override
  List<Object?> get props => [users];
}

class MatchUserFailedState extends MatchUserState {}
