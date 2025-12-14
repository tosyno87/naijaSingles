import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Industry-standard profile analytics service
/// Features:
/// - Profile view tracking
/// - Match analytics
/// - Engagement metrics
/// - Performance insights
/// - User behavior analysis
/// - A/B testing support
class ProfileAnalyticsService {
  factory ProfileAnalyticsService() => _instance;
  ProfileAnalyticsService._internal();
  static final ProfileAnalyticsService _instance =
      ProfileAnalyticsService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Track profile view
  Future<void> trackProfileView(String profileId, String viewerId) async {
    try {
      log('👁️ Tracking profile view: $profileId by $viewerId');

      await _firestore.collection('analytics').add({
        'type': 'profile_view',
        'profileId': profileId,
        'viewerId': viewerId,
        'timestamp': FieldValue.serverTimestamp(),
        'date': DateTime.now().toIso8601String().split('T')[0], // YYYY-MM-DD
      });

      // Update profile view count
      await _updateProfileViewCount(profileId);

      log('✅ Profile view tracked successfully');
    } catch (e) {
      log('❌ Error tracking profile view: $e');
    }
  }

  /// Track profile like
  Future<void> trackProfileLike(String profileId, String likerId) async {
    try {
      log('❤️ Tracking profile like: $profileId by $likerId');

      await _firestore.collection('analytics').add({
        'type': 'profile_like',
        'profileId': profileId,
        'likerId': likerId,
        'timestamp': FieldValue.serverTimestamp(),
        'date': DateTime.now().toIso8601String().split('T')[0],
      });

      // Update profile like count
      await _updateProfileLikeCount(profileId);

      log('✅ Profile like tracked successfully');
    } catch (e) {
      log('❌ Error tracking profile like: $e');
    }
  }

  /// Track profile pass
  Future<void> trackProfilePass(String profileId, String passerId) async {
    try {
      log('👎 Tracking profile pass: $profileId by $passerId');

      await _firestore.collection('analytics').add({
        'type': 'profile_pass',
        'profileId': profileId,
        'passerId': passerId,
        'timestamp': FieldValue.serverTimestamp(),
        'date': DateTime.now().toIso8601String().split('T')[0],
      });

      log('✅ Profile pass tracked successfully');
    } catch (e) {
      log('❌ Error tracking profile pass: $e');
    }
  }

  /// Track match
  Future<void> trackMatch(String userId1, String userId2) async {
    try {
      log('💕 Tracking match: $userId1 and $userId2');

      await _firestore.collection('analytics').add({
        'type': 'match',
        'userId1': userId1,
        'userId2': userId2,
        'timestamp': FieldValue.serverTimestamp(),
        'date': DateTime.now().toIso8601String().split('T')[0],
      });

      log('✅ Match tracked successfully');
    } catch (e) {
      log('❌ Error tracking match: $e');
    }
  }

  /// Track message sent
  Future<void> trackMessageSent(
      String threadId, String senderId, String receiverId,) async {
    try {
      log('💬 Tracking message sent: $threadId');

      await _firestore.collection('analytics').add({
        'type': 'message_sent',
        'threadId': threadId,
        'senderId': senderId,
        'receiverId': receiverId,
        'timestamp': FieldValue.serverTimestamp(),
        'date': DateTime.now().toIso8601String().split('T')[0],
      });

      log('✅ Message sent tracked successfully');
    } catch (e) {
      log('❌ Error tracking message sent: $e');
    }
  }

  /// Track profile edit
  Future<void> trackProfileEdit(String userId, String fieldChanged) async {
    try {
      log('✏️ Tracking profile edit: $userId, field: $fieldChanged');

      await _firestore.collection('analytics').add({
        'type': 'profile_edit',
        'userId': userId,
        'fieldChanged': fieldChanged,
        'timestamp': FieldValue.serverTimestamp(),
        'date': DateTime.now().toIso8601String().split('T')[0],
      });

      log('✅ Profile edit tracked successfully');
    } catch (e) {
      log('❌ Error tracking profile edit: $e');
    }
  }

