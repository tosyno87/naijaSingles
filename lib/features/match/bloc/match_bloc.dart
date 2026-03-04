import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/services/likes_service.dart';
import '../data/services/match_service.dart';
import '../models/match_model.dart';

part 'match_event.dart';
part 'match_state.dart';

class MatchBloc extends Bloc<MatchEvent, MatchState> {
  MatchBloc({
    MatchService? matchService,
    LikesService? likesService,
  })  : _matchService = matchService ?? MatchService(),
        _likesService = likesService ?? LikesService(),
        super(const MatchInitial()) {
    on<LikeUserEvent>(_onLikeUser);
    on<LoadMatchesEvent>(_onLoadMatches);
    on<MatchCreatedEvent>(_onMatchCreated);
    on<DismissMatchNotificationEvent>(_onDismissMatchNotification);
    on<UnlikeUserEvent>(_onUnlikeUser);
    on<DeleteMatchEvent>(_onDeleteMatch);
  }
  final MatchService _matchService;
  final LikesService _likesService;

  Future<void> _onLikeUser(
    LikeUserEvent event,
    Emitter<MatchState> emit,
  ) async {
    try {
      emit(LikeProcessing(toUserId: event.toUserId));

      final matchId = await _matchService.handleLike(event.toUserId);

      if (matchId != null) {
        // It's a match!
        final match = await _likesService.getMatchById(matchId);
        emit(
          LikeSuccess(
            toUserId: event.toUserId,
            isMatch: true,
            matchId: matchId,
          ),
        );

        // Emit match created state for UI animations/notifications
        emit(
          MatchCreated(
            matchId: matchId,
            otherUserId: event.toUserId,
            chatThreadId: match?.chatThreadId,
          ),
        );
      } else {
        // Just a like, no match yet
        emit(
          LikeSuccess(
            toUserId: event.toUserId,
            isMatch: false,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error liking user: $e');
      emit(MatchError(message: 'Failed to like user: ${e.toString()}'));
    }
  }

  Future<void> _onLoadMatches(
    LoadMatchesEvent event,
    Emitter<MatchState> emit,
  ) async {
    try {
      emit(const MatchLoading());

      final matches = await _matchService.getUserMatches();
      emit(MatchesLoaded(matches: matches));
    } catch (e) {
      debugPrint('Error loading matches: $e');
      emit(MatchError(message: 'Failed to load matches: ${e.toString()}'));
    }
  }

  Future<void> _onMatchCreated(
    MatchCreatedEvent event,
    Emitter<MatchState> emit,
  ) async {
    try {
      final match = await _likesService.getMatchById(event.matchId);
      emit(
        MatchCreated(
          matchId: event.matchId,
          otherUserId: event.otherUserId,
          chatThreadId: match?.chatThreadId,
        ),
      );
    } catch (e) {
      debugPrint('Error handling match created: $e');
      emit(MatchError(message: 'Failed to handle match: ${e.toString()}'));
    }
  }

  Future<void> _onDismissMatchNotification(
    DismissMatchNotificationEvent event,
    Emitter<MatchState> emit,
  ) async {
    // Return to initial state or previous state
    emit(const MatchInitial());
  }

  Future<void> _onUnlikeUser(
    UnlikeUserEvent event,
    Emitter<MatchState> emit,
  ) async {
    try {
      final currentUserId = _likesService.currentUserId;
      if (currentUserId == null) {
        emit(const MatchError(message: 'No user logged in'));
        return;
      }

      final success =
          await _likesService.removeLike(currentUserId, event.toUserId);

      if (success) {
        emit(UnlikeSuccess(toUserId: event.toUserId));
      } else {
        emit(const MatchError(message: 'Failed to unlike user'));
      }
    } catch (e) {
      debugPrint('Error unliking user: $e');
      emit(MatchError(message: 'Failed to unlike user: ${e.toString()}'));
    }
  }

  Future<void> _onDeleteMatch(
    DeleteMatchEvent event,
    Emitter<MatchState> emit,
  ) async {
    try {
      final success = await _matchService.deleteMatch(event.matchId);

      if (success) {
        emit(MatchDeleted(matchId: event.matchId));
        // Reload matches after deletion
        add(const LoadMatchesEvent());
      } else {
        emit(const MatchError(message: 'Failed to delete match'));
      }
    } catch (e) {
      debugPrint('Error deleting match: $e');
      emit(MatchError(message: 'Failed to delete match: ${e.toString()}'));
    }
  }
}
