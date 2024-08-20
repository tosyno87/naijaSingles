part of 'userfilter_bloc.dart';

abstract class UserfilterEvent extends Equatable {
  const UserfilterEvent();

  @override
  List<Object> get props => [];
}

class ChangefilterRequest extends UserfilterEvent {
  final Map<String, dynamic> details;

  const ChangefilterRequest({
    required this.details,
  });

  @override
  List<Object> get props => [details];
}

// for location change in filter.currently not in used

class ChangelocationRequest extends UserfilterEvent {
  final Map<String, dynamic> details;

  const ChangelocationRequest({
    required this.details,
  });

  @override
  List<Object> get props => [details];
}
