import 'package:flutter/foundation.dart';

import '../common/utils/distance.dart' as geo;
import '../features/match/data/services/compatibility_engine.dart';
import '../models/user_model.dart';
import 'match_config.dart';

/// Mode-specific compatibility engine that calculates different scores based on relationship intent
/// Implements Priority 2: Enhanced Matching Algorithm with mode differentiation
class ModeSpecificCompatibilityEngine {
  /// Calculate compatibility score based on the selected mode
  /// Returns a score between 0.0 (no compatibility) and 1.0 (perfect match)
  static double calculateModeCompatibility(
    UserModel user1,
    UserModel user2,
    String mode, {
    MatchConfig config = MatchConfig.defaults,
  }) {
    try {
      switch (mode) {
        case 'Dating':
          return _calculateDatingCompatibility(user1, user2, config);
        case 'Friendship':
          return _calculateFriendshipCompatibility(user1, user2, config);
        case 'Networking':
          return _calculateNetworkingCompatibility(user1, user2, config);
        default:
          return CompatibilityEngine.calculateCompatibility(user1, user2);
      }
    } on Object catch (e) {
      debugPrint('❌ Error calculating mode compatibility: $e');
      return 0.5;
    }
  }

  /// Calculate dating-specific compatibility
  /// Focuses on romantic compatibility factors
  static double _calculateDatingCompatibility(
    UserModel user1,
    UserModel user2,
    MatchConfig config,
  ) {
    final w = config.datingWeights;
    final ageScore = _calculateAgeCompatibility(user1, user2);
    final locationScore = _calculateLocationScore(user1, user2, config);
    final lifestyleScore = _calculateLifestyleCompatibility(user1, user2);
    final interestScore = _calculateInterestScore(user1, user2);
    final completenessScore = _calculateCompletenessScore(user1, user2);

    double totalScore = ageScore * w.age +
        locationScore * w.location +
        lifestyleScore * w.lifestyle +
        interestScore * w.interest +
        completenessScore * w.completeness;
    totalScore = totalScore.clamp(0.0, 1.0);

    debugPrint(
      '💕 Dating Compatibility ${user1.name} ↔ ${user2.name}: ${(totalScore * 100).toStringAsFixed(1)}%',
    );
    debugPrint(
      '   Age: ${(ageScore * 100).toStringAsFixed(1)}%, Location: ${(locationScore * 100).toStringAsFixed(1)}%, Lifestyle: ${(lifestyleScore * 100).toStringAsFixed(1)}%, Interest: ${(interestScore * 100).toStringAsFixed(1)}%, Completeness: ${(completenessScore * 100).toStringAsFixed(1)}%',
    );

    return totalScore;
  }

  /// Calculate friendship-specific compatibility
  /// Focuses on social compatibility factors
  static double _calculateFriendshipCompatibility(
    UserModel user1,
    UserModel user2,
    MatchConfig config,
  ) {
    final w = config.friendshipWeights;
    final socialScore = _calculateSocialCompatibility(user1, user2);
    final interestScore = _calculateInterestScore(user1, user2);
    final locationScore = _calculateLocationScore(user1, user2, config);
    final ageScore = _calculateAgeCompatibility(user1, user2);
    final completenessScore = _calculateCompletenessScore(user1, user2);

    double totalScore = socialScore * w.social +
        interestScore * w.interest +
        locationScore * w.location +
        ageScore * w.age +
        completenessScore * w.completeness;
    totalScore = totalScore.clamp(0.0, 1.0);

    debugPrint(
      '🤝 Friendship Compatibility ${user1.name} ↔ ${user2.name}: ${(totalScore * 100).toStringAsFixed(1)}%',
    );
    debugPrint(
      '   Social: ${(socialScore * 100).toStringAsFixed(1)}%, Interest: ${(interestScore * 100).toStringAsFixed(1)}%, Location: ${(locationScore * 100).toStringAsFixed(1)}%, Age: ${(ageScore * 100).toStringAsFixed(1)}%, Completeness: ${(completenessScore * 100).toStringAsFixed(1)}%',
    );

    return totalScore;
  }