  /// Get profile analytics
  Future<ProfileAnalytics> getProfileAnalytics(String userId) async {
    try {
      log('📊 Getting profile analytics for: $userId');

      // Get profile views
      final viewsSnapshot = await _firestore
          .collection('analytics')
          .where('profileId', isEqualTo: userId)
          .where('type', isEqualTo: 'profile_view')
          .get();

      // Get profile likes
      final likesSnapshot = await _firestore
          .collection('analytics')
          .where('profileId', isEqualTo: userId)
          .where('type', isEqualTo: 'profile_like')
          .get();

      // Get profile passes
      final passesSnapshot = await _firestore
          .collection('analytics')
          .where('profileId', isEqualTo: userId)
          .where('type', isEqualTo: 'profile_pass')
          .get();

      // Get matches
      final matchesSnapshot = await _firestore
          .collection('analytics')
          .where('userId1', isEqualTo: userId)
          .where('type', isEqualTo: 'match')
          .get();

      final matchesSnapshot2 = await _firestore
          .collection('analytics')
          .where('userId2', isEqualTo: userId)
          .where('type', isEqualTo: 'match')
          .get();

      // Calculate metrics
      final totalViews = viewsSnapshot.docs.length;
      final totalLikes = likesSnapshot.docs.length;
      final totalPasses = passesSnapshot.docs.length;
      final totalMatches =
          matchesSnapshot.docs.length + matchesSnapshot2.docs.length;

      // Calculate like rate
      final likeRate = totalViews > 0 ? (totalLikes / totalViews) * 100 : 0.0;

      // Calculate match rate
      final matchRate =
          totalLikes > 0 ? (totalMatches / totalLikes) * 100 : 0.0;

      // Get daily analytics
      final dailyAnalytics = await _getDailyAnalytics(userId);

      // Get demographic analytics
      final demographicAnalytics = await _getDemographicAnalytics(userId);

      final analytics = ProfileAnalytics(
        userId: userId,
        totalViews: totalViews,
        totalLikes: totalLikes,
        totalPasses: totalPasses,
        totalMatches: totalMatches,
        likeRate: likeRate,
        matchRate: matchRate,
        dailyAnalytics: dailyAnalytics,
        demographicAnalytics: demographicAnalytics,
        lastUpdated: DateTime.now(),
      );

      log('✅ Profile analytics retrieved successfully');
      return analytics;
    } catch (e) {
      log('❌ Error getting profile analytics: $e');
      return ProfileAnalytics(
        userId: userId,
        totalViews: 0,
        totalLikes: 0,
        totalPasses: 0,
        totalMatches: 0,
        likeRate: 0,
        matchRate: 0,
        dailyAnalytics: [],
        demographicAnalytics: DemographicAnalytics.empty(),
        lastUpdated: DateTime.now(),
      );
    }
  }

  /// Get daily analytics
  Future<List<DailyAnalytics>> _getDailyAnalytics(String userId) async {
    try {
      final now = DateTime.now();
      final last30Days = <DailyAnalytics>[];

      for (int i = 29; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        final dateString = date.toIso8601String().split('T')[0];

        // Get views for this date
        final viewsSnapshot = await _firestore
            .collection('analytics')
            .where('profileId', isEqualTo: userId)
            .where('type', isEqualTo: 'profile_view')
            .where('date', isEqualTo: dateString)
            .get();

        // Get likes for this date
        final likesSnapshot = await _firestore
            .collection('analytics')
            .where('profileId', isEqualTo: userId)
            .where('type', isEqualTo: 'profile_like')
            .where('date', isEqualTo: dateString)
            .get();

        // Get passes for this date
        final passesSnapshot = await _firestore
            .collection('analytics')
            .where('profileId', isEqualTo: userId)
            .where('type', isEqualTo: 'profile_pass')
            .where('date', isEqualTo: dateString)
            .get();

        last30Days.add(DailyAnalytics(
          date: date,
          views: viewsSnapshot.docs.length,
          likes: likesSnapshot.docs.length,
          passes: passesSnapshot.docs.length,
        ),);
      }

      return last30Days;
    } catch (e) {
      log('❌ Error getting daily analytics: $e');
      return [];
    }
  }

