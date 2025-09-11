import 'dart:developer';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:naijasingles/models/user_model.dart';

import '../../../services/discovery_service.dart';

part 'searchuser_event.dart';
part 'searchuser_state.dart';

class SearchUserBloc extends Bloc<SearchUserEvent, SearchUserState> {
  SearchUserBloc() : super(SearchuserInitial()) {
    on<LoadUserEvent>((event, emit) async {
      emit(SearchUserLoadingState());
      try {
        log("🔍 Loading users with privacy awareness");

        // Use privacy-aware discovery service
        List<UserModel> userList =
            await DiscoveryService.getUsersForDiscovery(event.currentUser);

        // Get discovery stats for debugging
        final stats =
            await DiscoveryService.getDiscoveryStats(event.currentUser);
        log("📊 Discovery stats: $stats");

        emit(SearchUserLoadUserState(userList));
      } catch (e) {
        emit(SearchUserFailedState());
        log('❌ Error loading users: $e');
      }
    });

    // Add new event for nearby users
    on<LoadNearbyUsersEvent>((event, emit) async {
      emit(SearchUserLoadingState());
      try {
        log("🗺️ Loading nearby users within ${event.radiusMiles} miles");

        List<UserModel> userList = await DiscoveryService.getNearbyUsers(
            event.currentUser, event.radiusMiles);

        emit(SearchUserLoadUserState(userList));
      } catch (e) {
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
      } catch (e) {
        log('❌ Error checking migration status: $e');
        emit(SearchUserFailedState());
      }
    });
  }
}
