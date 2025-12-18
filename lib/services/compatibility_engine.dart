import 'package:flutter/foundation.dart';

import '../common/utils/distance.dart' as distance;
import '../models/user_model.dart';

/// Compatibility engine that calculates match scores between users
/// Implements Priority 2: Enhanced Matching Algorithm
class CompatibilityEngine {
  // Scoring weights (must sum to 1.0)
  static const double AGE_WEIGHT = 0.25; // 25%
  static const double LOCATION_WEIGHT = 0.30; // 30%
  static const double INTEREST_WEIGHT = 0.20; // 20%
  static const double ACTIVITY_WEIGHT = 0.15; // 15%
  static const double COMPLETENESS_WEIGHT = 0.10; // 10%

  // Scoring parameters
  static const int IDEAL_AGE_DIFFERENCE = 3; // Years
  static const int MAX_AGE_DIFFERENCE = 10; // Years
  static const double MAX_DISTANCE_MILES = 31; // Miles (converted from 50km)
  static const int ACTIVITY_THRESHOLD_DAYS = 7; // Days

  /// Calculate overall compatibility score between two users
  /// Returns a score between 0.0 (no compatibility) and 1.0 (perfect match)
  static double calculateCompatibility(UserModel user1, UserModel user2) {
    try {
      double totalScore = 0;

      // Age compatibility (25%)
      final ageScore = _calculateAgeCompatibility(user1, user2);
      totalScore += ageScore * AGE_WEIGHT;

      // Location proximity (30%)
      final locationScore = _calculateLocationScore(user1, user2);
      totalScore += locationScore * LOCATION_WEIGHT;

      // Interest matching (20%)
      final interestScore = _calculateInterestScore(user1, user2);
      totalScore += interestScore * INTEREST_WEIGHT;

      // Activity level (15%)
      final activityScore = _calculateActivityScore(user1, user2);
      totalScore += activityScore * ACTIVITY_WEIGHT;

      // Profile completeness (10%)
      final completenessScore = _calculateCompletenessScore(user1, user2);
      totalScore += completenessScore * COMPLETENESS_WEIGHT;

      // Ensure score is within bounds
      totalScore = totalScore.clamp(0.0, 1.0);

      debugPrint(
          '🎯 Compatibility ${user1.name} ↔ ${user2.name}: ${(totalScore * 100).toStringAsFixed(1)}%',);
      debugPrint(
          '   Age: ${(ageScore * 100).toStringAsFixed(1)}%, Location: ${(locationScore * 100).toStringAsFixed(1)}%, Interest: ${(interestScore * 100).toStringAsFixed(1)}%, Activity: ${(activityScore * 100).toStringAsFixed(1)}%, Completeness: ${(completenessScore * 100).toStringAsFixed(1)}%',);

      return totalScore;
    } catch (e) {
      debugPrint('❌ Error calculating compatibility: $e');
      return 0.5; // Return neutral score on error
    }
  }

  /// Calculate age compatibility score
  /// Perfect score for ideal age difference, decreasing as difference increases
  static double _calculateAgeCompatibility(UserModel user1, UserModel user2) {
    try {
      final age1 = user1.age ?? 25; // Default age if not provided
      final age2 = user2.age ?? 25;

      final ageDifference = (age1 - age2).abs();

      if (ageDifference <= IDEAL_AGE_DIFFERENCE) {
        return 1; // Perfect score for ideal age difference
      } else if (ageDifference <= MAX_AGE_DIFFERENCE) {
        // Linear decrease from 1.0 to 0.3 as age difference increases
        final score = 1.0 -
            ((ageDifference - IDEAL_AGE_DIFFERENCE) /
                    (MAX_AGE_DIFFERENCE - IDEAL_AGE_DIFFERENCE)) *
                0.7;
        return score.clamp(0.3, 1.0);
      } else {
        return 0.1; // Very low score for large age differences
      }
    } catch (e) {
      debugPrint('❌ Error calculating age compatibility: $e');
      return 0.5;
    }
  }

