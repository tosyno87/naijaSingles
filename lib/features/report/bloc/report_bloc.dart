import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../common/data/repo/report_user.dart';
import './report_events.dart';
import './report_states.dart';

class ReportBloc extends Bloc<ReportEvents, ReportStates> {
  ReportBloc() : super(ReportUserInitial()) {
    on<ReportUserRequest>((event, emit) async {
      emit(ReportUserLoading());
      try {
        await ReportRepositoryImpl().reportUser(
            reason: event.reason,
            moreReason: event.moreReason,
            reported: event.reported,
            reportedBy: event.reportedBy);
        emit(const ReportUserSuccess(message: "User Reported"));
      } catch (e) {
        emit(ReportUserFailed(message: e.toString()));
        rethrow;
      }
    });
  }
}
