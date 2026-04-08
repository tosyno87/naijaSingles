import 'package:flutter/foundation.dart';

import '../../../../common/utils/distance.dart' as distance;
import '../../../../models/user_model.dart';

/// Compatibility engine that calculates match scores between users
/// Implements Priority 2: Enhanced Matching Algorithm
class CompatibilityEngine {
  // Scoring weights (must sum to 1.0)
  static const double ageWeight = 0.20; // 20%
  static const double locationWeight = 0.25; // 25%
  static const double interestWeight = 0.20; // 20%
  static const double activityWeight = 0.10; // 10%
  static const double completenessWeight = 0.10; // 10%
  static const double cultureWeight = 0.15; // 15% — nationality & tribe

  // Scoring parameters
  static const int idealAgeDifference = 3; // Years
  static const int maxAgeDifference = 10; // Years
  static const double maxDistanceMiles = 31; // Miles (converted from 50km)
  static const int activityThresholdDays = 7; // Days

  /// Calculate overall compatibility score between two users
  /// Returns a score between 0.0 (no compatibility) and 1.0 (perfect match)
  static double calculateCompatibility(UserModel user1, UserModel user2) {
    try {
      double totalScore = 0;

      // Age compatibility (25%)
      final ageScore = _calculateAgeCompatibility(user1, user2);
      totalScore += ageScore * ageWeight;

      // Location proximity (30%)
      final locationScore = _calculateLocationScore(user1, user2);
      totalScore += locationScore * locationWeight;

      // Interest matching (20%)
      final interestScore = _calculateInterestScore(user1, user2);
      totalScore += interestScore * interestWeight;

      // Activity level (15%)
      final activityScore = _calculateActivityScore(user1, user2);
      totalScore += activityScore * activityWeight;

      // Profile completeness (10%)
      final completenessScore = _calculateCompletenessScore(user1, user2);
      totalScore += completenessScore * completenessWeight;

      // Nationality & tribe affinity (15%)
      final cultureScore = _calculateCultureScore(user1, user2);
      totalScore += cultureScore * cultureWeight;

      // Ensure score is within bounds
      totalScore = totalScore.clamp(0.0, 1.0);

      debugPrint(
        '🎯 Compatibility ${user1.name} ↔ ${user2.name}: ${(totalScore * 100).toStringAsFixed(1)}%',
      );
      debugPrint(
        '   Age: ${(ageScore * 100).toStringAsFixed(1)}%, Location: ${(locationScore * 100).toStringAsFixed(1)}%, Interest: ${(interestScore * 100).toStringAsFixed(1)}%, Activity: ${(activityScore * 100).toStringAsFixed(1)}%, Completeness: ${(completenessScore * 100).toStringAsFixed(1)}%, Culture: ${(cultureScore * 100).toStringAsFixed(1)}%',
      );

      return totalScore;
    } on Object catch (e) {
      debugPrint('❌ Error calculating compatibility: $e');
      return 0.5; // Return neutral score on error
    }
  }

  /// Calculate age compatibility score
  static double _calculateAgeCompatibility(UserModel user1, UserModel user2) {
    try {
      final age1 = user1.age ?? 25;
      final age2 = user2.age ?? 25;
      final ageDifference = (age1 - age2).abs();

      if (ageDifference <= idealAgeDifference) {
        return 1;
      } else if (ageDifference <= maxAgeDifference) {
        final score = 1.0 -
            ((ageDifference - idealAgeDifference) /
                    (maxAgeDifference - idealAgeDifference)) *
                0.7;
        return score.clamp(0.3, 1.0);
      } else {
        return 0.1;
      }
    } on Object catch (e) {
      debugPrint('❌ Error calculating age compatibility: $e');
      return 0.5;
    }
  }

  /// Nationality and tribe overlap (0.0–1.0). Both fields must be present on
  /// both users to contribute; same nationality/tribe adds more than mismatch.
  static double _calculateCultureScore(UserModel user1, UserModel user2) {
    var score = 0.0;
    final n1 = user1.nationality?.trim();
    final n2 = user2.nationality?.trim();
    if (n1 != null && n1.isNotEmpty && n2 != null && n2.isNotEmpty) {
      if (n1.toLowerCase() == n2.toLowerCase()) {
        score += 0.6;
      } else {
        score += 0.1;
      }
    }
    final t1 = user1.tribe?.trim();
    final t2 = user2.tribe?.trim();
    if (t1 != null && t1.isNotEmpty && t2 != null && t2.isNotEmpty) {
      if (t1.toLowerCase() == t2.toLowerCase()) {
        score += 0.4;
      } else {
        score += 0.05;
      }
    }
    return score.clamp(0.0, 1.0);
  }