  /// Calculate location proximity score
  /// Higher score for users who are closer together
  static double _calculateLocationScore(UserModel user1, UserModel user2) {
    try {
      // Check if both users have location data
      if (user1.coordinates == null ||
          user2.coordinates == null ||
          user1.coordinates!.isEmpty ||
          user2.coordinates!.isEmpty) {
        return 0.5; // Neutral score if location data is missing
      }

      final lat1 = user1.coordinates!['latitude'] as double?;
      final lng1 = user1.coordinates!['longitude'] as double?;
      final lat2 = user2.coordinates!['latitude'] as double?;
      final lng2 = user2.coordinates!['longitude'] as double?;

      if (lat1 == null || lng1 == null || lat2 == null || lng2 == null) {
        return 0.5; // Neutral score if coordinates are invalid
      }

      // Calculate distance between users
      final distanceKm = distance.calculateDistance(lat1, lng1, lat2, lng2);

      if (distanceKm <= 3.1) {
        return 1; // Perfect score for very close users (within 3.1 miles)
      } else if (distanceKm <= MAX_DISTANCE_MILES) {
        // Linear decrease from 1.0 to 0.2 as distance increases
        final score =
            1.0 - ((distanceKm - 3.1) / (MAX_DISTANCE_MILES - 3.1)) * 0.8;
        return score.clamp(0.2, 1.0);
      } else {
        return 0.1; // Very low score for distant users
      }
    } catch (e) {
      debugPrint('❌ Error calculating location score: $e');
      return 0.5;
    }
  }

  /// Calculate interest matching score
  /// Based on shared interests, hobbies, and preferences
  static double _calculateInterestScore(UserModel user1, UserModel user2) {
    try {
      final interests1 = _extractInterests(user1);
      final interests2 = _extractInterests(user2);

      if (interests1.isEmpty || interests2.isEmpty) {
        return 0.3; // Low score if no interests are provided
      }

      // Calculate Jaccard similarity (intersection / union)
      final intersection = interests1.intersection(interests2);
      final union = interests1.union(interests2);

      if (union.isEmpty) {
        return 0.3;
      }

      final jaccardSimilarity = intersection.length / union.length;

      // Boost score if there are many shared interests
      final sharedCount = intersection.length;
      final boost = sharedCount >= 3 ? 0.2 : (sharedCount >= 2 ? 0.1 : 0.0);

      final score = (jaccardSimilarity + boost).clamp(0.0, 1.0);

      debugPrint(
          '🎨 Interest matching: ${intersection.length} shared interests out of ${union.length} total',);

      return score;
    } catch (e) {
      debugPrint('❌ Error calculating interest score: $e');
      return 0.5;
    }
  }

  /// Extract interests from user profile
  static Set<String> _extractInterests(UserModel user) {
    final interests = <String>{};

    // Add bio keywords (simple keyword extraction)
    if (user.bio != null && user.bio!.isNotEmpty) {
      final bioWords = user.bio!
          .toLowerCase()
          .replaceAll(RegExp(r'[^\w\s]'), ' ')
          .split(' ')
          .where((word) => word.length > 3)
          .toSet();
      interests.addAll(bioWords);
    }

    // Add location-based interests
    if (user.address != null && user.address!.isNotEmpty) {
      final locationWords = user.address!
          .toLowerCase()
          .split(' ')
          .where((word) => word.length > 3)
          .toSet();
      interests.addAll(locationWords);
    }

    // Add profession-based interests
    if (user.profession != null && user.profession!.isNotEmpty) {
      interests.add(user.profession!.toLowerCase());
    }

    // Add education-based interests
    if (user.education != null && user.education!.isNotEmpty) {
      interests.add(user.education!.toLowerCase());
    }

    // Add lifestyle interests based on profile data
    if (user.drinkingStatus != null) {
      interests.add('drinking_${user.drinkingStatus!.toLowerCase()}');
    }

    if (user.smokingStatus != null) {
      interests.add('smoking_${user.smokingStatus!.toLowerCase()}');
    }

    return interests;
  }

