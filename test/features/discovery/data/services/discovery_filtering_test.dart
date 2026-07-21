import 'package:flutter_test/flutter_test.dart';
import 'package:naijasingles/features/discovery/data/services/discovery_filtering.dart';
import 'package:naijasingles/models/user_model.dart';

void main() {
  group('DiscoveryFiltering', () {
    test('normalizeGender maps common aliases', () {
      expect(DiscoveryFiltering.normalizeGender('Male'), 'male');
      expect(DiscoveryFiltering.normalizeGender('woman'), 'female');
      expect(DiscoveryFiltering.normalizeGender('men'), 'male');
      expect(DiscoveryFiltering.normalizeGender('women'), 'female');
      expect(DiscoveryFiltering.normalizeGender('both'), 'everyone');
    });

    test('matchesGenderPreference maps plural showGender preferences', () {
      final currentUser = UserModel(
        id: 'current',
        name: 'Current',
        showGender: 'women',
      );
      final candidate = UserModel(
        id: 'candidate',
        name: 'Candidate',
        userGender: 'female',
      );

      expect(
        DiscoveryFiltering.matchesGenderPreference(candidate, currentUser),
        isTrue,
      );
    });

    test('matchesGenderPreference allows everyone preference', () {
      final currentUser = UserModel(
        id: 'current',
        name: 'Current',
        showGender: 'everyone',
      );
      final candidate = UserModel(
        id: 'candidate',
        name: 'Candidate',
        userGender: 'female',
      );

      expect(
        DiscoveryFiltering.matchesGenderPreference(candidate, currentUser),
        isTrue,
      );
    });

    test('matchesGenderPreference matches normalized gender values', () {
      final currentUser = UserModel(
        id: 'current',
        name: 'Current',
        showGender: 'man',
      );
      final candidate = UserModel(
        id: 'candidate',
        name: 'Candidate',
        userGender: 'male',
      );

      expect(
        DiscoveryFiltering.matchesGenderPreference(candidate, currentUser),
        isTrue,
      );
    });

    test('matchesGenderPreference rejects non-matching gender values', () {
      final currentUser = UserModel(
        id: 'current',
        name: 'Current',
        showGender: 'female',
      );
      final candidate = UserModel(
        id: 'candidate',
        name: 'Candidate',
        userGender: 'male',
      );

      expect(
        DiscoveryFiltering.matchesGenderPreference(candidate, currentUser),
        isFalse,
      );
    });

    test('matchesLookingForIntent treats blank as compatible', () {
      final seekerDating = 'Dating';
      final blank = UserModel(id: '1', name: 'A', lookingFor: '');
      final missing = UserModel(id: '2', name: 'B');
      final mixed = UserModel(id: '3', name: 'C', lookingFor: 'Mixed');
      final friendship =
          UserModel(id: '4', name: 'D', lookingFor: 'Friendship');
      final romance = UserModel(id: '5', name: 'E', lookingFor: 'Romance');

      expect(
        DiscoveryFiltering.matchesLookingForIntent(blank, seekerDating),
        isTrue,
      );
      expect(
        DiscoveryFiltering.matchesLookingForIntent(missing, seekerDating),
        isTrue,
      );
      expect(
        DiscoveryFiltering.matchesLookingForIntent(mixed, seekerDating),
        isTrue,
      );
      expect(
        DiscoveryFiltering.matchesLookingForIntent(friendship, seekerDating),
        isFalse,
      );
      expect(
        DiscoveryFiltering.matchesLookingForIntent(romance, seekerDating),
        isTrue,
      );
      expect(
        DiscoveryFiltering.matchesLookingForIntent(friendship, 'Mixed'),
        isTrue,
      );
    });

    test('lookingForQueryValues includes synonyms and Mixed', () {
      final dating = DiscoveryFiltering.lookingForQueryValues('Dating');
      expect(dating, containsAll(<String>['Dating', 'Mixed', 'Romance']));
      expect(dating, isNot(contains('Social')));
      expect(dating.length, lessThanOrEqualTo(10));

      final networking = DiscoveryFiltering.lookingForQueryValues('Networking');
      expect(
        networking,
        containsAll(<String>['Networking', 'Mixed', 'Professional']),
      );

      expect(DiscoveryFiltering.lookingForQueryValues('Mixed'), isEmpty);
      expect(DiscoveryFiltering.lookingForQueryValues(null), isEmpty);
    });
  });
}
