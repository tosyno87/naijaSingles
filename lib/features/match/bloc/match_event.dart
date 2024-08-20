part of 'match_bloc.dart';

abstract class MatchUserEvent extends Equatable {
  const MatchUserEvent();

  @override
  List<Object> get props => [];
}

class LoadMatchUserEvent extends MatchUserEvent {
  final UserModel currentUser;

  const LoadMatchUserEvent({required this.currentUser});

  @override
  List<Object> get props => [currentUser];
}
