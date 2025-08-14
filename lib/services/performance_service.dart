import 'dart:developer' as developer;
import 'package:firebase_performance/firebase_performance.dart';

/// Performance monitoring service for African diaspora dating app
class PerformanceService {
  static final PerformanceService _instance = PerformanceService._internal();
  factory PerformanceService() => _instance;
  PerformanceService._internal();

  /// Track user flow performance for diaspora-specific features
  static Future<void> trackUserFlow(String flowName, {Map<String, String>? attributes}) async {
    try {
      final trace = FirebasePerformance.instance.newTrace('diaspora_$flowName');
      
      // Add diaspora-specific attributes
      if (attributes != null) {
        for (final entry in attributes.entries) {
          trace.putAttribute(entry.key, entry.value);
        }
      }
      
      await trace.start();
      developer.log('📊 Started tracking: diaspora_$flowName');
      
      // Store trace for later stopping
      _activeTraces[flowName] = trace;
    } catch (e) {
      developer.log('❌ Error starting trace $flowName: $e');
    }
  }

  /// Stop tracking user flow
  static Future<void> stopTrackingUserFlow(String flowName) async {
    try {
      final trace = _activeTraces[flowName];
      if (trace != null) {
        await trace.stop();
        _activeTraces.remove(flowName);
        developer.log('✅ Stopped tracking: diaspora_$flowName');
      }
    } catch (e) {
      developer.log('❌ Error stopping trace $flowName: $e');
    }
  }

  /// Track matching performance by US region
  static Future<void> trackMatchingLatency(String userLocation, int matchCount, Duration latency) async {
    try {
      final trace = FirebasePerformance.instance.newTrace('cultural_matching_performance');
      
      // Add location and performance attributes
      trace.putAttribute('user_location', userLocation);
      trace.putAttribute('match_count', matchCount.toString());
      trace.putAttribute('latency_ms', latency.inMilliseconds.toString());
      
      await trace.start();
      await Future.delayed(const Duration(milliseconds: 100)); // Simulate processing
      await trace.stop();
      
      developer.log('🎯 Matching performance: $userLocation - ${latency.inMilliseconds}ms for $matchCount matches');
    } catch (e) {
      developer.log('❌ Error tracking matching performance: $e');
    }
  }

  /// Track cultural feature usage
  static Future<void> trackCulturalFeatureUsage(String featureName, String userEthnicity) async {
    try {
      final trace = FirebasePerformance.instance.newTrace('cultural_feature_usage');
      
      trace.putAttribute('feature_name', featureName);
      trace.putAttribute('user_ethnicity', userEthnicity);
      trace.putAttribute('timestamp', DateTime.now().toIso8601String());
      
      await trace.start();
      await Future.delayed(const Duration(milliseconds: 50));
      await trace.stop();
      
      developer.log('🌍 Cultural feature used: $featureName by $userEthnicity user');
    } catch (e) {
      developer.log('❌ Error tracking cultural feature usage: $e');
    }
  }

  /// Track professional networking performance
  static Future<void> trackProfessionalNetworking(String industry, String location) async {
    try {
      final trace = FirebasePerformance.instance.newTrace('professional_networking');
      
      trace.putAttribute('industry', industry);
      trace.putAttribute('location', location);
      trace.putAttribute('user_type', 'diaspora_professional');
      
      await trace.start();
      await Future.delayed(const Duration(milliseconds: 200));
      await trace.stop();
      
      developer.log('💼 Professional networking: $industry in $location');
    } catch (e) {
      developer.log('❌ Error tracking professional networking: $e');
    }
  }

  /// Track messaging performance across cultures
  static Future<void> trackCrossCulturalMessaging(String senderEthnicity, String receiverEthnicity) async {
    try {
      final trace = FirebasePerformance.instance.newTrace('cross_cultural_messaging');
      
      trace.putAttribute('sender_ethnicity', senderEthnicity);
      trace.putAttribute('receiver_ethnicity', receiverEthnicity);
      trace.putAttribute('message_type', 'cross_cultural');
      
      await trace.start();
      await Future.delayed(const Duration(milliseconds: 150));
      await trace.stop();
      
      developer.log('💬 Cross-cultural message: $senderEthnicity → $receiverEthnicity');
    } catch (e) {
      developer.log('❌ Error tracking cross-cultural messaging: $e');
    }
  }

