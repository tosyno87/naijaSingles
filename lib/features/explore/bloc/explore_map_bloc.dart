import 'dart:developer';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hookup4u2/models/user_model.dart';

import '../../../common/data/repo/explore_map_repo.dart';

part 'explore_map_event.dart';
part 'explore_map_states.dart';

class SearchUserForMapBloc
    extends Bloc<SearchUserForMapEvent, SearchUserForMapState> {
  SearchUserForMapBloc() : super(SearchuserForMapInitial()) {
    on<LoadUserForMapEvent>((event, emit) async {
      emit(SearchUserLoadingForMapState());
      try {
        log("called for map true");
        List<UserModel> userList =
            await ExploreMap.getUserListForMap(event.currentUser);
        emit(SearchUserLoadUserForMapState(userList));
      } catch (e) {
        emit(SearchUserFailedForMapState());
        rethrow;
      }
    });
  }
}
