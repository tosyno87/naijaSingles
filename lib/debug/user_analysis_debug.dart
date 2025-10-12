import 'package:flutter/foundation.dart';
import 'package:naijasingles/services/user_analytics_service.dart';

/// Debug script for analyzing users and cleaning up incomplete profiles
class UserAnalysisDebug {
  /// Run complete user analysis
  static Future<void> runCompleteAnalysis() async {
    debugPrint('🔍 Starting complete user analysis...');
    debugPrint('=' * 50);

    // 1. Analyze current users
    debugPrint('📊 Step 1: Analyzing user demographics...');
    final analytics = await UserAnalyticsService.analyzeUsers();

    if (analytics.totalUsers == 0) {
      debugPrint('❌ No users found in database!');
      return;
    }

    debugPrint('📈 Demographics Summary:');
    debugPrint('   Total Users: ${analytics.totalUsers}');
    debugPrint(
        '   Male: ${analytics.maleCount} (${(analytics.maleCount / analytics.totalUsers * 100).toStringAsFixed(1)}%)');
    debugPrint(
        '   Female: ${analytics.femaleCount} (${(analytics.femaleCount / analytics.totalUsers * 100).toStringAsFixed(1)}%)');
    debugPrint(
        '   Other/Unknown: ${analytics.otherGenderCount + analytics.unknownGenderCount}');
    debugPrint('');

    debugPrint('📋 Profile Completeness:');
    debugPrint('   Complete Profiles: ${analytics.completeProfiles}');
    debugPrint('   Incomplete Profiles: ${analytics.incompleteProfiles}');
    debugPrint(
        '   Very Incomplete Profiles: ${analytics.veryIncompleteProfiles}');
    debugPrint('');

    debugPrint('🎂 Age Distribution:');
    analytics.ageGroups.forEach((range, count) {
      debugPrint('   $range: $count users');
    });
    debugPrint('');

    // 2. Check algorithm status
    debugPrint('🧠 Step 2: Checking matching algorithm status...');
    final algorithmStatus = await UserAnalyticsService.getAlgorithmStatus();

    debugPrint('🎯 Algorithm Status: ${algorithmStatus.status}');
    debugPrint('   Ready: ${algorithmStatus.isReady ? "✅" : "❌"}');
    debugPrint(
        '   Gender Balance: ${(algorithmStatus.genderBalance * 100).toStringAsFixed(1)}% male');
    debugPrint('');

    if (algorithmStatus.recommendations.isNotEmpty) {
      debugPrint('💡 Recommendations:');
      for (int i = 0; i < algorithmStatus.recommendations.length; i++) {
        debugPrint('   ${i + 1}. ${algorithmStatus.recommendations[i]}');
      }
      debugPrint('');
    }

    // 3. Show incomplete profiles
    if (analytics.incompleteUserIds.isNotEmpty) {
      debugPrint(
          '⚠️ Incomplete Profiles (${analytics.incompleteUserIds.length}):');
      for (final userId in analytics.incompleteUserIds) {
        debugPrint('   - $userId');
      }
      debugPrint('');
    }

    if (analytics.veryIncompleteUserIds.isNotEmpty) {
      debugPrint(
          '🚨 Very Incomplete Profiles (${analytics.veryIncompleteUserIds.length}):');
      for (final userId in analytics.veryIncompleteUserIds) {
        debugPrint('   - $userId');
      }
      debugPrint('');
    }

    // 4. Offer cleanup option
    if (analytics.veryIncompleteUserIds.isNotEmpty) {
      debugPrint('🧹 Step 3: Cleanup Options');
      debugPrint(
          '   Found ${analytics.veryIncompleteUserIds.length} very incomplete profiles');
      debugPrint(
          '   These profiles have < 40% completeness and can be safely deleted');
      debugPrint(
          '   Run UserAnalysisDebug.cleanupIncompleteProfiles() to delete them');
      debugPrint('');
    }

    debugPrint('✅ Analysis complete!');
    debugPrint('=' * 50);
  }

  /// Clean up very incomplete profiles
  static Future<void> cleanupIncompleteProfiles() async {
    debugPrint('🧹 Starting cleanup of very incomplete profiles...');
    debugPrint('=' * 50);

    final result = await UserAnalyticsService.deleteVeryIncompleteProfiles();

    if (result.success) {
      debugPrint('✅ Cleanup completed successfully!');
      debugPrint('   Deleted: ${result.deletedCount} profiles');
      debugPrint('   Remaining: ${result.remainingUsers} users');
    } else {
      debugPrint('❌ Cleanup failed: ${result.error}');
    }

    debugPrint('=' * 50);
  }

  /// Quick status check
  static Future<void> quickStatus() async {
    debugPrint('⚡ Quick Status Check');
    debugPrint('=' * 30);

    final analytics = await UserAnalyticsService.analyzeUsers();
    final algorithmStatus = await UserAnalyticsService.getAlgorithmStatus();

    debugPrint(
        '👥 Users: ${analytics.totalUsers} (M: ${analytics.maleCount}, F: ${analytics.femaleCount})');
    debugPrint(
        '📋 Complete: ${analytics.completeProfiles}/${analytics.totalUsers}');
    debugPrint('🎯 Algorithm: ${algorithmStatus.status}');
    debugPrint('🧹 Incomplete: ${analytics.veryIncompleteProfiles}');

    debugPrint('=' * 30);
  }
}
