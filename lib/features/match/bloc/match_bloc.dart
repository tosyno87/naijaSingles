import 'dart:developer';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:naijasingles/common/data/repo/user_messaging_repo.dart';

import '../../../models/user_model.dart';

part 'match_event.dart';
part 'match_state.dart';

class MatchUserBloc extends Bloc<MatchUserEvent, MatchUserState> {
  final Future<List<UserModel>> Function(UserModel currentUser) getMatches;

  MatchUserBloc({
    Future<List<UserModel>> Function(UserModel currentUser)? getMatches,
  })  : getMatches = getMatches ?? UserMessagingRepo.getMatches,
        super(MatchUserInitial()) {
    on<LoadMatchUserEvent>((event, emit) async {
      emit(MatchUserLoadingState());
      try {
        final matchList = await this.getMatches(event.currentUser);
        log("matchuser${matchList.toString()}");
        log("matchuser from matchbloc");
        emit(MatchUserLoadedState(matchList));
      } catch (e) {
        emit(MatchUserFailedState());
        log('Error loading matches: $e');
      }
    });
  }
}
