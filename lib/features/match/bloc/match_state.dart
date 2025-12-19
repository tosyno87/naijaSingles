part of 'match_bloc.dart';

abstract class MatchState extends Equatable {
  const MatchState();

  @override
  List<Object?> get props => [];
}

class MatchInitial extends MatchState {
  const MatchInitial();
}

class MatchLoading extends MatchState {
  const MatchLoading();
}

class MatchesLoaded extends MatchState {
  const MatchesLoaded({required this.matches});
  final List<MatchModel> matches;

  @override
  List<Object?> get props => [matches];
}

class LikeProcessing extends MatchState {
  const LikeProcessing({required this.toUserId});
  final String toUserId;

  @override
  List<Object?> get props => [toUserId];
}

class LikeSuccess extends MatchState {
  const LikeSuccess({
    required this.toUserId,
    required this.isMatch,
    this.matchId,
  });
  final String toUserId;
  final bool isMatch;
  final String? matchId;

  @override
  List<Object?> get props => [toUserId, isMatch, matchId];
}

class MatchCreated extends MatchState {
  const MatchCreated({
    required this.matchId,
    required this.otherUserId,
    this.chatThreadId,
  });
  final String matchId;
  final String otherUserId;
  final String? chatThreadId;

  @override
  List<Object?> get props => [matchId, otherUserId, chatThreadId];
}

class MatchError extends MatchState {
  const MatchError({required this.message});
  final String message;

  @override
  List<Object?> get props => [message];
}

class UnlikeSuccess extends MatchState {
  const UnlikeSuccess({required this.toUserId});
  final String toUserId;

  @override
  List<Object?> get props => [toUserId];
}

class MatchDeleted extends MatchState {
  const MatchDeleted({required this.matchId});
  final String matchId;

  @override
  List<Object?> get props => [matchId];
}
