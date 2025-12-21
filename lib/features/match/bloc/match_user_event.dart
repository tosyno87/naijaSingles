part of 'match_user_bloc.dart';

abstract class MatchUserEvent extends Equatable {
  const MatchUserEvent();

  @override
  List<Object?> get props => [];
}

class LoadMatchUserEvent extends MatchUserEvent {
  const LoadMatchUserEvent({required this.currentUser});
  final UserModel currentUser;

  @override
  List<Object?> get props => [currentUser];
}
