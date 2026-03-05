import 'dart:async';
import 'package:flutter/foundation.dart';

/// Performance monitoring service to track optimization improvements
/// Helps measure the impact of performance optimizations
class PerformanceMonitor {
  static final Map<String, Stopwatch> _activeTimers = {};
  static final Map<String, List<int>> _performanceHistory = {};
  static final Map<String, int> _operationCounts = {};

  // Performance thresholds (in milliseconds)
  static const int USER_LIST_LOAD_THRESHOLD = 2000; // 2 seconds
  static const int MATCH_DETECTION_THRESHOLD = 1000; // 1 second
  static const int CACHE_ACCESS_THRESHOLD = 100; // 100ms

  /// Start timing an operation
  static void startTimer(String operationName) {
    final stopwatch = Stopwatch()..start();
    _activeTimers[operationName] = stopwatch;

    debugPrint('⏱️ Started timer for: $operationName');
  }

  /// Stop timing an operation and record the result
  static int stopTimer(String operationName) {
    final stopwatch = _activeTimers[operationName];
    if (stopwatch == null) {
      debugPrint('❌ No active timer found for: $operationName');
      return 0;
    }

    stopwatch.stop();
    final elapsedMs = stopwatch.elapsedMilliseconds;

    // Record in history
    _performanceHistory.putIfAbsent(operationName, () => []);
    _performanceHistory[operationName]!.add(elapsedMs);

    // Keep only last 50 measurements
    if (_performanceHistory[operationName]!.length > 50) {
      _performanceHistory[operationName]!.removeAt(0);
    }

    // Increment operation count
    _operationCounts[operationName] =
        (_operationCounts[operationName] ?? 0) + 1;

    // Remove from active timers
    _activeTimers.remove(operationName);

    // Log performance
    _logPerformance(operationName, elapsedMs);

    return elapsedMs;
  }

  /// Log performance with appropriate level based on thresholds
  static void _logPerformance(String operationName, int elapsedMs) {
    final threshold = _getThreshold(operationName);
    final emoji = elapsedMs <= threshold ? '✅' : '⚠️';
    final status = elapsedMs <= threshold ? 'GOOD' : 'SLOW';

    debugPrint('$emoji $operationName completed in ${elapsedMs}ms [$status]');

    if (elapsedMs > threshold) {
      debugPrint(
        '   ⚠️ Exceeded threshold of ${threshold}ms by ${elapsedMs - threshold}ms',
      );
    }
  }

  /// Get performance threshold for operation
  static int _getThreshold(String operationName) {
    if (operationName.toLowerCase().contains('user_list') ||
        operationName.toLowerCase().contains('get_users')) {
      return USER_LIST_LOAD_THRESHOLD;
    } else if (operationName.toLowerCase().contains('match') ||
        operationName.toLowerCase().contains('like')) {
      return MATCH_DETECTION_THRESHOLD;
    } else if (operationName.toLowerCase().contains('cache')) {
      return CACHE_ACCESS_THRESHOLD;
    }
    return 1000; // Default 1 second
  }

  /// Record a Firestore operation
  static void recordFirestoreOperation(
    String operationType, {
    int? readCount,
    int? writeCount,
  }) {
    final key = 'firestore_$operationType';
    _operationCounts[key] = (_operationCounts[key] ?? 0) + 1;

    if (readCount != null) {
      final readKey = '${key}_reads';
      _operationCounts[readKey] = (_operationCounts[readKey] ?? 0) + readCount;
    }

    if (writeCount != null) {
      final writeKey = '${key}_writes';
      _operationCounts[writeKey] =
          (_operationCounts[writeKey] ?? 0) + writeCount;
    }

    debugPrint(
      '📊 Firestore $operationType: reads=${readCount ?? 0}, writes=${writeCount ?? 0}',
    );
  }

  /// Get performance statistics for an operation
  static PerformanceStats? getStats(String operationName) {
    final history = _performanceHistory[operationName];
    if (history == null || history.isEmpty) {
      return null;
    }

    final sortedHistory = List<int>.from(history)..sort();
    final count = history.length;
    final sum = history.reduce((a, b) => a + b);

    return PerformanceStats(
      operationName: operationName,
      count: count,
      averageMs: (sum / count).round(),
      minMs: sortedHistory.first,
      maxMs: sortedHistory.last,
      medianMs: sortedHistory[count ~/ 2],
      p95Ms: sortedHistory[(count * 0.95).round() - 1],
      lastMs: history.last,
      threshold: _getThreshold(operationName),
    );
  }

