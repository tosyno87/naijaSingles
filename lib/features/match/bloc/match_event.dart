part of 'match_bloc.dart';

abstract class MatchEvent extends Equatable {
  const MatchEvent();

  @override
  List<Object?> get props => [];
}

class LikeUserEvent extends MatchEvent {
  const LikeUserEvent({required this.toUserId});
  final String toUserId;

  @override
  List<Object?> get props => [toUserId];
}

class LoadMatchesEvent extends MatchEvent {
  const LoadMatchesEvent();
}

class MatchCreatedEvent extends MatchEvent {
  const MatchCreatedEvent({
    required this.matchId,
    required this.otherUserId,
  });
  final String matchId;
  final String otherUserId;

  @override
  List<Object?> get props => [matchId, otherUserId];
}

class DismissMatchNotificationEvent extends MatchEvent {
  const DismissMatchNotificationEvent();
}

class UnlikeUserEvent extends MatchEvent {
  const UnlikeUserEvent({required this.toUserId});
  final String toUserId;

  @override
  List<Object?> get props => [toUserId];
}

class DeleteMatchEvent extends MatchEvent {
  const DeleteMatchEvent({required this.matchId});
  final String matchId;

  @override
  List<Object?> get props => [matchId];
}
