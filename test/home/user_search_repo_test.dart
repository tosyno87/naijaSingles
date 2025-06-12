import 'package:flutter_test/flutter_test.dart';
import 'package:naijasingles/common/data/repo/user_search_repo.dart';

void main() {
  test('calculateDistance returns expected value', () {
    final distance = UserSearchRepo.calculateDistance(0, 0, 0, 1);
    // Distance between (0,0) and (0,1) is about 111 km
    expect(distance, closeTo(111, 1));
  });
}