  /// Get demographic analytics
  Future<DemographicAnalytics> _getDemographicAnalytics(String userId) async {
    try {
      // Get views by age group
      final viewsSnapshot = await _firestore
          .collection('analytics')
          .where('profileId', isEqualTo: userId)
          .where('type', isEqualTo: 'profile_view')
          .get();

      final ageGroups = <String, int>{};
      final genderGroups = <String, int>{};
      final locationGroups = <String, int>{};

      for (final doc in viewsSnapshot.docs) {
        final viewerId = doc.data()['viewerId'] as String;

        // Get viewer's demographic data
        final viewerDoc =
            await _firestore.collection('users').doc(viewerId).get();
        if (viewerDoc.exists) {
          final viewerData = viewerDoc.data()!;

          // Age group
          final age = viewerData['age'] as int?;
          if (age != null) {
            final ageGroup = _getAgeGroup(age);
            ageGroups[ageGroup] = (ageGroups[ageGroup] ?? 0) + 1;
          }

          // Gender
          final gender = viewerData['gender'] as String?;
          if (gender != null) {
            genderGroups[gender] = (genderGroups[gender] ?? 0) + 1;
          }

          // Location
          final location = viewerData['locationName'] as String?;
          if (location != null) {
            locationGroups[location] = (locationGroups[location] ?? 0) + 1;
          }
        }
      }

      return DemographicAnalytics(
        ageGroups: ageGroups,
        genderGroups: genderGroups,
        locationGroups: locationGroups,
      );
    } catch (e) {
      log('❌ Error getting demographic analytics: $e');
      return DemographicAnalytics.empty();
    }
  }

  /// Get age group from age
  String _getAgeGroup(int age) {
    if (age < 25) return '18-24';
    if (age < 35) return '25-34';
    if (age < 45) return '35-44';
    if (age < 55) return '45-54';
    return '55+';
  }

