import 'dart:developer';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../common/data/repo/user_search_repo.dart';
import '../../../models/user_model.dart';

part 'swipebloc_event.dart';
part 'swipebloc_state.dart';

class SwipeBloc extends Bloc<SwipeblocEvent, SwipeblocState> {
  final Future<void> Function(UserModel, UserModel) leftSwipe;
  final Future<void> Function(UserModel, UserModel) rightSwipe;
  final Future<List<UserModel>> Function(UserModel) getUserList;

  SwipeBloc({
    Future<void> Function(UserModel, UserModel)? leftSwipe,
    Future<void> Function(UserModel, UserModel)? rightSwipe,
    Future<List<UserModel>> Function(UserModel)? getUserList,
  })  : leftSwipe = leftSwipe ?? UserSearchRepo.leftSwipe,
        rightSwipe = rightSwipe ?? UserSearchRepo.rightSwipe,
        getUserList = getUserList ?? UserSearchRepo.getUserList,
        super(SwipeblocInitial()) {
    on<LeftSwipeEvent>((event, emit) async {
      // emit(SearchUserLoadingState());
      try {
        await this.leftSwipe(event.currentUser, event.selectedUser);
        List<UserModel> userList =
            await this.getUserList(event.currentUser);
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
        await this.rightSwipe(event.currentUser, event.selectedUser);
        List<UserModel> userList =
            await this.getUserList(event.currentUser);

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