  /// Calculate networking-specific compatibility
  /// Focuses on professional compatibility factors
  static double _calculateNetworkingCompatibility(
    UserModel user1,
    UserModel user2,
    MatchConfig config,
  ) {
    final w = config.networkingWeights;
    final professionalScore = _calculateProfessionalCompatibility(user1, user2);
    final industryScore = _calculateIndustryCompatibility(user1, user2);
    final locationScore = _calculateLocationScore(user1, user2, config);
    final completenessScore = _calculateCompletenessScore(user1, user2);

    double totalScore = professionalScore * w.professional +
        industryScore * w.industry +
        locationScore * w.location +
        completenessScore * w.completeness;
    totalScore = totalScore.clamp(0.0, 1.0);

    debugPrint(
      '💼 Networking Compatibility ${user1.name} ↔ ${user2.name}: ${(totalScore * 100).toStringAsFixed(1)}%',
    );
    debugPrint(
      '   Professional: ${(professionalScore * 100).toStringAsFixed(1)}%, Industry: ${(industryScore * 100).toStringAsFixed(1)}%, Location: ${(locationScore * 100).toStringAsFixed(1)}%, Completeness: ${(completenessScore * 100).toStringAsFixed(1)}%',
    );

    return totalScore;
  }

  // Helper methods for specific compatibility calculations