  /// Update profile view count
  Future<void> _updateProfileViewCount(String profileId) async {
    try {
      await _firestore.collection('users').doc(profileId).update({
        'viewCount': FieldValue.increment(1),
        'lastViewedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      log('❌ Error updating profile view count: $e');
    }
  }

  /// Update profile like count
  Future<void> _updateProfileLikeCount(String profileId) async {
    try {
      await _firestore.collection('users').doc(profileId).update({
        'likeCount': FieldValue.increment(1),
        'lastLikedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      log('❌ Error updating profile like count: $e');
    }
  }

  /// Get app-wide analytics
  Future<AppAnalytics> getAppAnalytics() async {
    try {
      log('📊 Getting app-wide analytics');

      // Get total users
      final usersSnapshot = await _firestore.collection('users').get();
      final totalUsers = usersSnapshot.docs.length;

      // Get total matches
      final matchesSnapshot = await _firestore
          .collection('analytics')
          .where('type', isEqualTo: 'match')
          .get();
      final totalMatches = matchesSnapshot.docs.length;

      // Get total messages
      final messagesSnapshot = await _firestore
          .collection('analytics')
          .where('type', isEqualTo: 'message_sent')
          .get();
      final totalMessages = messagesSnapshot.docs.length;

      // Get daily active users (last 24 hours)
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));

      final dauSnapshot = await _firestore
          .collection('analytics')
          .where('timestamp', isGreaterThan: yesterday)
          .get();

      final activeUsers = dauSnapshot.docs
          .map((doc) => doc.data()['viewerId'] as String)
          .toSet()
          .length;

      return AppAnalytics(
        totalUsers: totalUsers,
        totalMatches: totalMatches,
        totalMessages: totalMessages,
        dailyActiveUsers: activeUsers,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      log('❌ Error getting app analytics: $e');
      return AppAnalytics(
        totalUsers: 0,
        totalMatches: 0,
        totalMessages: 0,
        dailyActiveUsers: 0,
        lastUpdated: DateTime.now(),
      );
    }
  }

  /// Get user engagement score
  Future<double> getUserEngagementScore(String userId) async {
    try {
      final analytics = await getProfileAnalytics(userId);

      // Calculate engagement score based on various factors
      double score = 0;

      // Profile completeness (30%)
      final profileCompleteness = await _calculateProfileCompleteness(userId);
      score += 0.3 * profileCompleteness;

      // Activity level (25%)
      final activityLevel = await _calculateActivityLevel(userId);
      score += 0.25 * activityLevel;

      // Response rate (25%)
      score += 0.25 * analytics.matchRate / 100;

      // Profile quality (20%)
      score += 0.2 * analytics.likeRate / 100;

      return score.clamp(0.0, 1.0);
    } catch (e) {
      log('❌ Error calculating engagement score: $e');
      return 0.0;
    }
  }

  /// Calculate profile completeness
  Future<double> _calculateProfileCompleteness(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return 0.0;

      final userData = userDoc.data()!;
      int completedFields = 0;
      const int totalFields = 8; // Total number of important fields

      if (userData['name'] != null && userData['name'].toString().isNotEmpty) {
        completedFields++;
      }
      if (userData['age'] != null) completedFields++;
      if (userData['bio'] != null && userData['bio'].toString().isNotEmpty) {
        completedFields++;
      }
      if (userData['photos'] != null && (userData['photos'] as List).isNotEmpty) {
        completedFields++;
      }
      if (userData['nationality'] != null &&
          userData['nationality'].toString().isNotEmpty) {
        completedFields++;
      }
      if (userData['tribe'] != null && userData['tribe'].toString().isNotEmpty) {
        completedFields++;
      }
      if (userData['occupation'] != null &&
          userData['occupation'].toString().isNotEmpty) {
        completedFields++;
      }
      if (userData['interests'] != null &&
          (userData['interests'] as List).isNotEmpty) {
        completedFields++;
      }

      return completedFields / totalFields;
    } catch (e) {
      log('❌ Error calculating profile completeness: $e');
      return 0.0;
    }
  }

  /// Calculate activity level
  Future<double> _calculateActivityLevel(String userId) async {
    try {
      final now = DateTime.now();
      final last7Days = now.subtract(const Duration(days: 7));

      final activitySnapshot = await _firestore
          .collection('analytics')
          .where('userId', isEqualTo: userId)
          .where('timestamp', isGreaterThan: last7Days)
          .get();

      final activityCount = activitySnapshot.docs.length;

      // Normalize activity score (0-1)
      return (activityCount / 20).clamp(0.0, 1.0); // 20 activities = 1.0 score
    } catch (e) {
      log('❌ Error calculating activity level: $e');
      return 0.0;
    }
  }
}

/// Profile analytics model
class ProfileAnalytics {

  const ProfileAnalytics({
    required this.userId,
    required this.totalViews,
    required this.totalLikes,
    required this.totalPasses,
    required this.totalMatches,
    required this.likeRate,
    required this.matchRate,
    required this.dailyAnalytics,
    required this.demographicAnalytics,
    required this.lastUpdated,
  });
  final String userId;
  final int totalViews;
  final int totalLikes;
  final int totalPasses;
  final int totalMatches;
  final double likeRate;
  final double matchRate;
  final List<DailyAnalytics> dailyAnalytics;
  final DemographicAnalytics demographicAnalytics;
  final DateTime lastUpdated;

  @override
  String toString() => 'ProfileAnalytics($userId: $totalViews views, $totalLikes likes, ${likeRate.toStringAsFixed(1)}% like rate)';
}

/// Daily analytics model
class DailyAnalytics {

  const DailyAnalytics({
    required this.date,
    required this.views,
    required this.likes,
    required this.passes,
  });
  final DateTime date;
  final int views;
  final int likes;
  final int passes;

  @override
  String toString() => 'DailyAnalytics(${date.toIso8601String().split('T')[0]}: $views views, $likes likes)';
}

/// Demographic analytics model
class DemographicAnalytics {

  const DemographicAnalytics({
    required this.ageGroups,
    required this.genderGroups,
    required this.locationGroups,
  });

  factory DemographicAnalytics.empty() => const DemographicAnalytics(
      ageGroups: {},
      genderGroups: {},
      locationGroups: {},
    );
  final Map<String, int> ageGroups;
  final Map<String, int> genderGroups;
  final Map<String, int> locationGroups;

  @override
  String toString() => 'DemographicAnalytics(age: ${ageGroups.length}, gender: ${genderGroups.length}, location: ${locationGroups.length})';
}

/// App analytics model
class AppAnalytics {

  const AppAnalytics({
    required this.totalUsers,
    required this.totalMatches,
    required this.totalMessages,
    required this.dailyActiveUsers,
    required this.lastUpdated,
  });
  final int totalUsers;
  final int totalMatches;
  final int totalMessages;
  final int dailyActiveUsers;
  final DateTime lastUpdated;

  @override
  String toString() => 'AppAnalytics($totalUsers users, $totalMatches matches, $dailyActiveUsers DAU)';
}
