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
  final List<MatchModel> matches;

  const MatchesLoaded({required this.matches});

  @override
  List<Object?> get props => [matches];
}

class LikeProcessing extends MatchState {
  final String toUserId;

  const LikeProcessing({required this.toUserId});

  @override
  List<Object?> get props => [toUserId];
}

class LikeSuccess extends MatchState {
  final String toUserId;
  final bool isMatch;
  final String? matchId;

  const LikeSuccess({
    required this.toUserId,
    required this.isMatch,
    this.matchId,
  });

  @override
  List<Object?> get props => [toUserId, isMatch, matchId];
}

class MatchCreated extends MatchState {
  final String matchId;
  final String otherUserId;
  final String? chatThreadId;

  const MatchCreated({
    required this.matchId,
    required this.otherUserId,
    this.chatThreadId,
  });

  @override
  List<Object?> get props => [matchId, otherUserId, chatThreadId];
}

class MatchError extends MatchState {
  final String message;

  const MatchError({required this.message});

  @override
  List<Object?> get props => [message];
}

class UnlikeSuccess extends MatchState {
  final String toUserId;

  const UnlikeSuccess({required this.toUserId});

  @override
  List<Object?> get props => [toUserId];
}

class MatchDeleted extends MatchState {
  final String matchId;

  const MatchDeleted({required this.matchId});

  @override
  List<Object?> get props => [matchId];
}
