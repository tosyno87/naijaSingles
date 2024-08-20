// ignore_for_file: annotate_overrides

part of 'userlocation_bloc.dart';

abstract class UserLocationEvents extends Equatable {
  const UserLocationEvents();

  @override
  List<Object> get props => [];
}

class UserLocationRequest extends UserLocationEvents {
  const UserLocationRequest();

  List<Object> get props => [];
}

abstract class UserlocationEvent extends Equatable {
  const UserlocationEvent();

  @override
  List<Object> get props => [];
}
