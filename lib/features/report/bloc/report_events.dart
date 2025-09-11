import 'package:equatable/equatable.dart';

abstract class ReportEvents extends Equatable {
  const ReportEvents();

  @override
  List<Object> get props => [];
}

class ReportUserRequest extends ReportEvents {
  final String reported;
  final String reportedBy;
  final String reason;
  final String? moreReason;

  const ReportUserRequest({
    required this.moreReason,
    required this.reported,
    required this.reportedBy,
    required this.reason,
  });

  @override
  List<Object> get props =>
      [reported, reportedBy, reason, if (moreReason != null) moreReason!];
}
