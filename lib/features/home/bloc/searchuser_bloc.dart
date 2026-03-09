import 'dart:async';
import 'dart:developer';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../features/discovery/data/services/discovery_service.dart';
import '../../../features/match/data/analytics/match_quality_reporter.dart';
import '../../../models/user_model.dart';

part 'searchuser_event.dart';
part 'searchuser_state.dart';

class SearchUserBloc extends Bloc<SearchUserEvent, SearchUserState> {
  SearchUserBloc() : super(SearchuserInitial()) {
    on<LoadUserEvent>((event, emit) async {
      emit(SearchUserLoadingState());
      final discoverLoadTimer = Stopwatch()..start();
      try {
        log('🔍 Loading users with privacy awareness');

        // Use privacy-aware discovery service, applying the user's onboarding
        // intent (lookingFor) so results match what they selected.
        final List<UserModel> userList =
            await DiscoveryService.getUsersForDiscovery(
          event.currentUser,
          intentFilter: event.currentUser.lookingFor,
        );
        discoverLoadTimer.stop();

        final currentUserId = event.currentUser.id;
        final mode = event.currentUser.lookingFor ?? 'Dating';
        if (currentUserId != null) {
          unawaited(
            MatchQualityReporter.instance.recordLatency(
              operation: 'discover_list_load',
              latencyMs: discoverLoadTimer.elapsedMilliseconds,
              mode: mode,
              userId: currentUserId,
            ),
          );
          for (var index = 0; index < userList.length; index++) {
            final candidateId = userList[index].id;
            if (candidateId == null) {
              continue;
            }
            unawaited(
              MatchQualityReporter.instance.recordImpression(
                userId: currentUserId,
                candidateId: candidateId,
                mode: mode,
                scoreSnapshot: <String, double>{
                  'rank': (index + 1).toDouble(),
                },
                distanceMiles: userList[index].distanceBW?.toDouble(),
              ),
            );
          }
        }

        // Get discovery stats for debugging
        final stats =
            await DiscoveryService.getDiscoveryStats(event.currentUser);
        log('📊 Discovery stats: $stats');

        emit(SearchUserLoadUserState(userList));
      } on Object catch (e) {
        discoverLoadTimer.stop();
        emit(SearchUserFailedState());
        log('❌ Error loading users: $e');
      }
    });

    // Add new event for nearby users
    on<LoadNearbyUsersEvent>((event, emit) async {
      emit(SearchUserLoadingState());
      try {
        log('🗺️ Loading nearby users within ${event.radiusMiles} miles');

        final List<UserModel> userList = await DiscoveryService.getNearbyUsers(
          event.currentUser,
          event.radiusMiles,
        );

        emit(SearchUserLoadUserState(userList));
      } on Object catch (e) {
        emit(SearchUserFailedState());
        log('❌ Error loading nearby users: $e');
      }
    });

    // Add event for checking migration status
    on<CheckMigrationStatusEvent>((event, emit) async {
      try {
        final shouldPrompt =
            await DiscoveryService.shouldPromptForMigration(event.userId);
        emit(MigrationStatusState(shouldPromptForMigration: shouldPrompt));
      } on Object catch (e) {
        log('❌ Error checking migration status: $e');
        emit(SearchUserFailedState());
      }
    });
  }
}