  static double _calculateLocationScore(
    UserModel user1,
    UserModel user2, [
    MatchConfig config = MatchConfig.defaults,
  ]) {
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

      final distanceMiles = geo.calculateDistance(lat1, lng1, lat2, lng2);
      final perfect = config.locationPerfectMiles;
      final decay = config.locationDecayMiles;
      final floor = config.locationFloorScore;

      if (distanceMiles <= perfect) {
        return 1;
      } else if (distanceMiles <= decay) {
        return 1.0 -
            ((distanceMiles - perfect) / (decay - perfect)) * (1.0 - floor);
      } else {
        return floor;
      }
    } on Object catch (e) {
      debugPrint('❌ Error calculating location score: $e');
      return 0.5;
    }
  }

  static double _calculateLifestyleCompatibility(
    UserModel user1,
    UserModel user2,
  ) {
    try {
      double totalScore = 0;
      int dimensions = 0;

      // Drinking habits
      if (user1.drinkingStatus != null &&
          user1.drinkingStatus!.isNotEmpty &&
          user2.drinkingStatus != null &&
          user2.drinkingStatus!.isNotEmpty) {
        totalScore += user1.drinkingStatus!.toLowerCase() ==
                user2.drinkingStatus!.toLowerCase()
            ? 1.0
            : 0.3;
        dimensions++;
      }

      // Smoking habits
      if (user1.smokingStatus != null &&
          user1.smokingStatus!.isNotEmpty &&
          user2.smokingStatus != null &&
          user2.smokingStatus!.isNotEmpty) {
        totalScore += user1.smokingStatus!.toLowerCase() ==
                user2.smokingStatus!.toLowerCase()
            ? 1.0
            : 0.3;
        dimensions++;
      }

      // Religion
      if (user1.religion != null &&
          user1.religion!.isNotEmpty &&
          user2.religion != null &&
          user2.religion!.isNotEmpty) {
        totalScore +=
            user1.religion!.toLowerCase() == user2.religion!.toLowerCase()
                ? 1.0
                : 0.4;
        dimensions++;
      }

      if (dimensions == 0) {
        return 0.5;
      }
      return (totalScore / dimensions).clamp(0.0, 1.0);
    } on Object catch (e) {
      debugPrint('❌ Error calculating lifestyle compatibility: $e');
      return 0.5;
    }
  }

  static double _calculateSocialCompatibility(
    UserModel user1,
    UserModel user2,
  ) {
    try {
      double totalScore = 0;
      int dimensions = 0;

      // Language overlap (Jaccard similarity)
      final langs1 = user1.languages
              ?.where((l) => l.isNotEmpty)
              .map((l) => l.toLowerCase())
              .toSet() ??
          <String>{};
      final langs2 = user2.languages
              ?.where((l) => l.isNotEmpty)
              .map((l) => l.toLowerCase())
              .toSet() ??
          <String>{};
      if (langs1.isNotEmpty && langs2.isNotEmpty) {
        final intersection = langs1.intersection(langs2);
        final union = langs1.union(langs2);
        totalScore += union.isNotEmpty ? intersection.length / union.length : 0;
        dimensions++;
      }

      // Tribe / cultural affinity
      if (user1.tribe != null &&
          user1.tribe!.isNotEmpty &&
          user2.tribe != null &&
          user2.tribe!.isNotEmpty) {
        totalScore += user1.tribe!.toLowerCase() == user2.tribe!.toLowerCase()
            ? 1.0
            : 0.4;
        dimensions++;
      }

      // Nationality
      if (user1.nationality != null &&
          user1.nationality!.isNotEmpty &&
          user2.nationality != null &&
          user2.nationality!.isNotEmpty) {
        totalScore +=
            user1.nationality!.toLowerCase() == user2.nationality!.toLowerCase()
                ? 1.0
                : 0.5;
        dimensions++;
      }

      if (dimensions == 0) {
        return 0.5;
      }
      return (totalScore / dimensions).clamp(0.0, 1.0);
    } on Object catch (e) {
      debugPrint('❌ Error calculating social compatibility: $e');
      return 0.5;
    }
  }

  static double _calculateProfessionalCompatibility(
    UserModel user1,
    UserModel user2,
  ) {
    try {
      double totalScore = 0;
      int dimensions = 0;

      // Occupation / profession similarity
      final occ1 = (user1.occupation ?? user1.profession ?? '').toLowerCase();
      final occ2 = (user2.occupation ?? user2.profession ?? '').toLowerCase();
      if (occ1.isNotEmpty && occ2.isNotEmpty) {
        if (occ1 == occ2) {
          totalScore += 1.0;
        } else {
          final words1 = occ1.split(RegExp(r'\s+')).toSet();
          final words2 = occ2.split(RegExp(r'\s+')).toSet();
          final overlap = words1.intersection(words2).length;
          totalScore += overlap > 0 ? 0.7 : 0.3;
        }
        dimensions++;
      }

      // Education level
      if (user1.education != null &&
          user1.education!.isNotEmpty &&
          user2.education != null &&
          user2.education!.isNotEmpty) {
        totalScore +=
            user1.education!.toLowerCase() == user2.education!.toLowerCase()
                ? 1.0
                : 0.5;
        dimensions++;
      }

      // Company / industry overlap via job_title
      final job1 = user1.job_title?.toLowerCase() ?? '';
      final job2 = user2.job_title?.toLowerCase() ?? '';
      if (job1.isNotEmpty && job2.isNotEmpty) {
        if (job1 == job2) {
          totalScore += 1.0;
        } else {
          final words1 = job1.split(RegExp(r'\s+')).toSet();
          final words2 = job2.split(RegExp(r'\s+')).toSet();
          final overlap = words1.intersection(words2).length;
          totalScore += overlap > 0 ? 0.7 : 0.4;
        }
        dimensions++;
      }

      if (dimensions == 0) {
        return 0.5;
      }
      return (totalScore / dimensions).clamp(0.0, 1.0);
    } on Object catch (e) {
      debugPrint('❌ Error calculating professional compatibility: $e');
      return 0.5;
    }
  }

  static double _calculateIndustryCompatibility(
    UserModel user1,
    UserModel user2,
  ) {
    try {
      // Compare job titles and industries
      final job1 = user1.job_title?.toLowerCase() ?? '';
      final job2 = user2.job_title?.toLowerCase() ?? '';

      if (job1.isEmpty || job2.isEmpty) {
        return 0.5; // Neutral if no job info
      }

      // Simple keyword matching for now
      final techKeywords = [
        'engineer',
        'developer',
        'programmer',
        'tech',
        'software',
        'it',
      ];
      final businessKeywords = [
        'manager',
        'director',
        'executive',
        'business',
        'sales',
        'marketing',
      ];
      final creativeKeywords = [
        'designer',
        'artist',
        'creative',
        'writer',
        'photographer',
      ];

      final isTech1 = techKeywords.any(job1.contains);
      final isTech2 = techKeywords.any(job2.contains);
      final isBusiness1 = businessKeywords.any(job1.contains);
      final isBusiness2 = businessKeywords.any(job2.contains);
      final isCreative1 = creativeKeywords.any(job1.contains);
      final isCreative2 = creativeKeywords.any(job2.contains);

      if ((isTech1 && isTech2) ||
          (isBusiness1 && isBusiness2) ||
          (isCreative1 && isCreative2)) {
        return 1; // Same industry
      } else if ((isTech1 && isBusiness2) || (isBusiness1 && isTech2)) {
        return 0.8; // Complementary industries
      } else {
        return 0.6; // Different industries
      }
    } on Object catch (e) {
      debugPrint('❌ Error calculating industry compatibility: $e');
      return 0.5;
    }
  }

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

      final jaccard = intersection.length / union.length;
      final sharedBoost = intersection.length >= 3
          ? 0.2
          : (intersection.length >= 2 ? 0.1 : 0.0);

      return (jaccard + sharedBoost).clamp(0.0, 1.0);
    } on Object catch (e) {
      debugPrint('❌ Error calculating interest score: $e');
      return 0.5;
    }
  }

  static Set<String> _extractInterests(UserModel user) {
    final interests = <String>{};

    if (user.bio != null && user.bio!.isNotEmpty) {
      interests.addAll(
        user.bio!
            .toLowerCase()
            .replaceAll(RegExp(r'[^\w\s]'), ' ')
            .split(' ')
            .where((w) => w.length > 3),
      );
    }

    if (user.profession != null && user.profession!.isNotEmpty) {
      interests.add(user.profession!.toLowerCase());
    }

    if (user.education != null && user.education!.isNotEmpty) {
      interests.add(user.education!.toLowerCase());
    }

    if (user.drinkingStatus != null && user.drinkingStatus!.isNotEmpty) {
      interests.add('drinking_${user.drinkingStatus!.toLowerCase()}');
    }

    if (user.smokingStatus != null && user.smokingStatus!.isNotEmpty) {
      interests.add('smoking_${user.smokingStatus!.toLowerCase()}');
    }

    return interests;
  }

  static double _calculateAgeCompatibility(UserModel user1, UserModel user2) {
    try {
      final age1 = user1.age ?? 25;
      final age2 = user2.age ?? 25;
      final ageDifference = (age1 - age2).abs();

      if (ageDifference <= 3) {
        return 1; // Perfect score for small age difference
      } else if (ageDifference <= 10) {
        return 1.0 - ((ageDifference - 3) / 7) * 0.7; // Linear decrease
      } else {
        return 0.3; // Low score for large age differences
      }
    } on Object catch (e) {
      debugPrint('❌ Error calculating age compatibility: $e');
      return 0.5;
    }
  }

  static double _calculateCompletenessScore(UserModel user1, UserModel user2) {
    try {
      // Calculate profile completeness for both users
      int user1Score = 0;
      int user2Score = 0;

      // Check various profile fields
      if (user1.name?.isNotEmpty ?? false) {
        user1Score++;
      }
      if (user1.bio?.isNotEmpty ?? false) {
        user1Score++;
      }
      if (user1.job_title?.isNotEmpty ?? false) {
        user1Score++;
      }
      if (user1.imageUrl?.isNotEmpty ?? false) {
        user1Score++;
      }
      if (user1.coordinates != null) {
        user1Score++;
      }

      if (user2.name?.isNotEmpty ?? false) {
        user2Score++;
      }
      if (user2.bio?.isNotEmpty ?? false) {
        user2Score++;
      }
      if (user2.job_title?.isNotEmpty ?? false) {
        user2Score++;
      }
      if (user2.imageUrl?.isNotEmpty ?? false) {
        user2Score++;
      }
      if (user2.coordinates != null) {
        user2Score++;
      }

      // Return average completeness
      return (user1Score + user2Score) / 10.0;
    } on Object catch (e) {
      debugPrint('❌ Error calculating completeness score: $e');
      return 0.5;
    }
  }

  /// Get compatibility breakdown for debugging
  static Map<String, double> getCompatibilityBreakdown(
    UserModel user1,
    UserModel user2,
    String mode, {
    MatchConfig config = MatchConfig.defaults,
  }) {
    switch (mode) {
      case 'Dating':
        final w = config.datingWeights;
        return {
          'age': _calculateAgeCompatibility(user1, user2) * w.age,
          'location':
              _calculateLocationScore(user1, user2, config) * w.location,
          'lifestyle':
              _calculateLifestyleCompatibility(user1, user2) * w.lifestyle,
          'interest': _calculateInterestScore(user1, user2) * w.interest,
          'completeness':
              _calculateCompletenessScore(user1, user2) * w.completeness,
        };
      case 'Friendship':
        final w = config.friendshipWeights;
        return {
          'social': _calculateSocialCompatibility(user1, user2) * w.social,
          'interest': _calculateInterestScore(user1, user2) * w.interest,
          'location':
              _calculateLocationScore(user1, user2, config) * w.location,
          'age': _calculateAgeCompatibility(user1, user2) * w.age,
          'completeness':
              _calculateCompletenessScore(user1, user2) * w.completeness,
        };
      case 'Networking':
        final w = config.networkingWeights;
        return {
          'professional': _calculateProfessionalCompatibility(user1, user2) *
              w.professional,
          'industry':
              _calculateIndustryCompatibility(user1, user2) * w.industry,
          'location':
              _calculateLocationScore(user1, user2, config) * w.location,
          'completeness':
              _calculateCompletenessScore(user1, user2) * w.completeness,
        };
      default:
        return {
          'overall': CompatibilityEngine.calculateCompatibility(user1, user2),
        };
    }
  }
}
