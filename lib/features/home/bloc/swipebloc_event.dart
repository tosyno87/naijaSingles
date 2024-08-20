part of 'swipebloc_bloc.dart';

abstract class SwipeblocEvent extends Equatable {
  const SwipeblocEvent();

  @override
  List<Object> get props => [];
}

class RightSwipeEvent extends SwipeblocEvent {
  final UserModel currentUser, selectedUser;

  const RightSwipeEvent(
      {required this.currentUser, required this.selectedUser});

  @override
  List<Object> get props => [currentUser, selectedUser];
}

class LeftSwipeEvent extends SwipeblocEvent {
  final UserModel currentUser, selectedUser;

  const LeftSwipeEvent({required this.currentUser, required this.selectedUser});

  @override
  List<Object> get props => [currentUser, selectedUser];
}
