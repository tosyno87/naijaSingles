import 'package:flutter_test/flutter_test.dart';
import 'package:naijasingles/services/profile_boost_service.dart';

void main() {
  test('sortWithBoostPriority places boosted users first', () {
    final sorted = ProfileBoostService.sortWithBoostPriority<String>(
      items: ['a', 'b', 'c'],
      isBoosted: (item) => item == 'b',
    );
    expect(sorted.first, 'b');
  });
}
