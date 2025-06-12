import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naijasingles/features/home/bloc/swipebloc_bloc.dart';
import 'package:naijasingles/models/user_model.dart';

void main() {
  group('SwipeBloc', () {
    final currentUser = UserModel(id: '1');
    final selectedUser = UserModel(id: '2');
    final list = [UserModel(id: '3')];

    blocTest<SwipeBloc, SwipeblocState>(
      'emits success after right swipe',
      build: () => SwipeBloc(
        rightSwipe: (_, __) async {},
        getUserList: (_) async => list,
        leftSwipe: (_, __) async {},
      ),
      act: (bloc) => bloc.add(RightSwipeEvent(currentUser: currentUser, selectedUser: selectedUser)),
      expect: () => [SwipeSucessState(list)],
    );

    blocTest<SwipeBloc, SwipeblocState>(
      'emits success after left swipe',
      build: () => SwipeBloc(
        leftSwipe: (_, __) async {},
        getUserList: (_) async => list,
        rightSwipe: (_, __) async {},
      ),
      act: (bloc) => bloc.add(LeftSwipeEvent(currentUser: currentUser, selectedUser: selectedUser)),
      expect: () => [SwipeSucessState(list)],
    );

    blocTest<SwipeBloc, SwipeblocState>(
      'emits failed state on exception',
      build: () => SwipeBloc(
        rightSwipe: (_, __) => throw Exception(),
        getUserList: (_) async => [],
        leftSwipe: (_, __) async {},
      ),
      act: (bloc) => bloc.add(RightSwipeEvent(currentUser: currentUser, selectedUser: selectedUser)),
      expect: () => [SwipeFailedState()],
    );
  });
}
