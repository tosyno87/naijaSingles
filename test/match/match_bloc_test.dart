import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naijasingles/features/match/bloc/match_bloc.dart';
import 'package:naijasingles/models/user_model.dart';

void main() {
  group('MatchUserBloc', () {
    final currentUser = UserModel(id: '1');
    final otherUser = UserModel(id: '2');

    blocTest<MatchUserBloc, MatchUserState>(
      'emits [Loading, Loaded] when repository returns data',
      build: () => MatchUserBloc(
        getMatches: (_) async => [otherUser],
      ),
      act: (bloc) => bloc.add(LoadMatchUserEvent(currentUser: currentUser)),
      expect: () => [
        MatchUserLoadingState(),
        MatchUserLoadedState([otherUser]),
      ],
    );

    blocTest<MatchUserBloc, MatchUserState>(
      'emits [Loading, Failed] on error',
      build: () => MatchUserBloc(
        getMatches: (_) => throw Exception('error'),
      ),
      act: (bloc) => bloc.add(LoadMatchUserEvent(currentUser: currentUser)),
      expect: () => [
        MatchUserLoadingState(),
        MatchUserFailedState(),
      ],
    );
  });
}
