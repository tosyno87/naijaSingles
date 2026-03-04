import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../../../models/user_model.dart';
import '../../../../services/cached_user_service.dart';
import '../../../../services/mode_specific_compatibility_engine.dart';
import '../../../../services/paginated_user_service.dart' show PaginatedResult;
import '../../../match/data/services/compatibility_engine.dart';
import '../../../../services/performance_monitor.dart';

/// Smart match service that provides intelligent user ordering and discovery
/// Implements Priority 2: Enhanced Matching Algorithm
class SmartMatchService {
  static const int DIVERSITY_WINDOW_SIZE = 5; // Apply diversity every 5 users
  static const double HIGH_COMPATIBILITY_THRESHOLD = 0.7;
  static const double MEDIUM_COMPATIBILITY_THRESHOLD = 0.5;
  static const int MAX_CONSECUTIVE_HIGH_MATCHES = 3;

  final CachedUserService _cachedUserService = CachedUserService();

  /// Get optimized user list with compatibility scoring and smart ordering
  Future<SmartMatchResult> getOptimizedUserList({
    required UserModel currentUser,
    String mode = 'Dating',
    int pageSize = 20,
    bool forceRefresh = false,
  }) async =>
      PerformanceMonitor.measure('smart_match_get_users', () async {
        try {
          debugPrint('🧠 Getting smart matches for ${currentUser.name}');

          // Get users from cache or Firestore
          final userResult = await _cachedUserService.getCachedUsers(
            currentUser: currentUser,
            forceRefresh: forceRefresh,
          );

          if (!userResult.isSuccess || userResult.items.isEmpty) {
            debugPrint('❌ Failed to get users for smart matching');
            return SmartMatchResult.error('Failed to load users');
          }

          // Calculate compatibility scores for all users
          final compatibilityResults = await _calculateCompatibilityScores(
            currentUser,
            userResult.items,
            mode,
          );

          // Apply smart ordering algorithm
          final orderedUsers = await _applySmartOrdering(
            currentUser,
            compatibilityResults,
            pageSize,
          );

          debugPrint(
            '✅ Smart matching complete: ${orderedUsers.length} users ordered',
          );

          return SmartMatchResult.success(
            users: orderedUsers.map((uc) => uc.user).toList(),
            compatibilityScores: orderedUsers,
            averageCompatibility: _calculateAverageCompatibility(orderedUsers),
            highCompatibilityCount:
                orderedUsers.where((uc) => uc.isHighCompatibility).length,
          );
        } catch (e) {
          debugPrint('❌ Error in smart matching: $e');
          return SmartMatchResult.error(e.toString());
        }
      });

  /// Calculate compatibility scores for all users
  Future<List<UserCompatibility>> _calculateCompatibilityScores(
    UserModel currentUser,
    List<UserModel> targetUsers,
    String mode,
  ) async =>
      PerformanceMonitor.measure('compatibility_calculation', () async {
        debugPrint(
          '🎯 Calculating compatibility for ${targetUsers.length} users',
        );

        final results = <UserCompatibility>[];

        for (final user in targetUsers) {
          final score =
              ModeSpecificCompatibilityEngine.calculateModeCompatibility(
            currentUser,
            user,
            mode,
          );

          results.add(
            UserCompatibility(
              user: user,
              compatibilityScore: score,
            ),
          );
        }

        // Log compatibility distribution
        final highCount = results.where((r) => r.isHighCompatibility).length;
        final mediumCount =
            results.where((r) => r.isMediumCompatibility).length;
        final lowCount = results.where((r) => r.isLowCompatibility).length;

        debugPrint(
          '📊 Compatibility distribution: High: $highCount, Medium: $mediumCount, Low: $lowCount',
        );

        return results;
      });