  /// Calculate activity level compatibility
  /// Prefers users who are both active or both less active
  static double _calculateActivityScore(UserModel user1, UserModel user2) {
    try {
      final activity1 = _calculateUserActivity(user1);
      final activity2 = _calculateUserActivity(user2);

      // Calculate similarity in activity levels (0.0 = very different, 1.0 = very similar)
      final activityDifference = (activity1 - activity2).abs();
      final similarityScore = 1.0 - activityDifference;

      // Boost score for highly active users
      final averageActivity = (activity1 + activity2) / 2;
      final activityBoost = averageActivity > 0.7 ? 0.2 : 0.0;

      final score = (similarityScore + activityBoost).clamp(0.0, 1.0);

      return score;
    } catch (e) {
      debugPrint('❌ Error calculating activity score: $e');
      return 0.5;
    }
  }

  /// Calculate user activity level (0.0 = inactive, 1.0 = very active)
  static double _calculateUserActivity(UserModel user) {
    double activityScore = 0;

    // Recent login activity
    if (user.lastSeen != null) {
      final daysSinceLastSeen =
          DateTime.now().difference(user.lastSeen!).inDays;
      if (daysSinceLastSeen <= 1) {
        activityScore += 0.4; // Very recent activity
      } else if (daysSinceLastSeen <= ACTIVITY_THRESHOLD_DAYS) {
        activityScore +=
            0.3 - (daysSinceLastSeen / ACTIVITY_THRESHOLD_DAYS) * 0.2;
      }
    }

    // Profile completeness indicates engagement
    final completeness = _calculateProfileCompleteness(user);
    activityScore += completeness * 0.3;

    // Number of photos indicates engagement
    final photoCount = user.imageUrl?.length ?? 0;
    if (photoCount >= 5) {
      activityScore += 0.2;
    } else if (photoCount >= 3) {
      activityScore += 0.1;
    }

    // Bio length indicates engagement
    final bioLength = user.bio?.length ?? 0;
    if (bioLength >= 100) {
      activityScore += 0.1;
    }

    return activityScore.clamp(0.0, 1.0);
  }

  /// Calculate profile completeness score
  /// Higher score for users with complete profiles
  static double _calculateCompletenessScore(UserModel user1, UserModel user2) {
    try {
      final completeness1 = _calculateProfileCompleteness(user1);
      final completeness2 = _calculateProfileCompleteness(user2);

      // Average completeness of both profiles
      final averageCompleteness = (completeness1 + completeness2) / 2;

      // Boost score if both profiles are highly complete
      final boost = (completeness1 > 0.8 && completeness2 > 0.8) ? 0.2 : 0.0;

      final score = (averageCompleteness + boost).clamp(0.0, 1.0);

      return score;
    } catch (e) {
      debugPrint('❌ Error calculating completeness score: $e');
      return 0.5;
    }
  }

  /// Calculate individual profile completeness (0.0 = empty, 1.0 = complete)
  static double _calculateProfileCompleteness(UserModel user) {
    double completeness = 0;
    int totalFields = 0;
    int completedFields = 0;

    // Essential fields
    final essentialFields = [
      user.name,
      user.age?.toString(),
      user.gender,
      user.bio,
    ];

    for (final field in essentialFields) {
      totalFields++;
      if (field != null && field.isNotEmpty) {
        completedFields++;
      }
    }

    // Photos
    totalFields++;
    if (user.imageUrl != null && user.imageUrl!.isNotEmpty) {
      completedFields++;
    }

    // Optional fields
    final optionalFields = [
      user.profession,
      user.education,
      user.address,
      user.drinkingStatus,
      user.smokingStatus,
    ];

    for (final field in optionalFields) {
      totalFields++;
      if (field != null && field.isNotEmpty) {
        completedFields++;
      }
    }

    // Location
    totalFields++;
    if (user.coordinates != null && user.coordinates!.isNotEmpty) {
      completedFields++;
    }

    completeness = totalFields > 0 ? completedFields / totalFields : 0.0;

    return completeness.clamp(0.0, 1.0);
  }

