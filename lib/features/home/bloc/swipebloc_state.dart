part of 'swipebloc_bloc.dart';

abstract class SwipeblocState extends Equatable {
  const SwipeblocState();

  @override
  List<Object> get props => [];
}

class SwipeblocInitial extends SwipeblocState {}

class SwipeFailedState extends SwipeblocState {}

class SwipeSucessState extends SwipeblocState {
  final List<UserModel> users;

  const SwipeSucessState(this.users);

  @override
  List<Object> get props => [users];
}