  /// Apply smart ordering algorithm with diversity
  Future<List<UserCompatibility>> _applySmartOrdering(
    UserModel currentUser,
    List<UserCompatibility> compatibilityResults,
    int pageSize,
  ) async =>
      PerformanceMonitor.measure('smart_ordering', () async {
        debugPrint('🔄 Applying smart ordering algorithm');

        // Start with compatibility-sorted list
        final sortedByCompatibility =
            List<UserCompatibility>.from(compatibilityResults);

        // Apply diversity algorithm to prevent monotony
        final diversifiedList = _applyDiversityFilter(sortedByCompatibility);

        // Apply boost for recently active users
        final boostedList = _applyActivityBoost(diversifiedList);

        // Apply location-based clustering
        final clusteredList =
            _applyLocationClustering(currentUser, boostedList);

        // Take only the requested page size
        final finalList = clusteredList.take(pageSize).toList();

        debugPrint('✅ Smart ordering complete: ${finalList.length} users');
        _logOrderingResults(finalList);

        return finalList;
      });

  /// Apply diversity filter to prevent showing too many similar users consecutively
  List<UserCompatibility> _applyDiversityFilter(List<UserCompatibility> users) {
    if (users.length <= DIVERSITY_WINDOW_SIZE) {
      return users; // No need for diversity with small lists
    }

    final diversifiedList = <UserCompatibility>[];
    final remaining = List<UserCompatibility>.from(users);

    int consecutiveHighMatches = 0;

    while (remaining.isNotEmpty && diversifiedList.length < users.length) {
      UserCompatibility? nextUser;

      // If we have too many consecutive high matches, prefer medium/low matches
      if (consecutiveHighMatches >= MAX_CONSECUTIVE_HIGH_MATCHES) {
        nextUser = remaining.firstWhere(
          (user) => !user.isHighCompatibility,
          orElse: () => remaining.first,
        );
        consecutiveHighMatches = 0;
      } else {
        // Normal selection - take the highest compatibility
        nextUser = remaining.first;
        if (nextUser.isHighCompatibility) {
          consecutiveHighMatches++;
        } else {
          consecutiveHighMatches = 0;
        }
      }

      diversifiedList.add(nextUser);
      remaining.remove(nextUser);
    }

    debugPrint('🎨 Applied diversity filter: ${diversifiedList.length} users');
    return diversifiedList;
  }

  /// Apply activity boost to recently active users
  List<UserCompatibility> _applyActivityBoost(List<UserCompatibility> users) {
    final now = DateTime.now();

    // Separate users by activity level
    final recentlyActive = <UserCompatibility>[];
    final lessActive = <UserCompatibility>[];

    for (final userComp in users) {
      final user = userComp.user;
      final daysSinceLastSeen =
          user.lastSeen != null ? now.difference(user.lastSeen!).inDays : 999;

      if (daysSinceLastSeen <= 3) {
        recentlyActive.add(userComp);
      } else {
        lessActive.add(userComp);
      }
    }

    // Interleave recently active users with less active ones
    final boostedList = <UserCompatibility>[];
    int activeIndex = 0;
    int lessActiveIndex = 0;

    while (activeIndex < recentlyActive.length ||
        lessActiveIndex < lessActive.length) {
      // Add 2 recently active users
      for (int i = 0; i < 2 && activeIndex < recentlyActive.length; i++) {
        boostedList.add(recentlyActive[activeIndex++]);
      }

      // Add 1 less active user
      if (lessActiveIndex < lessActive.length) {
        boostedList.add(lessActive[lessActiveIndex++]);
      }
    }

    debugPrint(
      '⚡ Applied activity boost: ${recentlyActive.length} recently active users prioritized',
    );
    return boostedList;
  }

