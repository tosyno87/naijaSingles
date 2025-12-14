part of 'userfilter_bloc.dart';

abstract class UserfilterEvent extends Equatable {
  const UserfilterEvent();

  @override
  List<Object> get props => [];
}

class ChangefilterRequest extends UserfilterEvent {

  const ChangefilterRequest({
    required this.details,
  });
  final Map<String, dynamic> details;

  @override
  List<Object> get props => [details];
}

// for location change in filter.currently not in used

class ChangelocationRequest extends UserfilterEvent {

  const ChangelocationRequest({
    required this.details,
  });
  final Map<String, dynamic> details;

  @override
  List<Object> get props => [details];
}
