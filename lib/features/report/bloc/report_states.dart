import 'package:equatable/equatable.dart';

abstract class ReportStates extends Equatable {
  const ReportStates();

  @override
  List<Object> get props => [];
}

class ReportUserInitial extends ReportStates {}

class ReportUserLoading extends ReportStates {}

class ReportUserSuccess extends ReportStates {
  final String message;

  const ReportUserSuccess({required this.message});

  @override
  List<Object> get props => [message];
}

class ReportUserFailed extends ReportStates {
  final String message;

  const ReportUserFailed({required this.message});

  @override
  List<Object> get props => [message];
}