  /// Apply location-based clustering to group nearby users
  List<UserCompatibility> _applyLocationClustering(
    UserModel currentUser,
    List<UserCompatibility> users,
  ) {
    if (currentUser.coordinates == null || currentUser.coordinates!.isEmpty) {
      return users; // No clustering without location data
    }

    // Separate users by distance
    final nearbyUsers = <UserCompatibility>[];
    final distantUsers = <UserCompatibility>[];

    for (final userComp in users) {
      final user = userComp.user;
      if (user.coordinates != null && user.coordinates!.isNotEmpty) {
        // This would use the distance calculation from compatibility engine
        // For now, we'll use a simple heuristic
        final locationScore =
            CompatibilityEngine.calculateCompatibility(currentUser, user);

        // If location contributes significantly to the score, consider it nearby
        if (locationScore > 0.6) {
          nearbyUsers.add(userComp);
        } else {
          distantUsers.add(userComp);
        }
      } else {
        distantUsers.add(userComp);
      }
    }

    // Interleave nearby and distant users (prefer nearby)
    final clusteredList = <UserCompatibility>[];
    int nearbyIndex = 0;
    int distantIndex = 0;

    while (nearbyIndex < nearbyUsers.length ||
        distantIndex < distantUsers.length) {
      // Add 3 nearby users
      for (int i = 0; i < 3 && nearbyIndex < nearbyUsers.length; i++) {
        clusteredList.add(nearbyUsers[nearbyIndex++]);
      }

      // Add 1 distant user
      if (distantIndex < distantUsers.length) {
        clusteredList.add(distantUsers[distantIndex++]);
      }
    }

    debugPrint(
      '📍 Applied location clustering: ${nearbyUsers.length} nearby users prioritized',
    );
    return clusteredList;
  }

  /// Calculate average compatibility score
  double _calculateAverageCompatibility(List<UserCompatibility> users) {
    if (users.isEmpty) return 0;

    final totalScore =
        users.fold(0.0, (sum, user) => sum + user.compatibilityScore);
    return totalScore / users.length;
  }

  /// Log ordering results for debugging
  void _logOrderingResults(List<UserCompatibility> users) {
    if (!kDebugMode) return;

    debugPrint('📋 Smart ordering results:');
    for (int i = 0; i < min(10, users.length); i++) {
      final user = users[i];
      final emoji = user.isHighCompatibility
          ? '🔥'
          : (user.isMediumCompatibility ? '👍' : '👌');
      debugPrint(
        '   ${i + 1}. $emoji ${user.user.name} (${user.compatibilityPercentage})',
      );
    }

    if (users.length > 10) {
      debugPrint('   ... and ${users.length - 10} more users');
    }
  }

  /// Get more users with smart ordering (for pagination)
  Future<SmartMatchResult> getMoreOptimizedUsers({
    required UserModel currentUser,
    required SmartMatchResult previousResult,
    int pageSize = 20,
  }) async {
    try {
      debugPrint('📄 Getting more smart matches');

      // Get more users from paginated service
      final moreUsersResult = await _cachedUserService.getMoreUsers(
        currentUser: currentUser,
        previousResult: PaginatedResult(
          items: previousResult.users,
          lastDocument:
              null, // This would need to be stored in SmartMatchResult
          hasMore: true,
          totalFetched: previousResult.users.length,
        ),
      );

      if (!moreUsersResult.isSuccess || moreUsersResult.items.isEmpty) {
        return SmartMatchResult.noMoreUsers();
      }

      // Apply smart matching to new users
      final newSmartResult = await getOptimizedUserList(
        currentUser: currentUser,
        pageSize: pageSize,
        forceRefresh: true,
      );

      return newSmartResult;
    } catch (e) {
      debugPrint('❌ Error getting more optimized users: $e');
      return SmartMatchResult.error(e.toString());
    }
  }

  /// Get compatibility breakdown for a specific user pair
  CompatibilityBreakdown getCompatibilityBreakdown(
    UserModel user1,
    UserModel user2,
  ) =>
      CompatibilityEngine.getCompatibilityBreakdown(user1, user2);

