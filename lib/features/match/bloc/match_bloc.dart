import 'dart:developer';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hookup4u2/common/data/repo/user_messaging_repo.dart';

import '../../../models/user_model.dart';

part 'match_event.dart';
part 'match_state.dart';

class MatchUserBloc extends Bloc<MatchUserEvent, MatchUserState> {
  MatchUserBloc() : super(MatchUserInitial()) {
    on<LoadMatchUserEvent>((event, emit) async {
      emit(MatchUserLoadingState());
      try {
        List<UserModel> matchList =
            await UserMessagingRepo.getMatches(event.currentUser);
        log("matchuser${matchList.toString()}");
        log("matchuser from matchbloc");
        emit(MatchUserLoadedState(matchList));
      } catch (e) {
        emit(MatchUserFailedState());
        rethrow;
      }
    });
  }
}
