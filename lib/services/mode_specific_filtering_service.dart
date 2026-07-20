import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../features/discovery/data/services/discovery_filtering.dart';
import '../models/user_model.dart';

/// Mode-specific filtering service that applies different filters based on relationship intent
/// Implements Priority 2: Enhanced Matching Algorithm with mode differentiation
class ModeSpecificFilteringService {
  /// Apply mode-specific filtering to a base query
  static Query applyModeSpecificFilters(
    Query baseQuery,
    UserModel currentUser,
    String mode,
  ) {
    try {
      debugPrint('🎯 Applying $mode-specific filters for ${currentUser.name}');

      Query filteredQuery = baseQuery;

      switch (mode) {
        case 'Dating':
          filteredQuery = _applyDatingFilters(filteredQuery, currentUser);
          break;
        case 'Friendship':
          filteredQuery = _applyFriendshipFilters(filteredQuery, currentUser);
          break;
        case 'Networking':
          filteredQuery = _applyNetworkingFilters(filteredQuery, currentUser);
          break;
        case 'Mixed':
          debugPrint('🌍 Mixed mode — no mode-specific query filters applied');
          break;
        default:
          debugPrint('⚠️ Unknown mode: $mode, using default filters');
      }

      debugPrint('✅ Applied $mode-specific filters');
      return filteredQuery;
    } on Object catch (e) {
      debugPrint('❌ Error applying mode-specific filters: $e');
      return baseQuery; // Return original query on error
    }
  }

  /// Apply dating-specific filters
  static Query _applyDatingFilters(Query query, UserModel currentUser) {
    debugPrint('💕 Applying dating-specific filters');

    // TEMPORARILY DISABLED: Age compatibility is more important for dating
    debugPrint('🔍 TEMPORARILY DISABLING DATING AGE FILTER FOR DEBUGGING');
    // if (currentUser.ageRangeMin != null && currentUser.ageRangeMax != null) {
    //   // Tighten age range for dating (reduce by 2 years on each side)
    //   final minAge = (currentUser.ageRangeMin! + 2).clamp(18, 100);
    //   final maxAge = (currentUser.ageRangeMax! - 2).clamp(18, 100);
    //
    //   query = query
    //       .where('age', isGreaterThanOrEqualTo: minAge)
    //       .where('age', isLessThanOrEqualTo: maxAge);
    //
    //   debugPrint('💕 Dating age filter: $minAge-$maxAge');
    // }

    // TEMPORARILY DISABLED: Location is very important for dating
    debugPrint('🔍 TEMPORARILY DISABLING maxDistance FILTER FOR DEBUGGING');
    // if (currentUser.maxDistance != null) {
    //   // Reduce max distance for dating (more local matches)
    //   final datingMaxDistance = (currentUser.maxDistance! * 0.8).round();
    //   query = query.where('maxDistance', isGreaterThanOrEqualTo: datingMaxDistance);
    //   debugPrint('💕 Dating distance filter: ${(datingMaxDistance * 0.621371).round()} miles');
    // }

    // TEMPORARILY DISABLED: lookingFor filter (field might not exist or have different name)
    debugPrint(
      '🔍 TEMPORARILY DISABLING lookingFor FILTER - field might not exist',
    );
    // try {
    //   query = query.where('lookingFor', whereIn: ['Dating', 'Romance', 'Relationship', 'Love', 'Marriage']);
    //   debugPrint('💕 Filtering by lookingFor: Dating/Romance/Relationship/Love/Marriage');
    // } on Object catch (e) {
    //   debugPrint('⚠️ lookingFor filter failed, continuing without it: $e');
    // }

    // TEMPORARILY DISABLED: Filter for active users (important for dating)
    debugPrint('🔍 TEMPORARILY DISABLING lastActive FILTER FOR DEBUGGING');
    // query = query.where('lastActive', isGreaterThan:
    //     Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 7))));

    // TEMPORARILY DISABLED: Filter for users with complete dating profiles
    debugPrint(
      '🔍 TEMPORARILY DISABLING hasDatingProfile FILTER FOR DEBUGGING',
    );
    // query = query.where('hasDatingProfile', isEqualTo: true);

    return query;
  }

  /// Apply friendship-specific filters.
  /// Age range is already applied by _buildOptimizedQuery; adding it again
  /// would trigger a Firestore duplicate-condition assertion.
  static Query _applyFriendshipFilters(Query query, UserModel currentUser) {
    debugPrint(
      '🤝 Applying friendship-specific filters (age handled by base query)',
    );
    return query;
  }