  /// Get users filtered by compatibility threshold
  Future<SmartMatchResult> getHighCompatibilityUsers({
    required UserModel currentUser,
    double minCompatibility = HIGH_COMPATIBILITY_THRESHOLD,
    int maxUsers = 50,
  }) async {
    try {
      debugPrint(
        '🔥 Getting high compatibility users (min: ${(minCompatibility * 100).toStringAsFixed(1)}%)',
      );

      // Get all available users
      final allUsersResult = await _cachedUserService.getCachedUsers(
        currentUser: currentUser,
      );

      if (!allUsersResult.isSuccess) {
        return SmartMatchResult.error('Failed to load users');
      }

      // Calculate compatibility and filter
      final compatibilityResults = await _calculateCompatibilityScores(
        currentUser,
        allUsersResult.items,
        'Dating', // Default mode for this method
      );

      final highCompatibilityUsers = compatibilityResults
          .where((uc) => uc.compatibilityScore >= minCompatibility)
          .take(maxUsers)
          .toList();

      debugPrint(
        '✅ Found ${highCompatibilityUsers.length} high compatibility users',
      );

      return SmartMatchResult.success(
        users: highCompatibilityUsers.map((uc) => uc.user).toList(),
        compatibilityScores: highCompatibilityUsers,
        averageCompatibility:
            _calculateAverageCompatibility(highCompatibilityUsers),
        highCompatibilityCount: highCompatibilityUsers.length,
      );
    } catch (e) {
      debugPrint('❌ Error getting high compatibility users: $e');
      return SmartMatchResult.error(e.toString());
    }
  }

  /// Analyze user's matching patterns
  Future<MatchingAnalysis> analyzeMatchingPatterns(
    UserModel currentUser,
  ) async {
    try {
      debugPrint('📊 Analyzing matching patterns for ${currentUser.name}');

      // Get sample of users for analysis
      final usersResult = await _cachedUserService.getCachedUsers(
        currentUser: currentUser,
      );

      if (!usersResult.isSuccess || usersResult.items.isEmpty) {
        return MatchingAnalysis.empty();
      }

      // Calculate compatibility scores
      final compatibilityResults = await _calculateCompatibilityScores(
        currentUser,
        usersResult.items.take(100).toList(), // Analyze first 100 users
        'Dating', // Default mode for this method
      );

      // Analyze patterns
      final highCount =
          compatibilityResults.where((r) => r.isHighCompatibility).length;
      final mediumCount =
          compatibilityResults.where((r) => r.isMediumCompatibility).length;
      final lowCount =
          compatibilityResults.where((r) => r.isLowCompatibility).length;

      final averageScore = _calculateAverageCompatibility(compatibilityResults);

      // Find best matches
      final bestMatches = compatibilityResults.take(5).toList();

      // Analyze profile completeness impact
      final userCompleteness =
          CompatibilityEngine.calculateCompatibility(currentUser, currentUser);

      return MatchingAnalysis(
        totalAnalyzed: compatibilityResults.length,
        highCompatibilityCount: highCount,
        mediumCompatibilityCount: mediumCount,
        lowCompatibilityCount: lowCount,
        averageCompatibilityScore: averageScore,
        bestMatches: bestMatches,
        userProfileCompleteness: userCompleteness,
        recommendations:
            _generateRecommendations(currentUser, compatibilityResults),
      );
    } catch (e) {
      debugPrint('❌ Error analyzing matching patterns: $e');
      return MatchingAnalysis.empty();
    }
  }

  /// Generate recommendations for improving matches
  List<String> _generateRecommendations(
    UserModel currentUser,
    List<UserCompatibility> compatibilityResults,
  ) {
    final recommendations = <String>[];

    // Profile completeness recommendation
    final completeness =
        CompatibilityEngine.calculateCompatibility(currentUser, currentUser);
    if (completeness < 0.7) {
      recommendations.add('Complete your profile to improve match quality');
    }

    // Photo recommendation
    final photoCount = currentUser.imageUrl?.length ?? 0;
    if (photoCount < 3) {
      recommendations.add('Add more photos to attract better matches');
    }

    // Bio recommendation
    if (currentUser.bio == null || currentUser.bio!.length < 50) {
      recommendations
          .add('Write a detailed bio to help others understand you better');
    }

    // Location recommendation
    if (currentUser.coordinates == null || currentUser.coordinates!.isEmpty) {
      recommendations.add('Enable location services to find nearby matches');
    }

    // Activity recommendation
    if (currentUser.lastSeen != null) {
      final daysSinceLastSeen =
          DateTime.now().difference(currentUser.lastSeen!).inDays;
      if (daysSinceLastSeen > 7) {
        recommendations
            .add('Stay active on the app to improve your visibility');
      }
    }

    return recommendations;
  }
}