  /// Calculate location proximity score
  static double _calculateLocationScore(UserModel user1, UserModel user2) {
    try {
      if (user1.coordinates == null ||
          user2.coordinates == null ||
          user1.coordinates!.isEmpty ||
          user2.coordinates!.isEmpty) {
        return 0.5;
      }

      final lat1 = user1.coordinates!['latitude'] as double?;
      final lng1 = user1.coordinates!['longitude'] as double?;
      final lat2 = user2.coordinates!['latitude'] as double?;
      final lng2 = user2.coordinates!['longitude'] as double?;

      if (lat1 == null || lng1 == null || lat2 == null || lng2 == null) {
        return 0.5;
      }

      final distanceKm = distance.calculateDistance(lat1, lng1, lat2, lng2);

      if (distanceKm <= 3.1) {
        return 1;
      } else if (distanceKm <= maxDistanceMiles) {
        final score =
            1.0 - ((distanceKm - 3.1) / (maxDistanceMiles - 3.1)) * 0.8;
        return score.clamp(0.2, 1.0);
      } else {
        return 0.1;
      }
    } on Object catch (e) {
      debugPrint('❌ Error calculating location score: $e');
      return 0.5;
    }
  }

  /// Calculate interest matching score
  static double _calculateInterestScore(UserModel user1, UserModel user2) {
    try {
      final interests1 = _extractInterests(user1);
      final interests2 = _extractInterests(user2);

      if (interests1.isEmpty || interests2.isEmpty) {
        return 0.3;
      }

      final intersection = interests1.intersection(interests2);
      final union = interests1.union(interests2);

      if (union.isEmpty) {
        return 0.3;
      }

      final jaccardSimilarity = intersection.length / union.length;
      final sharedCount = intersection.length;
      final boost = sharedCount >= 3 ? 0.2 : (sharedCount >= 2 ? 0.1 : 0.0);

      return (jaccardSimilarity + boost).clamp(0.0, 1.0);
    } on Object catch (e) {
      debugPrint('❌ Error calculating interest score: $e');
      return 0.5;
    }
  }

  static Set<String> _extractInterests(UserModel user) {
    final interests = <String>{};

    if (user.bio != null && user.bio!.isNotEmpty) {
      final bioWords = user.bio!
          .toLowerCase()
          .replaceAll(RegExp(r'[^\w\s]'), ' ')
          .split(' ')
          .where((word) => word.length > 3)
          .toSet();
      interests.addAll(bioWords);
    }

    if (user.address != null && user.address!.isNotEmpty) {
      final locationWords = user.address!
          .toLowerCase()
          .split(' ')
          .where((word) => word.length > 3)
          .toSet();
      interests.addAll(locationWords);
    }

    if (user.profession != null && user.profession!.isNotEmpty) {
      interests.add(user.profession!.toLowerCase());
    }

    if (user.education != null && user.education!.isNotEmpty) {
      interests.add(user.education!.toLowerCase());
    }

    if (user.drinkingStatus != null) {
      interests.add('drinking_${user.drinkingStatus!.toLowerCase()}');
    }

    if (user.smokingStatus != null) {
      interests.add('smoking_${user.smokingStatus!.toLowerCase()}');
    }

    return interests;
  }

  static double _calculateActivityScore(UserModel user1, UserModel user2) {
    try {
      final activity1 = _calculateUserActivity(user1);
      final activity2 = _calculateUserActivity(user2);
      final activityDifference = (activity1 - activity2).abs();
      final similarityScore = 1.0 - activityDifference;
      final averageActivity = (activity1 + activity2) / 2;
      final activityBoost = averageActivity > 0.7 ? 0.2 : 0.0;
      return (similarityScore + activityBoost).clamp(0.0, 1.0);
    } on Object catch (e) {
      debugPrint('❌ Error calculating activity score: $e');
      return 0.5;
    }
  }

