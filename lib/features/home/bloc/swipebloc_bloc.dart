import 'dart:developer';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../common/data/repo/user_search_repo.dart';
import '../../../models/user_model.dart';
import '../../match/services/match_service.dart';

part 'swipebloc_event.dart';
part 'swipebloc_state.dart';

class SwipeBloc extends Bloc<SwipeblocEvent, SwipeblocState> {
  final Future<void> Function(UserModel, UserModel) leftSwipe;
  final Future<void> Function(UserModel, UserModel) rightSwipe;
  final Future<List<UserModel>> Function(UserModel) getUserList;
  final MatchService _matchService;

  SwipeBloc({
    Future<void> Function(UserModel, UserModel)? leftSwipe,
    Future<void> Function(UserModel, UserModel)? rightSwipe,
    Future<List<UserModel>> Function(UserModel)? getUserList,
    MatchService? matchService,
  })  : leftSwipe = leftSwipe ?? UserSearchRepo.leftSwipe,
        rightSwipe = rightSwipe ?? UserSearchRepo.rightSwipe,
        getUserList = getUserList ?? UserSearchRepo.getUserList,
        _matchService = matchService ?? MatchService(),
        super(SwipeblocInitial()) {
    on<LeftSwipeEvent>((event, emit) async {
      try {
        await this.leftSwipe(event.currentUser, event.selectedUser);
        List<UserModel> userList =
            await this.getUserList(event.currentUser);
        emit(SwipeSucessState(userList));

        log("afterlefteventuser${userList.toString()}");
        log("cominguser from leftevent");
      } catch (e) {
        emit(SwipeFailedState());
        log('Error while processing left swipe: $e');
      }
    });
    
    on<RightSwipeEvent>((event, emit) async {
      try {
        // Check if this will create a match
        final selectedUserId = event.selectedUser.id;
        bool hasAlreadyLiked = false;
        
        if (selectedUserId != null) {
          hasAlreadyLiked = await _matchService.hasUserLiked(selectedUserId);
        }
        
        await this.rightSwipe(event.currentUser, event.selectedUser);
        
        List<UserModel> userList =
            await this.getUserList(event.currentUser);

        // Check if a match was created by looking for mutual likes
        final usersWhoLikedMe = await _matchService.getUsersWhoLikedMe();
        final isMatch = selectedUserId != null && 
                       usersWhoLikedMe.contains(selectedUserId) && 
                       !hasAlreadyLiked;

        if (isMatch) {
          // Emit match state
          emit(SwipeMatchCreatedState(
            users: userList,
            matchedUser: event.selectedUser,
          ));
        } else {
          emit(SwipeSucessState(userList));
        }

        log("afterrighteventuser${userList.toString()}");
        log("cominguser from rightevent");
      } catch (e) {
        emit(SwipeFailedState());
        log('Error while processing right swipe: $e');
      }
    });
  }
}
