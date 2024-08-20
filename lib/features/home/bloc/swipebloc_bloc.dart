import 'dart:developer';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../common/data/repo/user_search_repo.dart';
import '../../../models/user_model.dart';

part 'swipebloc_event.dart';
part 'swipebloc_state.dart';

class SwipeBloc extends Bloc<SwipeblocEvent, SwipeblocState> {
  SwipeBloc() : super(SwipeblocInitial()) {
    on<LeftSwipeEvent>((event, emit) async {
      // emit(SearchUserLoadingState());
      try {
        UserSearchRepo.leftSwipe(event.currentUser, event.selectedUser);
        List<UserModel> userList =
            await UserSearchRepo.getUserList(event.currentUser);
        emit(SwipeSucessState(userList));

        log("afterlefteventuser${userList.toString()}");
        log("cominguser from leftevent");
      } catch (e) {
        emit(SwipeFailedState());
        rethrow;
      }
    });
    on<RightSwipeEvent>((event, emit) async {
      // emit(SearchUserLoadingState());
      try {
        UserSearchRepo.rightSwipe(event.currentUser, event.selectedUser);
        List<UserModel> userList =
            await UserSearchRepo.getUserList(event.currentUser);

        emit(SwipeSucessState(userList));
        log("afterrighteventuser${userList.toString()}");
        log("cominguser from rightevent");
      } catch (e) {
        emit(SwipeFailedState());
        rethrow;
      }
    });
  }
}
