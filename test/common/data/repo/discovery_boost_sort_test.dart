import 'package:flutter_test/flutter_test.dart';
import 'package:naijasingles/common/data/repo/discovery_boost_sort.dart';
import 'package:naijasingles/models/user_model.dart';

void main() {
  test('boosted users are ordered before non-boosted users', () {
    final users = [
      UserModel(id: 'a', name: 'A'),
      UserModel(id: 'b', name: 'B'),
      UserModel(id: 'c', name: 'C'),
    ];

    final sorted = sortUsersWithBoostPriority(
      users: users,
      boostedUserIds: {'b'},
    );

    expect(sorted.map((u) => u.id).toList(), ['b', 'a', 'c']);
  });

  test('empty boosted set preserves order', () {
    final users = [
      UserModel(id: 'a', name: 'A'),
      UserModel(id: 'b', name: 'B'),
    ];
    final sorted = sortUsersWithBoostPriority(
      users: users,
      boostedUserIds: {},
    );
    expect(sorted.map((u) => u.id).toList(), ['a', 'b']);
  });
}
