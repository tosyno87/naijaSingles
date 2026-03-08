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

    test('compatibility is symmetric', () {
      final user1 = UserModel(
        id: '1',
        name: 'Alice',
        age: 28,
        bio: 'Travel and cooking lover',
      );
      final user2 = UserModel(
        id: '2',
        name: 'Bob',
        age: 32,
        bio: 'Cooking enthusiast who travels',
      );

      final scoreAB =
          CompatibilityEngine.calculateCompatibility(user1, user2);
      final scoreBA =
          CompatibilityEngine.calculateCompatibility(user2, user1);

      expect(scoreAB, closeTo(scoreBA, 0.001));
    });

    test('calculateBatchCompatibility returns results sorted descending', () {
      final current = UserModel(id: '0', name: 'Current', age: 25);
      final targets = [
        UserModel(id: '1', name: 'Far Age', age: 60),
        UserModel(id: '2', name: 'Same Age', age: 25),
        UserModel(id: '3', name: 'Close Age', age: 27),
      ];

      final results = CompatibilityEngine.calculateBatchCompatibility(
        current,
        targets,
      );

      for (int i = 0; i < results.length - 1; i++) {
        expect(
          results[i].compatibilityScore,
          greaterThanOrEqualTo(results[i + 1].compatibilityScore),
        );
      }
    });

    test('nearby users score higher on location than distant users', () {
      final user1 = UserModel(
        id: '1',
        name: 'Alice',
        age: 25,
        coordinates: {'latitude': 40.7128, 'longitude': -74.0060},
      );
      final nearby = UserModel(
        id: '2',
        name: 'Nearby Bob',
        age: 25,
        coordinates: {'latitude': 40.7200, 'longitude': -74.0000},
      );
      final distant = UserModel(
        id: '3',
        name: 'Distant Charlie',
        age: 25,
        coordinates: {'latitude': 34.0522, 'longitude': -118.2437},
      );

      final nearbyScore =
          CompatibilityEngine.calculateCompatibility(user1, nearby);
      final distantScore =
          CompatibilityEngine.calculateCompatibility(user1, distant);

      expect(nearbyScore, greaterThan(distantScore));
    });

    test('users sharing many interests score higher than users sharing none',
        () {
      final user1 = UserModel(
        id: '1',
        name: 'Alice',
        age: 25,
        bio: 'Love hiking camping photography travel',
        profession: 'Engineer',
        education: 'MIT',
      );
      final similar = UserModel(
        id: '2',
        name: 'Similar Bob',
        age: 25,
        bio: 'Passionate about hiking photography travel',
        profession: 'Engineer',
        education: 'MIT',
      );
      final different = UserModel(
        id: '3',
        name: 'Different Charlie',
        age: 25,
        bio: 'Classical piano opera ballet',
        profession: 'Lawyer',
        education: 'Harvard Law',
      );

      final similarScore =
          CompatibilityEngine.calculateCompatibility(user1, similar);
      final differentScore =
          CompatibilityEngine.calculateCompatibility(user1, different);

      expect(similarScore, greaterThan(differentScore));
    });
  });
}
