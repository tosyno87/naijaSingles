part of 'swipebloc_bloc.dart';

abstract class SwipeblocEvent extends Equatable {
  const SwipeblocEvent();

  @override
  List<Object> get props => [];
}

class RightSwipeEvent extends SwipeblocEvent {
  const RightSwipeEvent({
    required this.currentUser,
    required this.selectedUser,
  });
  final UserModel currentUser;
  final UserModel selectedUser;

  @override
  List<Object> get props => [currentUser, selectedUser];
}

class LeftSwipeEvent extends SwipeblocEvent {
  const LeftSwipeEvent({required this.currentUser, required this.selectedUser});
  final UserModel currentUser;
  final UserModel selectedUser;

  @override
  List<Object> get props => [currentUser, selectedUser];
}
