import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:naijasingles/features/home/bloc/swipebloc_bloc.dart';
import 'package:naijasingles/features/match/data/services/match_service.dart';
import 'package:naijasingles/models/user_model.dart';

import '../helpers/firebase_test_setup.dart';

class MockMatchService extends Mock implements MatchService {}

void main() {
  setUpAll(() async {
    await FirebaseTestSetup.setupFirebase();
  });

  tearDownAll(FirebaseTestSetup.cleanup);
  group('SwipeBloc', () {
    final currentUser = UserModel(id: '1');
    final selectedUser = UserModel(id: '2');
    final list = [UserModel(id: '3')];
    late MockMatchService mockMatchService;

    setUp(() {
      mockMatchService = MockMatchService();
      // Mock the MatchService methods
      when(() => mockMatchService.hasUserLiked(any()))
          .thenAnswer((_) async => false);
      when(() => mockMatchService.getUsersWhoLikedMe())
          .thenAnswer((_) async => []);
    });

    blocTest<SwipeBloc, SwipeblocState>(
      'emits success after right swipe',
      build: () => SwipeBloc(
        rightSwipe: (_, __) async {},
        getUserList: (_) async => list,
        leftSwipe: (_, __) async {},
        matchService: mockMatchService,
      ),
      act: (bloc) => bloc.add(RightSwipeEvent(
          currentUser: currentUser, selectedUser: selectedUser,),),
      expect: () => [SwipeSucessState(list)],
    );

    blocTest<SwipeBloc, SwipeblocState>(
      'emits success after left swipe',
      build: () => SwipeBloc(
        leftSwipe: (_, __) async {},
        getUserList: (_) async => list,
        rightSwipe: (_, __) async {},
        matchService: mockMatchService,
      ),
      act: (bloc) => bloc.add(
          LeftSwipeEvent(currentUser: currentUser, selectedUser: selectedUser),),
      expect: () => [SwipeSucessState(list)],
    );

    blocTest<SwipeBloc, SwipeblocState>(
      'emits failed state on exception',
      build: () => SwipeBloc(
        rightSwipe: (_, __) => throw Exception(),
        getUserList: (_) async => [],
        leftSwipe: (_, __) async {},
        matchService: mockMatchService,
      ),
      act: (bloc) => bloc.add(RightSwipeEvent(
          currentUser: currentUser, selectedUser: selectedUser,),),
      expect: () => [SwipeFailedState()],
    );
  });
}