  static double _calculateUserActivity(UserModel user) {
    double activityScore = 0;

    if (user.lastSeen != null) {
      final daysSinceLastSeen =
          DateTime.now().difference(user.lastSeen!).inDays;
      if (daysSinceLastSeen <= 1) {
        activityScore += 0.4;
      } else if (daysSinceLastSeen <= activityThresholdDays) {
        activityScore +=
            0.3 - (daysSinceLastSeen / activityThresholdDays) * 0.2;
      }
    }

    final completeness = _calculateProfileCompleteness(user);
    activityScore += completeness * 0.3;

    final photoCount = user.imageUrl?.length ?? 0;
    if (photoCount >= 5) {
      activityScore += 0.2;
    } else if (photoCount >= 3) {
      activityScore += 0.1;
    }

    final bioLength = user.bio?.length ?? 0;
    if (bioLength >= 100) {
      activityScore += 0.1;
    }

    return activityScore.clamp(0.0, 1.0);
  }

  static double _calculateCompletenessScore(UserModel user1, UserModel user2) {
    try {
      final completeness1 = _calculateProfileCompleteness(user1);
      final completeness2 = _calculateProfileCompleteness(user2);
      final averageCompleteness = (completeness1 + completeness2) / 2;
      final boost = (completeness1 > 0.8 && completeness2 > 0.8) ? 0.2 : 0.0;
      return (averageCompleteness + boost).clamp(0.0, 1.0);
    } on Object catch (e) {
      debugPrint('❌ Error calculating completeness score: $e');
      return 0.5;
    }
  }

  static double _calculateProfileCompleteness(UserModel user) {
    double completeness = 0;
    int totalFields = 0;
    int completedFields = 0;

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

    totalFields++;
    if (user.imageUrl != null && user.imageUrl!.isNotEmpty) {
      completedFields++;
    }

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

    totalFields++;
    if (user.coordinates != null && user.coordinates!.isNotEmpty) {
      completedFields++;
    }

    completeness = totalFields > 0 ? completedFields / totalFields : 0.0;
    return completeness.clamp(0.0, 1.0);
  }

  static CompatibilityBreakdown getCompatibilityBreakdown(
    UserModel user1,
    UserModel user2,
  ) {
    final ageScore = _calculateAgeCompatibility(user1, user2);
    final locationScore = _calculateLocationScore(user1, user2);
    final interestScore = _calculateInterestScore(user1, user2);
    final activityScore = _calculateActivityScore(user1, user2);
    final completenessScore = _calculateCompletenessScore(user1, user2);
    final cultureScore = _calculateCultureScore(user1, user2);

    final totalScore = (ageScore * ageWeight) +
        (locationScore * locationWeight) +
        (interestScore * interestWeight) +
        (activityScore * activityWeight) +
        (completenessScore * completenessWeight) +
        (cultureScore * cultureWeight);

    return CompatibilityBreakdown(
      totalScore: totalScore,
      ageScore: ageScore,
      locationScore: locationScore,
      interestScore: interestScore,
      activityScore: activityScore,
      completenessScore: completenessScore,
      cultureScore: cultureScore,
      user1Completeness: _calculateProfileCompleteness(user1),
      user2Completeness: _calculateProfileCompleteness(user2),
      user1Activity: _calculateUserActivity(user1),
      user2Activity: _calculateUserActivity(user2),
    );
  }

  static List<UserCompatibility> calculateBatchCompatibility(
    UserModel currentUser,
    List<UserModel> targetUsers,
  ) {
    final results = <UserCompatibility>[];

    for (final targetUser in targetUsers) {
      final score = calculateCompatibility(currentUser, targetUser);
      results.add(
        UserCompatibility(
          user: targetUser,
          compatibilityScore: score,
        ),
      );
    }

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
    required this.cultureScore,
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
  final double cultureScore;
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
      '  Culture: ${(cultureScore * 100).toStringAsFixed(1)}%\n'
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

  String get compatibilityPercentage =>
      '${(compatibilityScore * 100).toStringAsFixed(1)}%';

  bool get isHighCompatibility => compatibilityScore >= 0.7;

  bool get isMediumCompatibility =>
      compatibilityScore >= 0.5 && compatibilityScore < 0.7;

  bool get isLowCompatibility => compatibilityScore < 0.5;

  @override
  String toString() =>
      'UserCompatibility(${user.name}: $compatibilityPercentage)';
}