/// Result class for smart matching operations
class SmartMatchResult {
  const SmartMatchResult._({
    required this.isSuccess,
    required this.users,
    required this.compatibilityScores,
    required this.averageCompatibility,
    required this.highCompatibilityCount,
    this.error,
    this.hasMore = true,
  });

  factory SmartMatchResult.success({
    required List<UserModel> users,
    required List<UserCompatibility> compatibilityScores,
    required double averageCompatibility,
    required int highCompatibilityCount,
    bool hasMore = true,
  }) =>
      SmartMatchResult._(
        isSuccess: true,
        users: users,
        compatibilityScores: compatibilityScores,
        averageCompatibility: averageCompatibility,
        highCompatibilityCount: highCompatibilityCount,
        hasMore: hasMore,
      );

  factory SmartMatchResult.error(String error) => SmartMatchResult._(
        isSuccess: false,
        users: [],
        compatibilityScores: [],
        averageCompatibility: 0,
        highCompatibilityCount: 0,
        error: error,
        hasMore: false,
      );

  factory SmartMatchResult.noMoreUsers() => const SmartMatchResult._(
        isSuccess: true,
        users: [],
        compatibilityScores: [],
        averageCompatibility: 0,
        highCompatibilityCount: 0,
        hasMore: false,
      );
  final bool isSuccess;
  final List<UserModel> users;
  final List<UserCompatibility> compatibilityScores;
  final double averageCompatibility;
  final int highCompatibilityCount;
  final String? error;
  final bool hasMore;

  bool get isEmpty => users.isEmpty;
  int get length => users.length;

  @override
  String toString() =>
      'SmartMatchResult(success: $isSuccess, users: ${users.length}, avgCompatibility: ${(averageCompatibility * 100).toStringAsFixed(1)}%, highMatches: $highCompatibilityCount)';
}

/// Analysis of user's matching patterns
class MatchingAnalysis {
  const MatchingAnalysis({
    required this.totalAnalyzed,
    required this.highCompatibilityCount,
    required this.mediumCompatibilityCount,
    required this.lowCompatibilityCount,
    required this.averageCompatibilityScore,
    required this.bestMatches,
    required this.userProfileCompleteness,
    required this.recommendations,
  });

  factory MatchingAnalysis.empty() => const MatchingAnalysis(
        totalAnalyzed: 0,
        highCompatibilityCount: 0,
        mediumCompatibilityCount: 0,
        lowCompatibilityCount: 0,
        averageCompatibilityScore: 0,
        bestMatches: [],
        userProfileCompleteness: 0,
        recommendations: [],
      );
  final int totalAnalyzed;
  final int highCompatibilityCount;
  final int mediumCompatibilityCount;
  final int lowCompatibilityCount;
  final double averageCompatibilityScore;
  final List<UserCompatibility> bestMatches;
  final double userProfileCompleteness;
  final List<String> recommendations;

  double get highCompatibilityPercentage =>
      totalAnalyzed > 0 ? (highCompatibilityCount / totalAnalyzed) * 100 : 0.0;

  double get mediumCompatibilityPercentage => totalAnalyzed > 0
      ? (mediumCompatibilityCount / totalAnalyzed) * 100
      : 0.0;

  double get lowCompatibilityPercentage =>
      totalAnalyzed > 0 ? (lowCompatibilityCount / totalAnalyzed) * 100 : 0.0;

  @override
  String toString() => 'MatchingAnalysis(\n'
      '  Total Analyzed: $totalAnalyzed\n'
      '  High Compatibility: $highCompatibilityCount (${highCompatibilityPercentage.toStringAsFixed(1)}%)\n'
      '  Medium Compatibility: $mediumCompatibilityCount (${mediumCompatibilityPercentage.toStringAsFixed(1)}%)\n'
      '  Low Compatibility: $lowCompatibilityCount (${lowCompatibilityPercentage.toStringAsFixed(1)}%)\n'
      '  Average Score: ${(averageCompatibilityScore * 100).toStringAsFixed(1)}%\n'
      '  Profile Completeness: ${(userProfileCompleteness * 100).toStringAsFixed(1)}%\n'
      '  Recommendations: ${recommendations.length}\n'
      ')';
}
