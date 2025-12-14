part of 'swipebloc_bloc.dart';

abstract class SwipeblocState extends Equatable {
  const SwipeblocState();

  @override
  List<Object> get props => [];
}

class SwipeblocInitial extends SwipeblocState {}

class SwipeFailedState extends SwipeblocState {}

class SwipeSucessState extends SwipeblocState {

  const SwipeSucessState(this.users);
  final List<UserModel> users;

  @override
  List<Object> get props => [users];
}

class SwipeMatchCreatedState extends SwipeblocState {

  const SwipeMatchCreatedState({
    required this.users,
    required this.matchedUser,
  });
  final List<UserModel> users;
  final UserModel matchedUser;

  @override
  List<Object> get props => [users, matchedUser];
}
