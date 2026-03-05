import 'dart:developer';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../common/data/repo/explore_map_repo.dart';
import '../../../models/user_model.dart';

part 'explore_map_event.dart';
part 'explore_map_states.dart';

class SearchUserForMapBloc
    extends Bloc<SearchUserForMapEvent, SearchUserForMapState> {
  SearchUserForMapBloc() : super(SearchuserForMapInitial()) {
    on<LoadUserForMapEvent>((event, emit) async {
      emit(SearchUserLoadingForMapState());
      try {
        log('called for map true');
        final List<UserModel> userList =
            await ExploreMap.getUserListForMap(event.currentUser);
        emit(SearchUserLoadUserForMapState(userList));
      } on Object catch (e) {
        emit(SearchUserFailedForMapState());
        log('Error loading map users: $e');
      }
    });
  }
}
