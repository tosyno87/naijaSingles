import 'dart:developer';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hookup4u2/models/user_model.dart';

import '../../../common/data/repo/user_search_repo.dart';

part 'searchuser_event.dart';
part 'searchuser_state.dart';

class SearchUserBloc extends Bloc<SearchUserEvent, SearchUserState> {
  SearchUserBloc() : super(SearchuserInitial()) {
    on<LoadUserEvent>((event, emit) async {
      emit(SearchUserLoadingState());
      try {
        log("called for map false");
        List<UserModel> userList =
            await UserSearchRepo.getUserList(event.currentUser);
        emit(SearchUserLoadUserState(userList));
      } catch (e) {
        emit(SearchUserFailedState());
        rethrow;
      }
    });
  }
}
