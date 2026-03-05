import 'package:flutter/foundation.dart';

import '../features/match/data/services/compatibility_engine.dart';
import '../models/user_model.dart';

/// Mode-specific compatibility engine that calculates different scores based on relationship intent
/// Implements Priority 2: Enhanced Matching Algorithm with mode differentiation
class ModeSpecificCompatibilityEngine {
  /// Calculate compatibility score based on the selected mode
  /// Returns a score between 0.0 (no compatibility) and 1.0 (perfect match)
  static double calculateModeCompatibility(
    UserModel user1,
    UserModel user2,
    String mode,
  ) {
    try {
      switch (mode) {
        case 'Dating':
          return _calculateDatingCompatibility(user1, user2);
        case 'Friendship':
          return _calculateFriendshipCompatibility(user1, user2);
        case 'Networking':
          return _calculateNetworkingCompatibility(user1, user2);
        default:
          return CompatibilityEngine.calculateCompatibility(user1, user2);
      }
    } on Object catch (e) {
      debugPrint('❌ Error calculating mode compatibility: $e');
      return 0.5; // Return neutral score on error
    }
  }

  /// Calculate dating-specific compatibility
  /// Focuses on romantic compatibility factors
  static double _calculateDatingCompatibility(
    UserModel user1,
    UserModel user2,
  ) {
    double totalScore = 0;

    // Age compatibility (30% - more important for dating)
    final ageScore = CompatibilityEngine.calculateCompatibility(user1, user2);
    totalScore += ageScore * 0.30;

    // Location proximity (25% - important for dating)
    final locationScore = _calculateLocationScore(user1, user2);
    totalScore += locationScore * 0.25;

    // Lifestyle compatibility (20% - new for dating)
    final lifestyleScore = _calculateLifestyleCompatibility(user1, user2);
    totalScore += lifestyleScore * 0.20;

    // Interest alignment (15% - shared activities)
    final interestScore = _calculateInterestScore(user1, user2);
    totalScore += interestScore * 0.15;

    // Profile completeness (10% - effort in profile)
    final completenessScore = _calculateCompletenessScore(user1, user2);
    totalScore += completenessScore * 0.10;

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
  ) {
    double totalScore = 0;

    // Social activity alignment (35% - most important for friendship)
    final socialScore = _calculateSocialCompatibility(user1, user2);
    totalScore += socialScore * 0.35;

    // Interest overlap (25% - shared hobbies)
    final interestScore = _calculateInterestScore(user1, user2);
    totalScore += interestScore * 0.25;

    // Location proximity (20% - easier to meet up)
    final locationScore = _calculateLocationScore(user1, user2);
    totalScore += locationScore * 0.20;

    // Age compatibility (10% - less strict for friendship)
    final ageScore = _calculateAgeCompatibility(user1, user2);
    totalScore += ageScore * 0.10;

    // Profile completeness (10% - effort in profile)
    final completenessScore = _calculateCompletenessScore(user1, user2);
    totalScore += completenessScore * 0.10;

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
  ) {
    double totalScore = 0;

    // Professional alignment (40% - most important for networking)
    final professionalScore = _calculateProfessionalCompatibility(user1, user2);
    totalScore += professionalScore * 0.40;

    // Industry compatibility (25% - same or complementary industries)
    final industryScore = _calculateIndustryCompatibility(user1, user2);
    totalScore += industryScore * 0.25;

    // Location proximity (20% - business meetings)
    final locationScore = _calculateLocationScore(user1, user2);
    totalScore += locationScore * 0.20;

    // Profile completeness (15% - professional profile quality)
    final completenessScore = _calculateCompletenessScore(user1, user2);
    totalScore += completenessScore * 0.15;

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

  static double _calculateLocationScore(UserModel user1, UserModel user2) {
    try {
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
        return 0.5;
      }

      // Calculate distance (simplified - you might want to use a proper distance calculation)
      final distance = ((lat1 - lat2).abs() + (lng1 - lng2).abs()) *
          111; // Rough km conversion

      if (distance <= 5.0) {
        return 1; // Perfect score for very close users
      } else if (distance <= 50.0) {
        return 1.0 - ((distance - 5.0) / 45.0) * 0.8; // Linear decrease
      } else {
        return 0.2; // Low score for distant users
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
      // This would compare lifestyle factors like:
      // - Drinking habits
      // - Smoking habits
      // - Fitness level
      // - Sleep schedule
      // - Social preferences

      // For now, return a neutral score
      // In a real implementation, you'd compare these fields from user profiles
      return 0.7; // Default good compatibility
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
      // This would compare social factors like:
      // - Group activity preferences
      // - Social energy level
      // - Meeting style preferences
      // - Friend group size preferences

      // For now, return a neutral score
      return 0.7; // Default good compatibility
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
      // This would compare professional factors like:
      // - Career level compatibility
      // - Professional goals alignment
      // - Collaboration style
      // - Networking preferences

      // For now, return a neutral score
      return 0.7; // Default good compatibility
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
      // This would compare user interests
      // For now, return a neutral score
      return 0.7; // Default good compatibility
    } on Object catch (e) {
      debugPrint('❌ Error calculating interest score: $e');
      return 0.5;
    }
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
      if (user1.name?.isNotEmpty ?? false) user1Score++;
      if (user1.bio?.isNotEmpty ?? false) user1Score++;
      if (user1.job_title?.isNotEmpty ?? false) user1Score++;
      if (user1.imageUrl?.isNotEmpty ?? false) user1Score++;
      if (user1.coordinates != null) user1Score++;

      if (user2.name?.isNotEmpty ?? false) user2Score++;
      if (user2.bio?.isNotEmpty ?? false) user2Score++;
      if (user2.job_title?.isNotEmpty ?? false) user2Score++;
      if (user2.imageUrl?.isNotEmpty ?? false) user2Score++;
      if (user2.coordinates != null) user2Score++;

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
    String mode,
  ) {
    switch (mode) {
      case 'Dating':
        return {
          'age':
              CompatibilityEngine.calculateCompatibility(user1, user2) * 0.30,
          'location': _calculateLocationScore(user1, user2) * 0.25,
          'lifestyle': _calculateLifestyleCompatibility(user1, user2) * 0.20,
          'interest': _calculateInterestScore(user1, user2) * 0.15,
          'completeness': _calculateCompletenessScore(user1, user2) * 0.10,
        };
      case 'Friendship':
        return {
          'social': _calculateSocialCompatibility(user1, user2) * 0.35,
          'interest': _calculateInterestScore(user1, user2) * 0.25,
          'location': _calculateLocationScore(user1, user2) * 0.20,
          'age': _calculateAgeCompatibility(user1, user2) * 0.10,
          'completeness': _calculateCompletenessScore(user1, user2) * 0.10,
        };
      case 'Networking':
        return {
          'professional':
              _calculateProfessionalCompatibility(user1, user2) * 0.40,
          'industry': _calculateIndustryCompatibility(user1, user2) * 0.25,
          'location': _calculateLocationScore(user1, user2) * 0.20,
          'completeness': _calculateCompletenessScore(user1, user2) * 0.15,
        };
      default:
        return {
          'overall': CompatibilityEngine.calculateCompatibility(user1, user2),
        };
    }
  }
}
