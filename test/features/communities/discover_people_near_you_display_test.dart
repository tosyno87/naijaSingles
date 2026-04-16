import 'package:flutter_test/flutter_test.dart';
import 'package:naijasingles/features/communities/utils/discover_people_near_you_display.dart';
import 'package:naijasingles/models/user_model.dart';

void main() {
  test('sortAndCapPeopleNearYou sorts by distanceBW ascending', () {
    final List<UserModel> input = <UserModel>[
      UserModel(id: 'a', distanceBW: 50),
      UserModel(id: 'b', distanceBW: 10),
      UserModel(id: 'c', distanceBW: 30),
    ];
    final List<UserModel> out = sortAndCapPeopleNearYou(input);
    expect(out.map((UserModel u) => u.id).toList(), <String>['b', 'c', 'a']);
  });

  test('sortAndCapPeopleNearYou caps at kPeopleNearYouMax', () {
    final List<UserModel> input = <UserModel>[
      for (int i = 0; i < kPeopleNearYouMax + 8; i++)
        UserModel(id: 'u$i', distanceBW: i),
    ];
    final List<UserModel> out = sortAndCapPeopleNearYou(input);
    expect(out.length, kPeopleNearYouMax);
  });
}
