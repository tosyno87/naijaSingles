import 'package:flutter/foundation.dart';
import '../services/user_analytics_service.dart';

/// Quick analysis that can be called from the running app
class QuickAnalysis {
  /// Run a quick user analysis and print results
  static Future<void> runQuickAnalysis() async {
    debugPrint('🔍 Running quick user analysis...');
    debugPrint('=' * 50);

    try {
      // Get basic analytics
      final analytics = await UserAnalyticsService.analyzeUsers();

      if (analytics.totalUsers == 0) {
        debugPrint('❌ No users found in database!');
        return;
      }

      debugPrint('📊 Quick Analysis Results:');
      debugPrint('   Total Users: ${analytics.totalUsers}');
      debugPrint(
          '   Male: ${analytics.maleCount} (${(analytics.maleCount / analytics.totalUsers * 100).toStringAsFixed(1)}%)',);
      debugPrint(
          '   Female: ${analytics.femaleCount} (${(analytics.femaleCount / analytics.totalUsers * 100).toStringAsFixed(1)}%)',);
      debugPrint('   Complete Profiles: ${analytics.completeProfiles}');
      debugPrint('   Incomplete Profiles: ${analytics.incompleteProfiles}');
      debugPrint('   Very Incomplete: ${analytics.veryIncompleteProfiles}');
      debugPrint('');

      // Check algorithm status
      final algorithmStatus = await UserAnalyticsService.getAlgorithmStatus();
      debugPrint('🎯 Algorithm Status: ${algorithmStatus.status}');
      debugPrint('   Ready: ${algorithmStatus.isReady ? "✅" : "❌"}');

      if (algorithmStatus.recommendations.isNotEmpty) {
        debugPrint('💡 Recommendations:');
        for (int i = 0; i < algorithmStatus.recommendations.length; i++) {
          debugPrint('   ${i + 1}. ${algorithmStatus.recommendations[i]}');
        }
      }

      debugPrint('=' * 50);
    } catch (e) {
      debugPrint('❌ Error during analysis: $e');
    }
  }

  /// Clean up very incomplete profiles
  static Future<void> cleanupProfiles() async {
    debugPrint('🧹 Starting profile cleanup...');

    try {
      final result = await UserAnalyticsService.deleteVeryIncompleteProfiles();

      if (result.success) {
        debugPrint('✅ Cleanup completed!');
        debugPrint('   Deleted: ${result.deletedCount} profiles');
        debugPrint('   Remaining: ${result.remainingUsers} users');
      } else {
        debugPrint('❌ Cleanup failed: ${result.error}');
      }
    } catch (e) {
      debugPrint('❌ Error during cleanup: $e');
    }
  }
}
