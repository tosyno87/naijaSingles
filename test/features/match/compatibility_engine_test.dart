import 'package:flutter_test/flutter_test.dart';
import 'package:naijasingles/features/match/data/services/compatibility_engine.dart';
import 'package:naijasingles/models/user_model.dart';

void main() {
  group('CompatibilityEngine', () {
    test('calculateCompatibility returns score between 0 and 1', () {
      final user1 = UserModel(id: '1', name: 'Alice', age: 28);
      final user2 = UserModel(id: '2', name: 'Bob', age: 27);

      final score = CompatibilityEngine.calculateCompatibility(user1, user2);

      expect(score, inInclusiveRange(0.0, 1.0));
    });

    test('same age users get high age compatibility', () {
      final user1 = UserModel(id: '1', name: 'Alice', age: 25);
      final user2 = UserModel(id: '2', name: 'Bob', age: 25);

      final score = CompatibilityEngine.calculateCompatibility(user1, user2);

      expect(score, greaterThan(0.3));
    });

    test('users with shared interests get higher scores', () {
      final user1 = UserModel(
        id: '1',
        name: 'Alice',
        age: 28,
        bio: 'I love hiking and photography',
      );
      final user2 = UserModel(
        id: '2',
        name: 'Bob',
        age: 27,
        bio: 'Hiking photography travel enthusiast',
      );

      final score = CompatibilityEngine.calculateCompatibility(user1, user2);

      expect(score, greaterThan(0.2));
    });

    test('handles null age gracefully', () {
      final user1 = UserModel(id: '1', name: 'Alice');
      final user2 = UserModel(id: '2', name: 'Bob');

      final score = CompatibilityEngine.calculateCompatibility(user1, user2);

      expect(score, inInclusiveRange(0.0, 1.0));
    });
  });
}
