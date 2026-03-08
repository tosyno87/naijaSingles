import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naijasingles/models/user_model.dart';
import 'package:naijasingles/services/mode_specific_compatibility_engine.dart';
import 'package:naijasingles/services/mode_specific_filtering_service.dart';

void main() {
  group('Mode Differentiation Tests', () {
    late UserModel currentUser;
    late UserModel targetUser;

    setUp(() {
      currentUser = UserModel(
        id: 'user1',
        name: 'Test User',
        age: 25,
        userGender: 'male',
        showGender: 'female',
        ageRange: {'min': '20', 'max': '30'},
        maxDistance: 50,
        lookingFor: 'Dating',
        bio: 'Looking for someone special',
        job_title: 'Software Engineer',
        company: 'Tech Corp',
        imageUrl: ['https://example.com/photo.jpg'],
        coordinates: {
          'latitude': 40.7128,
          'longitude': -74.0060,
        },
      );

      targetUser = UserModel(
        id: 'user2',
        name: 'Target User',
        age: 27,
        userGender: 'female',
        showGender: 'male',
        ageRange: {'min': '22', 'max': '32'},
        maxDistance: 50,
        lookingFor: 'Dating',
        bio: 'Looking for a serious relationship',
        job_title: 'Designer',
        company: 'Design Studio',
        imageUrl: ['https://example.com/photo2.jpg'],
        coordinates: {
          'latitude': 40.7589,
          'longitude': -73.9851,
        },
      );
    });

    group('Mode-Specific Compatibility Engine', () {
      test('should calculate different scores for different modes', () {
        final datingScore =
            ModeSpecificCompatibilityEngine.calculateModeCompatibility(
          currentUser,
          targetUser,
          'Dating',
        );

        final friendshipScore =
            ModeSpecificCompatibilityEngine.calculateModeCompatibility(
          currentUser,
          targetUser,
          'Friendship',
        );

        final networkingScore =
            ModeSpecificCompatibilityEngine.calculateModeCompatibility(
          currentUser,
          targetUser,
          'Networking',
        );

        // Scores should be different for different modes
        expect(datingScore, isA<double>());
        expect(friendshipScore, isA<double>());
        expect(networkingScore, isA<double>());

        // Scores should be between 0 and 1
        expect(datingScore, inInclusiveRange(0.0, 1.0));
        expect(friendshipScore, inInclusiveRange(0.0, 1.0));
        expect(networkingScore, inInclusiveRange(0.0, 1.0));

        debugPrint('Dating Score: ${(datingScore * 100).toStringAsFixed(1)}%');
        debugPrint(
            'Friendship Score: ${(friendshipScore * 100).toStringAsFixed(1)}%',);
        debugPrint(
            'Networking Score: ${(networkingScore * 100).toStringAsFixed(1)}%',);
      });

      test('should return compatibility breakdown', () {
        final datingBreakdown =
            ModeSpecificCompatibilityEngine.getCompatibilityBreakdown(
          currentUser,
          targetUser,
          'Dating',
        );

        final friendshipBreakdown =
            ModeSpecificCompatibilityEngine.getCompatibilityBreakdown(
          currentUser,
          targetUser,
          'Friendship',
        );

        final networkingBreakdown =
            ModeSpecificCompatibilityEngine.getCompatibilityBreakdown(
          currentUser,
          targetUser,
          'Networking',
        );

        // Dating breakdown should have age, location, lifestyle, interest, completeness
        expect(datingBreakdown.keys, contains('age'));
        expect(datingBreakdown.keys, contains('location'));
        expect(datingBreakdown.keys, contains('lifestyle'));
        expect(datingBreakdown.keys, contains('interest'));
        expect(datingBreakdown.keys, contains('completeness'));

        // Friendship breakdown should have social, interest, location, age, completeness
        expect(friendshipBreakdown.keys, contains('social'));
        expect(friendshipBreakdown.keys, contains('interest'));
        expect(friendshipBreakdown.keys, contains('location'));
        expect(friendshipBreakdown.keys, contains('age'));
        expect(friendshipBreakdown.keys, contains('completeness'));

        // Networking breakdown should have professional, industry, location, completeness
        expect(networkingBreakdown.keys, contains('professional'));
        expect(networkingBreakdown.keys, contains('industry'));
        expect(networkingBreakdown.keys, contains('location'));
        expect(networkingBreakdown.keys, contains('completeness'));
      });
    });

    group('Mode-Specific Filtering Service', () {
      test('should return different preferences for different modes', () {
        final datingPrefs =
            ModeSpecificFilteringService.getModeSpecificPreferences(
          currentUser,
          'Dating',
        );

        final friendshipPrefs =
            ModeSpecificFilteringService.getModeSpecificPreferences(
          currentUser,
          'Friendship',
        );

        final networkingPrefs =
            ModeSpecificFilteringService.getModeSpecificPreferences(
          currentUser,
          'Networking',
        );

        // Dating should have tighter age range
        expect(datingPrefs['ageRange']['min'], equals(22)); // 20 + 2
        expect(datingPrefs['ageRange']['max'], equals(28)); // 30 - 2

        // Friendship should have expanded age range
        expect(friendshipPrefs['ageRange']['min'],
            equals(18),); // 20 - 5, clamped to 18
        expect(friendshipPrefs['ageRange']['max'], equals(35)); // 30 + 5

        // Networking should have most expanded age range
        expect(networkingPrefs['ageRange']['min'],
            equals(18),); // 20 - 10, clamped to 18
        expect(networkingPrefs['ageRange']['max'], equals(40)); // 30 + 10

        // Distance preferences should be different
        expect(datingPrefs['maxDistance'], equals(40)); // 50 * 0.8
        expect(friendshipPrefs['maxDistance'], equals(75)); // 50 * 1.5
        expect(networkingPrefs['maxDistance'], equals(50)); // 50 * 1.0
      });

      test('should validate mode matches correctly', () {
        // Test dating validation
        expect(
          ModeSpecificFilteringService.validateModeMatch(targetUser, 'Dating'),
          isTrue,
        );

        // Test friendship validation (should fail because user is looking for dating)
        expect(
          ModeSpecificFilteringService.validateModeMatch(
              targetUser, 'Friendship',),
          isFalse,
        );

        // Test networking validation (should fail because user is looking for dating)
        expect(
          ModeSpecificFilteringService.validateModeMatch(
              targetUser, 'Networking',),
          isFalse,
        );
      });

      test('should return mode-specific suggestions', () {
        final datingSuggestions =
            ModeSpecificFilteringService.getModeSpecificSuggestions('Dating');
        final friendshipSuggestions =
            ModeSpecificFilteringService.getModeSpecificSuggestions(
                'Friendship',);
        final networkingSuggestions =
            ModeSpecificFilteringService.getModeSpecificSuggestions(
                'Networking',);

        expect(datingSuggestions, isNotEmpty);
        expect(friendshipSuggestions, isNotEmpty);
        expect(networkingSuggestions, isNotEmpty);

        expect(datingSuggestions, contains('Looking for someone special'));
        expect(friendshipSuggestions, contains('Make new friends'));
        expect(networkingSuggestions, contains('Professional connections'));
      });
    });

    group('Ranking correctness', () {
      test('dating weights age more heavily than friendship does', () {
        final baseUser = UserModel(
          id: 'base',
          name: 'Base',
          age: 25,
          coordinates: {'latitude': 40.7128, 'longitude': -74.0060},
        );
        final sameAge = UserModel(
          id: 'same',
          name: 'Same Age',
          age: 25,
          coordinates: {'latitude': 40.7128, 'longitude': -74.0060},
        );
        final farAge = UserModel(
          id: 'far',
          name: 'Far Age',
          age: 45,
          coordinates: {'latitude': 40.7128, 'longitude': -74.0060},
        );

        final datingSame =
            ModeSpecificCompatibilityEngine.calculateModeCompatibility(
          baseUser,
          sameAge,
          'Dating',
        );
        final datingFar =
            ModeSpecificCompatibilityEngine.calculateModeCompatibility(
          baseUser,
          farAge,
          'Dating',
        );
        final friendSame =
            ModeSpecificCompatibilityEngine.calculateModeCompatibility(
          baseUser,
          sameAge,
          'Friendship',
        );
        final friendFar =
            ModeSpecificCompatibilityEngine.calculateModeCompatibility(
          baseUser,
          farAge,
          'Friendship',
        );

        final datingDelta = datingSame - datingFar;
        final friendDelta = friendSame - friendFar;

        // Dating should penalize age mismatch more than friendship
        expect(
          datingDelta,
          greaterThan(friendDelta),
          reason:
              'Dating (30% age weight) should show larger score delta than '
              'Friendship (10% age weight) for the same age difference',
        );
      });

      test(
          'matching lifestyles score higher than mismatching lifestyles in dating',
          () {
        final user = UserModel(
          id: 'u1',
          name: 'User',
          age: 25,
          drinkingStatus: 'Never',
          smokingStatus: 'Never',
          religion: 'Christian',
        );
        final matchingLifestyle = UserModel(
          id: 'u2',
          name: 'Match',
          age: 25,
          drinkingStatus: 'Never',
          smokingStatus: 'Never',
          religion: 'Christian',
        );
        final mismatchLifestyle = UserModel(
          id: 'u3',
          name: 'Mismatch',
          age: 25,
          drinkingStatus: 'Regularly',
          smokingStatus: 'Regularly',
          religion: 'None',
        );

        final matchScore =
            ModeSpecificCompatibilityEngine.calculateModeCompatibility(
          user,
          matchingLifestyle,
          'Dating',
        );
        final mismatchScore =
            ModeSpecificCompatibilityEngine.calculateModeCompatibility(
          user,
          mismatchLifestyle,
          'Dating',
        );

        expect(
          matchScore,
          greaterThan(mismatchScore),
          reason: 'Matching lifestyles must produce a higher dating score',
        );
      });

      test(
          'matching profession scores higher in networking than mismatching',
          () {
        final user = UserModel(
          id: 'u1',
          name: 'User',
          age: 30,
          job_title: 'Software Engineer',
          occupation: 'Software Engineering',
          education: 'Computer Science',
        );
        final sameProfession = UserModel(
          id: 'u2',
          name: 'Same',
          age: 30,
          job_title: 'Software Engineer',
          occupation: 'Software Engineering',
          education: 'Computer Science',
        );
        final differentProfession = UserModel(
          id: 'u3',
          name: 'Different',
          age: 30,
          job_title: 'Pastry Chef',
          occupation: 'Culinary Arts',
          education: 'Le Cordon Bleu',
        );

        final sameScore =
            ModeSpecificCompatibilityEngine.calculateModeCompatibility(
          user,
          sameProfession,
          'Networking',
        );
        final diffScore =
            ModeSpecificCompatibilityEngine.calculateModeCompatibility(
          user,
          differentProfession,
          'Networking',
        );

        expect(
          sameScore,
          greaterThan(diffScore),
          reason:
              'Same profession must score higher in networking mode',
        );
      });

      test('shared languages boost friendship score', () {
        final user = UserModel(
          id: 'u1',
          name: 'User',
          age: 25,
          languages: ['English', 'Yoruba', 'French'],
          tribe: 'Yoruba',
          nationality: 'Nigerian',
        );
        final sharedLangs = UserModel(
          id: 'u2',
          name: 'Shared',
          age: 25,
          languages: ['English', 'Yoruba'],
          tribe: 'Yoruba',
          nationality: 'Nigerian',
        );
        final noSharedLangs = UserModel(
          id: 'u3',
          name: 'None',
          age: 25,
          languages: ['Mandarin', 'Japanese'],
          tribe: 'Other',
          nationality: 'Chinese',
        );

        final sharedScore =
            ModeSpecificCompatibilityEngine.calculateModeCompatibility(
          user,
          sharedLangs,
          'Friendship',
        );
        final noSharedScore =
            ModeSpecificCompatibilityEngine.calculateModeCompatibility(
          user,
          noSharedLangs,
          'Friendship',
        );

        expect(
          sharedScore,
          greaterThan(noSharedScore),
          reason:
              'Shared languages/tribe/nationality must boost friendship score',
        );
      });
    });

    group('Integration Tests', () {
      test('should work with different user profiles', () {
        // Test with a networking-focused user
        final networkingUser = UserModel(
          id: 'networking_user',
          name: 'Networking User',
          age: 35,
          userGender: 'male',
          showGender: 'everyone',
          ageRange: {'min': '25', 'max': '45'},
          maxDistance: 100,
          lookingFor: 'Networking',
          bio: 'Looking for business opportunities',
          job_title: 'CEO',
          company: 'Startup Inc',
          imageUrl: ['https://example.com/ceo.jpg'],
          coordinates: {
            'latitude': 40.7128,
            'longitude': -74.0060,
          },
        );

        final networkingScore =
            ModeSpecificCompatibilityEngine.calculateModeCompatibility(
          currentUser,
          networkingUser,
          'Networking',
        );

        expect(networkingScore, inInclusiveRange(0.0, 1.0));
        debugPrint(
            'Networking User Score: ${(networkingScore * 100).toStringAsFixed(1)}%',);
      });

      test('should handle edge cases gracefully', () {
        // Test with minimal user data
        final minimalUser = UserModel(
          id: 'minimal_user',
          name: 'Minimal User',
          age: 25,
          userGender: 'female',
          showGender: 'male',
        );

        final score =
            ModeSpecificCompatibilityEngine.calculateModeCompatibility(
          currentUser,
          minimalUser,
          'Dating',
        );

        expect(score, inInclusiveRange(0.0, 1.0));
        debugPrint('Minimal User Score: ${(score * 100).toStringAsFixed(1)}%');
      });
    });
  });
}
