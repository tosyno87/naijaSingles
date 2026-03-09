import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Service for analyzing user demographics and cleaning up incomplete profiles
class UserAnalyticsService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Analyze user demographics and profile completeness
  static Future<UserAnalytics> analyzeUsers() async {
    try {
      debugPrint('📊 Starting user analytics...');

      final snapshot = await _firestore.collection('users').get();
      final users = snapshot.docs;

      debugPrint('👥 Total users in database: ${users.length}');

      if (users.isEmpty) {
        return UserAnalytics.empty();
      }

      int maleCount = 0;
      int femaleCount = 0;
      int otherGenderCount = 0;
      int unknownGenderCount = 0;

      int completeProfiles = 0;
      int incompleteProfiles = 0;
      int veryIncompleteProfiles = 0;

      final List<String> incompleteUserIds = [];
      final List<String> veryIncompleteUserIds = [];

      final Map<String, int> ageGroups = {
        '18-25': 0,
        '26-35': 0,
        '36-45': 0,
        '46+': 0,
        'unknown': 0,
      };

      for (final doc in users) {
        final data = doc.data();
        final userId = doc.id;

        // Analyze gender
        final gender = data['gender']?.toString().toLowerCase();
        if (gender == 'male' || gender == 'm') {
          maleCount++;
        } else if (gender == 'female' || gender == 'f') {
          femaleCount++;
        } else if (gender != null && gender.isNotEmpty) {
          otherGenderCount++;
        } else {
          unknownGenderCount++;
        }

        // Analyze age
        final age = data['age'];
        if (age is int && age > 0) {
          if (age >= 18 && age <= 25) {
            ageGroups['18-25'] = ageGroups['18-25']! + 1;
          } else if (age >= 26 && age <= 35) {
            ageGroups['26-35'] = ageGroups['26-35']! + 1;
          } else if (age >= 36 && age <= 45) {
            ageGroups['36-45'] = ageGroups['36-45']! + 1;
          } else if (age > 45) {
            ageGroups['46+'] = ageGroups['46+']! + 1;
          }
        } else {
          ageGroups['unknown'] = ageGroups['unknown']! + 1;
        }

        // Analyze profile completeness
        final completeness = _analyzeProfileCompleteness(data);

        if (completeness.isComplete) {
          completeProfiles++;
        } else if (completeness.isVeryIncomplete) {
          veryIncompleteProfiles++;
          veryIncompleteUserIds.add(userId);
        } else {
          incompleteProfiles++;
          incompleteUserIds.add(userId);
        }

        debugPrint('👤 User $userId: ${data['name'] ?? 'No name'} - '
            'Gender: ${gender ?? 'Unknown'}, Age: ${age ?? 'Unknown'}, '
            'Completeness: ${completeness.score}/100');
      }

      final analytics = UserAnalytics(
        totalUsers: users.length,
        maleCount: maleCount,
        femaleCount: femaleCount,
        otherGenderCount: otherGenderCount,
        unknownGenderCount: unknownGenderCount,
        completeProfiles: completeProfiles,
        incompleteProfiles: incompleteProfiles,
        veryIncompleteProfiles: veryIncompleteProfiles,
        incompleteUserIds: incompleteUserIds,
        veryIncompleteUserIds: veryIncompleteUserIds,
        ageGroups: ageGroups,
      );

      debugPrint('📈 Analytics Summary:');
      debugPrint('   Total Users: ${analytics.totalUsers}');
      debugPrint(
        '   Male: ${analytics.maleCount} (${(analytics.maleCount / analytics.totalUsers * 100).toStringAsFixed(1)}%)',
      );
      debugPrint(
        '   Female: ${analytics.femaleCount} (${(analytics.femaleCount / analytics.totalUsers * 100).toStringAsFixed(1)}%)',
      );
      debugPrint('   Complete Profiles: ${analytics.completeProfiles}');
      debugPrint('   Incomplete Profiles: ${analytics.incompleteProfiles}');
      debugPrint(
        '   Very Incomplete Profiles: ${analytics.veryIncompleteProfiles}',
      );

      return analytics;
    } on Object catch (e) {
      debugPrint('❌ Error analyzing users: $e');
      return UserAnalytics.empty();
    }
  }

  /// Analyze individual profile completeness
  static ProfileCompleteness _analyzeProfileCompleteness(
    Map<String, dynamic> data,
  ) {
    int score = 0;
    final List<String> missingFields = [];

    // Essential fields (60 points total)
    if (data['name'] != null && data['name'].toString().isNotEmpty) {
      score += 15;
    } else {
      missingFields.add('name');
    }

    if (data['age'] != null && data['age'] is int && data['age'] > 0) {
      score += 15;
    } else {
      missingFields.add('age');
    }

    if (data['gender'] != null && data['gender'].toString().isNotEmpty) {
      score += 15;
    } else {
      missingFields.add('gender');
    }

    if (data['bio'] != null && data['bio'].toString().isNotEmpty) {
      score += 15;
    } else {
      missingFields.add('bio');
    }

    // Location (20 points)
    if (data['latitude'] != null && data['longitude'] != null) {
      score += 20;
    } else {
      missingFields.add('location');
    }

    // Photos (20 points)
    if (data['photos'] != null &&
        data['photos'] is List &&
        data['photos'].isNotEmpty) {
      score += 20;
    } else {
      missingFields.add('photos');
    }

    return ProfileCompleteness(
      score: score,
      missingFields: missingFields,
      isComplete: score >= 80,
      isVeryIncomplete: score < 40,
    );
  }

  /// Delete very incomplete profiles (scores < 40)
  static Future<CleanupResult> deleteVeryIncompleteProfiles() async {
    try {
      debugPrint('🧹 Starting cleanup of very incomplete profiles...');

      final analytics = await analyzeUsers();
      final userIdsToDelete = analytics.veryIncompleteUserIds;

      if (userIdsToDelete.isEmpty) {
        debugPrint('✅ No very incomplete profiles found to delete');
        return CleanupResult(
          deletedCount: 0,
          remainingUsers: analytics.totalUsers,
          success: true,
        );
      }

      debugPrint(
        '🗑️ Deleting ${userIdsToDelete.length} very incomplete profiles...',
      );

      int deletedCount = 0;
      for (final userId in userIdsToDelete) {
        try {
          await _firestore.collection('users').doc(userId).delete();
          deletedCount++;
          debugPrint('✅ Deleted user: $userId');
        } on Object catch (e) {
          debugPrint('❌ Failed to delete user $userId: $e');
        }
      }

      final remainingUsers = analytics.totalUsers - deletedCount;

      debugPrint('🎉 Cleanup complete:');
      debugPrint('   Deleted: $deletedCount users');
      debugPrint('   Remaining: $remainingUsers users');

      return CleanupResult(
        deletedCount: deletedCount,
        remainingUsers: remainingUsers,
        success: true,
      );
    } on Object catch (e) {
      debugPrint('❌ Error during cleanup: $e');
      return CleanupResult(
        deletedCount: 0,
        remainingUsers: 0,
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Get user matching algorithm status
  static Future<AlgorithmStatus> getAlgorithmStatus() async {
    try {
      debugPrint('🔍 Analyzing matching algorithm status...');

      final analytics = await analyzeUsers();

      // Check if we have enough users for good matching
      final bool hasEnoughUsers = analytics.totalUsers >= 10;
      final bool hasGoodGenderBalance =
          analytics.maleCount > 0 && analytics.femaleCount > 0;
      final bool hasCompleteProfiles = analytics.completeProfiles >= 5;

      // Calculate gender balance ratio
      double genderBalance = 0;
      if (analytics.maleCount + analytics.femaleCount > 0) {
        genderBalance =
            analytics.maleCount / (analytics.maleCount + analytics.femaleCount);
      }

      // Determine algorithm readiness
      final bool isReady =
          hasEnoughUsers && hasGoodGenderBalance && hasCompleteProfiles;

      final String status = isReady ? 'Ready' : 'Needs Improvement';
      final List<String> recommendations = [];

      if (!hasEnoughUsers) {
        recommendations
            .add('Need at least 10 users (currently: ${analytics.totalUsers})');
      }
      if (!hasGoodGenderBalance) {
        recommendations.add(
          'Need both male and female users (M: ${analytics.maleCount}, F: ${analytics.femaleCount})',
        );
      }
      if (!hasCompleteProfiles) {
        recommendations.add(
          'Need at least 5 complete profiles (currently: ${analytics.completeProfiles})',
        );
      }
      if (genderBalance < 0.2 || genderBalance > 0.8) {
        recommendations.add(
          'Gender balance is skewed (${(genderBalance * 100).toStringAsFixed(1)}% male)',
        );
      }

      return AlgorithmStatus(
        isReady: isReady,
        status: status,
        totalUsers: analytics.totalUsers,
        maleCount: analytics.maleCount,
        femaleCount: analytics.femaleCount,
        completeProfiles: analytics.completeProfiles,
        genderBalance: genderBalance,
        recommendations: recommendations,
      );
    } on Object catch (e) {
      debugPrint('❌ Error analyzing algorithm status: $e');
      return AlgorithmStatus.error(e.toString());
    }
  }
}

/// User analytics data model
class UserAnalytics {
  UserAnalytics({
    required this.totalUsers,
    required this.maleCount,
    required this.femaleCount,
    required this.otherGenderCount,
    required this.unknownGenderCount,
    required this.completeProfiles,
    required this.incompleteProfiles,
    required this.veryIncompleteProfiles,
    required this.incompleteUserIds,
    required this.veryIncompleteUserIds,
    required this.ageGroups,
  });

  factory UserAnalytics.empty() => UserAnalytics(
        totalUsers: 0,
        maleCount: 0,
        femaleCount: 0,
        otherGenderCount: 0,
        unknownGenderCount: 0,
        completeProfiles: 0,
        incompleteProfiles: 0,
        veryIncompleteProfiles: 0,
        incompleteUserIds: [],
        veryIncompleteUserIds: [],
        ageGroups: {},
      );
  final int totalUsers;
  final int maleCount;
  final int femaleCount;
  final int otherGenderCount;
  final int unknownGenderCount;
  final int completeProfiles;
  final int incompleteProfiles;
  final int veryIncompleteProfiles;
  final List<String> incompleteUserIds;
  final List<String> veryIncompleteUserIds;
  final Map<String, int> ageGroups;
}

/// Profile completeness data model
class ProfileCompleteness {
  ProfileCompleteness({
    required this.score,
    required this.missingFields,
    required this.isComplete,
    required this.isVeryIncomplete,
  });
  final int score;
  final List<String> missingFields;
  final bool isComplete;
  final bool isVeryIncomplete;
}

/// Cleanup result data model
class CleanupResult {
  CleanupResult({
    required this.deletedCount,
    required this.remainingUsers,
    required this.success,
    this.error,
  });
  final int deletedCount;
  final int remainingUsers;
  final bool success;
  final String? error;
}

/// Algorithm status data model
class AlgorithmStatus {
  AlgorithmStatus({
    required this.isReady,
    required this.status,
    required this.totalUsers,
    required this.maleCount,
    required this.femaleCount,
    required this.completeProfiles,
    required this.genderBalance,
    required this.recommendations,
  });

  factory AlgorithmStatus.error(String error) => AlgorithmStatus(
        isReady: false,
        status: 'Error',
        totalUsers: 0,
        maleCount: 0,
        femaleCount: 0,
        completeProfiles: 0,
        genderBalance: 0,
        recommendations: ['Error: $error'],
      );
  final bool isReady;
  final String status;
  final int totalUsers;
  final int maleCount;
  final int femaleCount;
  final int completeProfiles;
  final double genderBalance;
  final List<String> recommendations;
}