  /// Apply networking-specific filters.
  /// Age range is already applied by _buildOptimizedQuery.
  static Query _applyNetworkingFilters(Query query, UserModel currentUser) {
    debugPrint(
      '💼 Applying networking-specific filters (age handled by base query)',
    );
    return query;
  }

  /// Get mode-specific user preferences for filtering
  static Map<String, dynamic> getModeSpecificPreferences(
    UserModel currentUser,
    String mode,
  ) {
    switch (mode) {
      case 'Dating':
        return {
          'ageRange': {
            'min': (currentUser.ageRangeMin! + 2).clamp(18, 100),
            'max': (currentUser.ageRangeMax! - 2).clamp(18, 100),
          },
          'maxDistance': (currentUser.maxDistance! * 0.8).round(),
          'lookingFor': ['Dating', 'Romance', 'Relationship'],
          'profileType': 'dating',
          'activityLevel': 'high',
        };

      case 'Friendship':
        return {
          'ageRange': {
            'min': (currentUser.ageRangeMin! - 5).clamp(18, 100),
            'max': (currentUser.ageRangeMax! + 5).clamp(18, 100),
          },
          'maxDistance': (currentUser.maxDistance! * 1.5).round(),
          'lookingFor': ['Friendship', 'Friends', 'Social'],
          'profileType': 'social',
          'activityLevel': 'medium',
        };

      case 'Networking':
        return {
          'ageRange': {
            'min': (currentUser.ageRangeMin! - 10).clamp(18, 100),
            'max': (currentUser.ageRangeMax! + 10).clamp(18, 100),
          },
          'maxDistance': currentUser.maxDistance,
          'lookingFor': ['Networking', 'Business', 'Professional'],
          'profileType': 'professional',
          'activityLevel': 'medium',
        };

      case 'Mixed':
        return {
          'ageRange': {
            'min': currentUser.ageRangeMin,
            'max': currentUser.ageRangeMax,
          },
          'maxDistance': currentUser.maxDistance,
          'lookingFor': [
            'Dating',
            'Friendship',
            'Networking',
            'Mixed',
          ],
          'profileType': 'general',
          'activityLevel': 'medium',
        };

      default:
        return {
          'ageRange': {
            'min': currentUser.ageRangeMin,
            'max': currentUser.ageRangeMax,
          },
          'maxDistance': currentUser.maxDistance,
          'lookingFor': [
            'Dating',
            'Friendship',
            'Networking',
            'Mixed',
          ],
          'profileType': 'general',
          'activityLevel': 'medium',
        };
    }
  }

  /// Validate if a user matches mode-specific criteria.
  /// 'Mixed' users pass all modes; a 'Mixed' mode accepts everyone.
  static bool validateModeMatch(UserModel user, String mode) {
    try {
      if (mode == 'Mixed') return true;
      if (user.lookingFor == 'Mixed') return true;

      switch (mode) {
        case 'Dating':
          return _validateDatingMatch(user);
        case 'Friendship':
          return _validateFriendshipMatch(user);
        case 'Networking':
          return _validateNetworkingMatch(user);
        default:
          return true;
      }
    } on Object catch (e) {
      debugPrint('❌ Error validating mode match: $e');
      return true;
    }
  }

  static bool _validateDatingMatch(UserModel user) {
    final imageCheck = user.imageUrl != null && user.imageUrl!.isNotEmpty;
    return imageCheck &&
        DiscoveryFiltering.matchesLookingForIntent(user, 'Dating');
  }

  static bool _validateFriendshipMatch(UserModel user) =>
      DiscoveryFiltering.matchesLookingForIntent(user, 'Friendship');

  static bool _validateNetworkingMatch(UserModel user) =>
      DiscoveryFiltering.matchesLookingForIntent(user, 'Networking');

  /// Get mode-specific search suggestions
  static List<String> getModeSpecificSuggestions(String mode) {
    switch (mode) {
      case 'Dating':
        return [
          'Looking for someone special',
          'Find your perfect match',
          'Romantic connections',
          'Serious relationships',
          'Casual dating',
        ];

      case 'Friendship':
        return [
          'Make new friends',
          'Expand your social circle',
          'Find activity partners',
          'Group activities',
          'Social connections',
        ];

      case 'Networking':
        return [
          'Professional connections',
          'Career opportunities',
          'Business partnerships',
          'Industry networking',
          'Skill sharing',
        ];

      case 'Mixed':
        return [
          'Explore all connections',
          'Meet new people',
          'Friends, dating, or networking',
          'Open to anything',
          'Discover your community',
        ];

      default:
        return ['Connect with people'];
    }
  }
}
