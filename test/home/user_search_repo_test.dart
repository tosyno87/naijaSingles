import 'package:flutter_test/flutter_test.dart';
import 'package:naijasingles/common/data/repo/user_search_repo.dart';

void main() {
  test('calculateDistance returns expected value', () {
    final distance = UserSearchRepo.calculateDistance(0, 0, 0, 1);
    // Distance between (0,0) and (0,1) is about 69 miles
    expect(distance, closeTo(69, 1));
  });
}