  /// Get detailed compatibility breakdown for debugging
  static CompatibilityBreakdown getCompatibilityBreakdown(
      UserModel user1, UserModel user2,) {
    final ageScore = _calculateAgeCompatibility(user1, user2);
    final locationScore = _calculateLocationScore(user1, user2);
    final interestScore = _calculateInterestScore(user1, user2);
    final activityScore = _calculateActivityScore(user1, user2);
    final completenessScore = _calculateCompletenessScore(user1, user2);

    final totalScore = (ageScore * AGE_WEIGHT) +
        (locationScore * LOCATION_WEIGHT) +
        (interestScore * INTEREST_WEIGHT) +
        (activityScore * ACTIVITY_WEIGHT) +
        (completenessScore * COMPLETENESS_WEIGHT);

    return CompatibilityBreakdown(
      totalScore: totalScore,
      ageScore: ageScore,
      locationScore: locationScore,
      interestScore: interestScore,
      activityScore: activityScore,
      completenessScore: completenessScore,
      user1Completeness: _calculateProfileCompleteness(user1),
      user2Completeness: _calculateProfileCompleteness(user2),
      user1Activity: _calculateUserActivity(user1),
      user2Activity: _calculateUserActivity(user2),
    );
  }

  /// Batch calculate compatibility scores for multiple users
  static List<UserCompatibility> calculateBatchCompatibility(
    UserModel currentUser,
    List<UserModel> targetUsers,
  ) {
    final results = <UserCompatibility>[];

    for (final targetUser in targetUsers) {
      final score = calculateCompatibility(currentUser, targetUser);
      results.add(UserCompatibility(
        user: targetUser,
        compatibilityScore: score,
      ),);
    }

    // Sort by compatibility score (highest first)
    results
        .sort((a, b) => b.compatibilityScore.compareTo(a.compatibilityScore));

    return results;
  }
}

/// Detailed compatibility breakdown for analysis
class CompatibilityBreakdown {

  const CompatibilityBreakdown({
    required this.totalScore,
    required this.ageScore,
    required this.locationScore,
    required this.interestScore,
    required this.activityScore,
    required this.completenessScore,
    required this.user1Completeness,
    required this.user2Completeness,
    required this.user1Activity,
    required this.user2Activity,
  });
  final double totalScore;
  final double ageScore;
  final double locationScore;
  final double interestScore;
  final double activityScore;
  final double completenessScore;
  final double user1Completeness;
  final double user2Completeness;
  final double user1Activity;
  final double user2Activity;

  @override
  String toString() => 'CompatibilityBreakdown(\n'
        '  Total: ${(totalScore * 100).toStringAsFixed(1)}%\n'
        '  Age: ${(ageScore * 100).toStringAsFixed(1)}%\n'
        '  Location: ${(locationScore * 100).toStringAsFixed(1)}%\n'
        '  Interest: ${(interestScore * 100).toStringAsFixed(1)}%\n'
        '  Activity: ${(activityScore * 100).toStringAsFixed(1)}%\n'
        '  Completeness: ${(completenessScore * 100).toStringAsFixed(1)}%\n'
        ')';
}

/// User with compatibility score
class UserCompatibility {

  const UserCompatibility({
    required this.user,
    required this.compatibilityScore,
  });
  final UserModel user;
  final double compatibilityScore;

  /// Get compatibility percentage as string
  String get compatibilityPercentage =>
      '${(compatibilityScore * 100).toStringAsFixed(1)}%';

  /// Check if this is a high compatibility match
  bool get isHighCompatibility => compatibilityScore >= 0.7;

  /// Check if this is a medium compatibility match
  bool get isMediumCompatibility =>
      compatibilityScore >= 0.5 && compatibilityScore < 0.7;

  /// Check if this is a low compatibility match
  bool get isLowCompatibility => compatibilityScore < 0.5;

  @override
  String toString() => 'UserCompatibility(${user.name}: $compatibilityPercentage)';
}
