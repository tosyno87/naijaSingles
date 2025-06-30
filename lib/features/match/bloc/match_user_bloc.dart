import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

import '../../../models/user_model.dart';

part 'match_user_event.dart';
part 'match_user_state.dart';

class MatchUserBloc extends Bloc<MatchUserEvent, MatchUserState> {
  final Future<List<UserModel>> Function(UserModel) getMatches;

  MatchUserBloc({
    required this.getMatches,
  }) : super(MatchUserInitial()) {
    on<LoadMatchUserEvent>(_onLoadMatchUser);
  }

  Future<void> _onLoadMatchUser(
    LoadMatchUserEvent event,
    Emitter<MatchUserState> emit,
  ) async {
    try {
      emit(MatchUserLoadingState());
      
      final matches = await getMatches(event.currentUser);
      
      emit(MatchUserLoadedState(matches));
    } catch (e) {
      debugPrint('Error loading matches: $e');
      emit(MatchUserFailedState());
    }
  }
}