  /// Track subscription conversion for diaspora users
  static Future<void> trackSubscriptionConversion(String userLocation, String planType, bool converted) async {
    try {
      final trace = FirebasePerformance.instance.newTrace('diaspora_subscription_conversion');
      
      trace.putAttribute('user_location', userLocation);
      trace.putAttribute('plan_type', planType);
      trace.putAttribute('converted', converted.toString());
      trace.putAttribute('user_segment', 'african_diaspora');
      
      await trace.start();
      await Future.delayed(const Duration(milliseconds: 100));
      await trace.stop();
      
      developer.log('💳 Subscription conversion: $userLocation - $planType - ${converted ? 'SUCCESS' : 'FAILED'}');
    } catch (e) {
      developer.log('❌ Error tracking subscription conversion: $e');
    }
  }

  /// Track app startup performance for diaspora users
  static Future<void> trackAppStartup(String userLocation) async {
    try {
      final trace = FirebasePerformance.instance.newTrace('diaspora_app_startup');
      
      trace.putAttribute('user_location', userLocation);
      trace.putAttribute('app_version', '1.0.0'); // Get from package info
      trace.putAttribute('user_segment', 'african_diaspora');
      
      await trace.start();
      
      // This will be stopped when app is fully loaded
      _activeTraces['app_startup'] = trace;
      
      developer.log('🚀 Started tracking app startup for diaspora user in $userLocation');
    } catch (e) {
      developer.log('❌ Error tracking app startup: $e');
    }
  }

  /// Track network performance for different US regions
  static Future<void> trackNetworkPerformance(String region, String operation, Duration latency) async {
    try {
      final trace = FirebasePerformance.instance.newTrace('network_performance');
      
      trace.putAttribute('region', region);
      trace.putAttribute('operation', operation);
      trace.putAttribute('latency_ms', latency.inMilliseconds.toString());
      
      await trace.start();
      await Future.delayed(const Duration(milliseconds: 50));
      await trace.stop();
      
      developer.log('🌐 Network performance: $region - $operation - ${latency.inMilliseconds}ms');
    } catch (e) {
      developer.log('❌ Error tracking network performance: $e');
    }
  }

  /// Performance benchmarks for diaspora app
  static const Map<String, int> performanceBenchmarks = {
    'app_startup_ms': 3000,           // 3 seconds max startup
    'matching_latency_ms': 2000,      // 2 seconds max for matching
    'message_send_ms': 1000,          // 1 second max for message sending
    'profile_load_ms': 1500,          // 1.5 seconds max for profile loading
    'cultural_filter_ms': 800,        // 800ms max for cultural filtering
    'subscription_flow_ms': 5000,     // 5 seconds max for subscription flow
  };

  /// Check if performance meets diaspora user expectations
  static bool meetsPerformanceBenchmark(String operation, Duration actualTime) {
    final benchmark = performanceBenchmarks[operation];
    if (benchmark == null) return true;
    
    final meets = actualTime.inMilliseconds <= benchmark;
    developer.log('📊 Performance check: $operation - ${actualTime.inMilliseconds}ms vs ${benchmark}ms - ${meets ? 'PASS' : 'FAIL'}');
    
    return meets;
  }

  // Private storage for active traces
  static final Map<String, Trace> _activeTraces = {};

  /// Get performance summary for diaspora features
  static Map<String, dynamic> getPerformanceSummary() {
    return {
      'active_traces': _activeTraces.keys.toList(),
      'benchmarks': performanceBenchmarks,
      'timestamp': DateTime.now().toIso8601String(),
      'user_segment': 'african_diaspora',
    };
  }
}
