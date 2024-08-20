import 'dart:developer';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hookup4u2/common/data/repo/user_repo.dart';

import '../../../models/user_model.dart';

part 'streetviewdata_event.dart';
part 'streetviewdata_state.dart';

class StreetviewdataBloc
    extends Bloc<StreetviewdataEvent, StreetviewdataState> {
  StreetviewdataBloc() : super(StreetviewdataInitial()) {
    on<LoadStreetViewDataEvent>((event, emit) async {
      emit(StreetViewDataLoadingState());
      try {
        Map<String, dynamic> streetViewData =
            await UserRepo.getStreetViewData(event.user.id!);
        log("matchuser${streetViewData.toString()}");
        List<dynamic> userIds = streetViewData['userIds'];
        List<String> stringUserIds =
            userIds.map((userId) => userId.toString()).toList();
        String option = streetViewData['option'];
        log("matchuser $userIds");

        emit(StreetViewDataLoadedState(stringUserIds, option));
      } catch (e) {
        emit(StreetViewDataFailedState());
        rethrow;
      }
    });
  }
}
