import 'dart:async';
import 'dart:developer';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../common/data/repo/user_search_repo.dart';
import '../../../features/match/data/analytics/match_quality_event.dart';
import '../../../features/match/data/analytics/match_quality_reporter.dart';
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
      final actionTimer = Stopwatch()..start();
      try {
        await this.leftSwipe(event.currentUser, event.selectedUser);
        actionTimer.stop();
        final List<UserModel> userList =
            await this.getUserList(event.currentUser);
        emit(SwipeSucessState(userList));

        final userId = event.currentUser.id;
        final candidateId = event.selectedUser.id;
        final mode = event.currentUser.lookingFor ?? 'Dating';
        if (userId != null && candidateId != null) {
          unawaited(
            MatchQualityReporter.instance.recordAction(
              userId: userId,
              candidateId: candidateId,
              mode: mode,
              actionType: MatchQualityActionType.pass,
              distanceMiles: event.selectedUser.distanceBW?.toDouble(),
            ),
          );
          unawaited(
            MatchQualityReporter.instance.recordLatency(
              operation: 'pass_action',
              latencyMs: actionTimer.elapsedMilliseconds,
              mode: mode,
              userId: userId,
              candidateId: candidateId,
            ),
          );
        }

        log('afterlefteventuser${userList.toString()}');
        log('cominguser from leftevent');
      } on Object catch (e) {
        actionTimer.stop();
        emit(SwipeFailedState());
        log('Error while processing left swipe: $e');
      }
    });

    on<RightSwipeEvent>((event, emit) async {
      final actionTimer = Stopwatch()..start();
      try {
        final matchId =
            await this.rightSwipe(event.currentUser, event.selectedUser);
        actionTimer.stop();

        final List<UserModel> userList =
            await this.getUserList(event.currentUser);

        final userId = event.currentUser.id;
        final candidateId = event.selectedUser.id;
        final mode = event.currentUser.lookingFor ?? 'Dating';
        if (userId != null && candidateId != null) {
          unawaited(
            MatchQualityReporter.instance.recordAction(
              userId: userId,
              candidateId: candidateId,
              mode: mode,
              actionType: MatchQualityActionType.connect,
              distanceMiles: event.selectedUser.distanceBW?.toDouble(),
            ),
          );
          unawaited(
            MatchQualityReporter.instance.recordLatency(
              operation: 'connect_action',
              latencyMs: actionTimer.elapsedMilliseconds,
              mode: mode,
              userId: userId,
              candidateId: candidateId,
            ),
          );
          if (matchId != null) {
            unawaited(
              MatchQualityReporter.instance.recordMatch(
                userId: userId,
                candidateId: candidateId,
                mode: mode,
              ),
            );
          }
        }

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
      } on Object catch (e) {
        actionTimer.stop();
        emit(SwipeFailedState());
        log('Error while processing right swipe: $e');
      }
    });
  }
  final Future<void> Function(UserModel, UserModel) leftSwipe;
  final Future<String?> Function(UserModel, UserModel) rightSwipe;
  final Future<List<UserModel>> Function(UserModel) getUserList;
}
