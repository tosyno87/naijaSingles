part of 'match_bloc.dart';

abstract class MatchEvent extends Equatable {
  const MatchEvent();

  @override
  List<Object?> get props => [];
}

class LikeUserEvent extends MatchEvent {
  final String toUserId;
  
  const LikeUserEvent({required this.toUserId});
  
  @override
  List<Object?> get props => [toUserId];
}

class LoadMatchesEvent extends MatchEvent {
  const LoadMatchesEvent();
}

class MatchCreatedEvent extends MatchEvent {
  final String matchId;
  final String otherUserId;
  
  const MatchCreatedEvent({
    required this.matchId,
    required this.otherUserId,
  });
  
  @override
  List<Object?> get props => [matchId, otherUserId];
}

class DismissMatchNotificationEvent extends MatchEvent {
  const DismissMatchNotificationEvent();
}

class UnlikeUserEvent extends MatchEvent {
  final String toUserId;
  
  const UnlikeUserEvent({required this.toUserId});
  
  @override
  List<Object?> get props => [toUserId];
}

class DeleteMatchEvent extends MatchEvent {
  final String matchId;
  
  const DeleteMatchEvent({required this.matchId});
  
  @override
  List<Object?> get props => [matchId];
}
