import 'package:flutter_test/flutter_test.dart';
import 'package:naijasingles/features/discovery/data/services/discovery_filtering.dart';
import 'package:naijasingles/models/user_model.dart';

void main() {
  group('DiscoveryFiltering', () {
    test('normalizeGender maps common aliases', () {
      expect(DiscoveryFiltering.normalizeGender('Male'), 'male');
      expect(DiscoveryFiltering.normalizeGender('woman'), 'female');
      expect(DiscoveryFiltering.normalizeGender('both'), 'everyone');
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

    test('matchesGenderPreference allows candidate with missing gender', () {
      final currentUser = UserModel(
        id: 'current',
        name: 'Current',
        showGender: 'female',
      );
      final candidate = UserModel(
        id: 'candidate',
        name: 'Candidate',
      );

      expect(
        DiscoveryFiltering.matchesGenderPreference(candidate, currentUser),
        isTrue,
      );
    });
  });
}