  /// Get all performance statistics
  static Map<String, PerformanceStats> getAllStats() {
    final stats = <String, PerformanceStats>{};

    for (final operationName in _performanceHistory.keys) {
      final stat = getStats(operationName);
      if (stat != null) {
        stats[operationName] = stat;
      }
    }

    return stats;
  }

  /// Get operation counts
  static Map<String, int> getOperationCounts() => Map.from(_operationCounts);

  /// Generate performance report
  static String generateReport() {
    final buffer = StringBuffer();
    buffer.writeln('📊 PERFORMANCE REPORT');
    buffer.writeln('=' * 50);

    final stats = getAllStats();
    if (stats.isEmpty) {
      buffer.writeln('No performance data available');
      return buffer.toString();
    }

    // Sort by average performance
    final sortedStats = stats.entries.toList()
      ..sort((a, b) => b.value.averageMs.compareTo(a.value.averageMs));

    for (final entry in sortedStats) {
      final stat = entry.value;
      final isGood = stat.averageMs <= stat.threshold;
      final emoji = isGood ? '✅' : '⚠️';

      buffer.writeln('\n$emoji ${stat.operationName.toUpperCase()}');
      buffer.writeln('   Count: ${stat.count}');
      buffer.writeln(
        '   Average: ${stat.averageMs}ms (threshold: ${stat.threshold}ms)',
      );
      buffer.writeln('   Min/Max: ${stat.minMs}ms / ${stat.maxMs}ms');
      buffer.writeln('   Median: ${stat.medianMs}ms');
      buffer.writeln('   95th percentile: ${stat.p95Ms}ms');
      buffer.writeln('   Last: ${stat.lastMs}ms');

      if (!isGood) {
        buffer.writeln('   ⚠️ NEEDS OPTIMIZATION');
      }
    }

    // Firestore operation counts
    buffer.writeln('\n📊 FIRESTORE OPERATIONS');
    buffer.writeln('-' * 30);

    final firestoreOps = _operationCounts.entries
        .where((e) => e.key.startsWith('firestore_'))
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    for (final entry in firestoreOps) {
      buffer.writeln('   ${entry.key}: ${entry.value}');
    }

    return buffer.toString();
  }

  /// Clear all performance data
  static void clearData() {
    _activeTimers.clear();
    _performanceHistory.clear();
    _operationCounts.clear();
    debugPrint('🗑️ Performance monitoring data cleared');
  }

  /// Measure execution time of a function
  static Future<T> measure<T>(
    String operationName,
    Future<T> Function() operation,
  ) async {
    startTimer(operationName);
    try {
      final result = await operation();
      stopTimer(operationName);
      return result;
    } on Object catch (e) {
      stopTimer(operationName);
      debugPrint('❌ Error in measured operation $operationName: $e');
      rethrow;
    }
  }

  /// Measure synchronous execution time
  static T measureSync<T>(String operationName, T Function() operation) {
    startTimer(operationName);
    try {
      final result = operation();
      stopTimer(operationName);
      return result;
    } on Object catch (e) {
      stopTimer(operationName);
      debugPrint('❌ Error in measured sync operation $operationName: $e');
      rethrow;
    }
  }
}

/// Performance statistics for an operation
class PerformanceStats {
  const PerformanceStats({
    required this.operationName,
    required this.count,
    required this.averageMs,
    required this.minMs,
    required this.maxMs,
    required this.medianMs,
    required this.p95Ms,
    required this.lastMs,
    required this.threshold,
  });
  final String operationName;
  final int count;
  final int averageMs;
  final int minMs;
  final int maxMs;
  final int medianMs;
  final int p95Ms;
  final int lastMs;
  final int threshold;

  bool get isPerformant => averageMs <= threshold;
  double get performanceRatio => averageMs / threshold;

  @override
  String toString() =>
      'PerformanceStats($operationName: avg=${averageMs}ms, count=$count, performant=$isPerformant)';
}

/// Extension methods for easy performance monitoring
extension PerformanceMonitorExtension on Future {
  Future<T> withPerformanceMonitoring<T>(String operationName) async =>
      PerformanceMonitor.measure(
        operationName,
        () async => await this as T,
      );
}
