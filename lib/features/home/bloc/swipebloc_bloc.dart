import 'dart:developer';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../common/data/repo/user_search_repo.dart';
import '../../../models/user_model.dart';

part 'swipebloc_event.dart';
part 'swipebloc_state.dart';

class SwipeBloc extends Bloc<SwipeblocEvent, SwipeblocState> {
  SwipeBloc({
    Future<void> Function(UserModel, UserModel)? leftSwipe,
    Future<String?> Function(UserModel, UserModel)? rightSwipe,
    Future<List<UserModel>> Function(UserModel)? getUserList,
  })  : leftSwipe = leftSwipe ?? UserSearchRepo.leftSwipe,
        rightSwipe = rightSwipe ?? UserSearchRepo.rightSwipe,
        getUserList = getUserList ?? UserSearchRepo.getUserList,
        super(SwipeblocInitial()) {
    on<LeftSwipeEvent>((event, emit) async {
      try {
        await this.leftSwipe(event.currentUser, event.selectedUser);
        final List<UserModel> userList =
            await this.getUserList(event.currentUser);
        emit(SwipeSucessState(userList));

        log('afterlefteventuser${userList.toString()}');
        log('cominguser from leftevent');
      } catch (e) {
        emit(SwipeFailedState());
        log('Error while processing left swipe: $e');
      }
    });

    on<RightSwipeEvent>((event, emit) async {
      try {
        final matchId =
            await this.rightSwipe(event.currentUser, event.selectedUser);

        final List<UserModel> userList =
            await this.getUserList(event.currentUser);

        if (matchId != null) {
          // Emit match state
          emit(
            SwipeMatchCreatedState(
              users: userList,
              matchedUser: event.selectedUser,
            ),
          );
        } else {
          emit(SwipeSucessState(userList));
        }

        log('afterrighteventuser${userList.toString()}');
        log('cominguser from rightevent');
      } catch (e) {
        emit(SwipeFailedState());
        log('Error while processing right swipe: $e');
      }
    });
  }
  final Future<void> Function(UserModel, UserModel) leftSwipe;
  final Future<String?> Function(UserModel, UserModel) rightSwipe;
  final Future<List<UserModel>> Function(UserModel) getUserList;
}
