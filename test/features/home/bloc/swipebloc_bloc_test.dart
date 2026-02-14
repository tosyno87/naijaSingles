import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naijasingles/features/home/bloc/swipebloc_bloc.dart';
import 'package:naijasingles/models/user_model.dart';

void main() {
  group('SwipeBloc', () {
    final currentUser = UserModel(id: 'current', name: 'Current');
    final selectedUser = UserModel(id: 'selected', name: 'Selected');
    final refreshedUsers = [selectedUser];

    blocTest<SwipeBloc, SwipeblocState>(
      'emits SwipeMatchCreatedState when right swipe creates a match',
      build: () => SwipeBloc(
        rightSwipe: (_, __) async => 'match-123',
        leftSwipe: (_, __) async {},
        getUserList: (_) async => refreshedUsers,
      ),
      act: (bloc) => bloc.add(
        RightSwipeEvent(currentUser: currentUser, selectedUser: selectedUser),
      ),
      expect: () => [
        SwipeMatchCreatedState(
          users: refreshedUsers,
          matchedUser: selectedUser,
        ),
      ],
    );

    blocTest<SwipeBloc, SwipeblocState>(
      'emits SwipeSucessState when right swipe does not create a match',
      build: () => SwipeBloc(
        rightSwipe: (_, __) async => null,
        leftSwipe: (_, __) async {},
        getUserList: (_) async => refreshedUsers,
      ),
      act: (bloc) => bloc.add(
        RightSwipeEvent(currentUser: currentUser, selectedUser: selectedUser),
      ),
      expect: () => [
        SwipeSucessState(refreshedUsers),
      ],
    );

    blocTest<SwipeBloc, SwipeblocState>(
      'emits SwipeSucessState after left swipe',
      build: () => SwipeBloc(
        rightSwipe: (_, __) async => null,
        leftSwipe: (_, __) async {},
        getUserList: (_) async => refreshedUsers,
      ),
      act: (bloc) => bloc.add(
        LeftSwipeEvent(currentUser: currentUser, selectedUser: selectedUser),
      ),
      expect: () => [
        SwipeSucessState(refreshedUsers),
      ],
    );
  });
}
