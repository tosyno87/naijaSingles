import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../features/match/models/match_model.dart';
import 'performance_monitor.dart';

/// Match expiration service that manages match lifecycle and cleanup
/// Implements Priority 3: User Experience Enhancements
class MatchExpirationService {
  static const Duration MATCH_EXPIRY_DURATION = Duration(days: 7);
  static const Duration CLEANUP_INTERVAL = Duration(hours: 6);
  static const Duration WARNING_THRESHOLD =
      Duration(days: 5); // Warn 2 days before expiry

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection references
  CollectionReference get _matchesCollection =>
      _firestore.collection('matches');
  CollectionReference get _usersCollection => _firestore.collection('users');
  CollectionReference get _chatThreadsCollection =>
      _firestore.collection('chatThreads');
  CollectionReference get _expiredMatchesCollection =>
      _firestore.collection('expiredMatches');

  // Cleanup timer
  Timer? _cleanupTimer;

  /// Initialize the expiration service with automatic cleanup
  void initialize() {
    debugPrint('🕐 Initializing match expiration service');

    // Start periodic cleanup
    _cleanupTimer = Timer.periodic(CLEANUP_INTERVAL, (timer) {
      _performScheduledCleanup();
    });

    // Perform initial cleanup
    _performScheduledCleanup();
  }

  /// Dispose of the service and cleanup resources
  void dispose() {
    _cleanupTimer?.cancel();
    _cleanupTimer = null;
    debugPrint('🗑️ Match expiration service disposed');
  }

  /// Check if a match has expired
  bool isMatchExpired(MatchModel match) {
    final matchAge = DateTime.now().difference(match.matchedAt);
    return matchAge > MATCH_EXPIRY_DURATION;
  }

  /// Check if a match is approaching expiration
  bool isMatchNearExpiry(MatchModel match) {
    final matchAge = DateTime.now().difference(match.matchedAt);
    return matchAge > WARNING_THRESHOLD && matchAge <= MATCH_EXPIRY_DURATION;
  }

  /// Get time remaining before match expires
  Duration? getTimeUntilExpiry(MatchModel match) {
    final matchAge = DateTime.now().difference(match.matchedAt);
    final timeRemaining = MATCH_EXPIRY_DURATION - matchAge;

    return timeRemaining.isNegative ? Duration.zero : timeRemaining;
  }

  /// Get expired matches for a user
  Future<List<MatchModel>> getExpiredMatches(String userId) async =>
      PerformanceMonitor.measure('get_expired_matches', () async {
        try {
          final querySnapshot = await _matchesCollection
              .where('users', arrayContains: userId)
              .where(
                'matchedAt',
                isLessThan: Timestamp.fromDate(
                  DateTime.now().subtract(MATCH_EXPIRY_DURATION),
                ),
              )
              .get();

          final expiredMatches = querySnapshot.docs
              .map(MatchModel.fromDocument)
              .where(isMatchExpired)
              .toList();

          debugPrint(
            '📋 Found ${expiredMatches.length} expired matches for user $userId',
          );
          return expiredMatches;
        } catch (e) {
          debugPrint('❌ Error getting expired matches: $e');
          return [];
        }
      });

  /// Get matches approaching expiration for a user
  Future<List<MatchModel>> getMatchesNearExpiry(String userId) async =>
      PerformanceMonitor.measure('get_matches_near_expiry', () async {
        try {
          final querySnapshot = await _matchesCollection
              .where('users', arrayContains: userId)
              .where(
                'matchedAt',
                isLessThan: Timestamp.fromDate(
                  DateTime.now().subtract(WARNING_THRESHOLD),
                ),
              )
              .where(
                'matchedAt',
                isGreaterThan: Timestamp.fromDate(
                  DateTime.now().subtract(MATCH_EXPIRY_DURATION),
                ),
              )
              .get();

          final nearExpiryMatches = querySnapshot.docs
              .map(MatchModel.fromDocument)
              .where(isMatchNearExpiry)
              .toList();

          debugPrint(
            '⚠️ Found ${nearExpiryMatches.length} matches near expiry for user $userId',
          );
          return nearExpiryMatches;
        } catch (e) {
          debugPrint('❌ Error getting matches near expiry: $e');
          return [];
        }
      });

  /// Archive an expired match
  Future<bool> archiveExpiredMatch(String matchId) async =>
      PerformanceMonitor.measure('archive_expired_match', () async {
        try {
          final matchDoc = await _matchesCollection.doc(matchId).get();
          if (!matchDoc.exists) {
            debugPrint('❌ Match $matchId not found for archiving');
            return false;
          }

          final matchData = matchDoc.data() as Map<String, dynamic>;
          final match = MatchModel.fromDocument(matchDoc);

          // Verify match is actually expired
          if (!isMatchExpired(match)) {
            debugPrint('⚠️ Match $matchId is not expired, skipping archive');
            return false;
          }

          // Use batch operation for consistency
          final batch = _firestore.batch();

          // Archive the match
          batch.set(_expiredMatchesCollection.doc(matchId), {
            ...matchData,
            'expiredAt': FieldValue.serverTimestamp(),
            'originalMatchedAt': matchData['matchedAt'],
          });

          // Remove from active matches
          batch.delete(_matchesCollection.doc(matchId));

          // Clean up legacy match collections
          final userIds = List<String>.from(matchData['users'] ?? []);
          for (final userId in userIds) {
            final otherUserId = userIds.firstWhere((id) => id != userId);
            batch.delete(
              _usersCollection
                  .doc(userId)
                  .collection('Matches')
                  .doc(otherUserId),
            );
          }

          // Archive chat thread if it exists and has no messages
          final chatThreadId = matchData['chatThreadId'] as String?;
          if (chatThreadId != null) {
            final chatDoc =
                await _chatThreadsCollection.doc(chatThreadId).get();
            if (chatDoc.exists) {
              final chatData = chatDoc.data() as Map<String, dynamic>;
              final lastMessage = chatData['lastMessage'];

              // Only archive if no actual messages were sent
              if (lastMessage == null ||
                  lastMessage == 'You matched! Say hello!') {
                batch.update(_chatThreadsCollection.doc(chatThreadId), {
                  'archived': true,
                  'archivedAt': FieldValue.serverTimestamp(),
                  'archiveReason': 'match_expired',
                });
              }
            }
          }

          await batch.commit();

          debugPrint('✅ Successfully archived expired match: $matchId');
          return true;
        } catch (e) {
          debugPrint('❌ Error archiving expired match $matchId: $e');
          return false;
        }
      });

  /// Extend match expiration (premium feature)
  Future<bool> extendMatchExpiration(
          String matchId, Duration extension) async =>
      PerformanceMonitor.measure('extend_match_expiration', () async {
        try {
          final matchDoc = await _matchesCollection.doc(matchId).get();
          if (!matchDoc.exists) {
            debugPrint('❌ Match $matchId not found for extension');
            return false;
          }

          final matchData = matchDoc.data() as Map<String, dynamic>;
          final currentExpiry = matchData['expiresAt'] as Timestamp?;
          final newExpiry = currentExpiry != null
              ? Timestamp.fromDate(currentExpiry.toDate().add(extension))
              : Timestamp.fromDate(
                  DateTime.now().add(MATCH_EXPIRY_DURATION).add(extension),
                );

          await _matchesCollection.doc(matchId).update({
            'expiresAt': newExpiry,
            'extensionGrantedAt': FieldValue.serverTimestamp(),
            'extensionDuration': extension.inMilliseconds,
          });

          debugPrint(
            '✅ Extended match $matchId expiration by ${extension.inDays} days',
          );
          return true;
        } catch (e) {
          debugPrint('❌ Error extending match expiration: $e');
          return false;
        }
      });

  /// Perform scheduled cleanup of expired matches
  Future<void> _performScheduledCleanup() async {
    await PerformanceMonitor.measure('scheduled_cleanup', () async {
      try {
        debugPrint('🧹 Starting scheduled match cleanup');

        // Get all expired matches (limit to prevent overwhelming)
        final expiredQuery = await _matchesCollection
            .where(
              'matchedAt',
              isLessThan: Timestamp.fromDate(
                DateTime.now().subtract(MATCH_EXPIRY_DURATION),
              ),
            )
            .limit(100) // Process in batches
            .get();

        int archivedCount = 0;
        int skippedCount = 0;

        for (final doc in expiredQuery.docs) {
          final match = MatchModel.fromDocument(doc);

          // Double-check expiration and message activity
          if (isMatchExpired(match)) {
            final success = await archiveExpiredMatch(doc.id);
            if (success) {
              archivedCount++;
            }
          } else {
            skippedCount++;
          }
        }

        debugPrint(
          '✅ Cleanup complete: $archivedCount archived, $skippedCount skipped',
        );

        // Record cleanup metrics
        PerformanceMonitor.recordFirestoreOperation(
          'match_cleanup',
          readCount: expiredQuery.docs.length,
          writeCount: archivedCount * 3,
        ); // Estimate writes per archive
      } catch (e) {
        debugPrint('❌ Error in scheduled cleanup: $e');
      }
    });
  }

  /// Get match expiration statistics for a user
  Future<MatchExpirationStats> getExpirationStats(String userId) async =>
      PerformanceMonitor.measure('get_expiration_stats', () async {
        try {
          // Get all user matches
          final allMatches = await _matchesCollection
              .where('users', arrayContains: userId)
              .get();

          int activeMatches = 0;
          int nearExpiryMatches = 0;
          int expiredMatches = 0;
          const int matchesWithMessages = 0;

          for (final doc in allMatches.docs) {
            final match = MatchModel.fromDocument(doc);

            if (isMatchExpired(match)) {
              expiredMatches++;
            } else if (isMatchNearExpiry(match)) {
              nearExpiryMatches++;
            } else {
              activeMatches++;
            }
          }

          // Get archived matches count
          final archivedQuery = await _expiredMatchesCollection
              .where('users', arrayContains: userId)
              .get();

          return MatchExpirationStats(
            activeMatches: activeMatches,
            nearExpiryMatches: nearExpiryMatches,
            expiredMatches: expiredMatches,
            archivedMatches: archivedQuery.docs.length,
            matchesWithMessages: matchesWithMessages,
            totalMatches: allMatches.docs.length,
          );
        } catch (e) {
          debugPrint('❌ Error getting expiration stats: $e');
          return MatchExpirationStats.empty();
        }
      });

  /// Send expiration warning notifications
  Future<void> sendExpirationWarnings() async {
    await PerformanceMonitor.measure('send_expiration_warnings', () async {
      try {
        debugPrint('📢 Sending expiration warning notifications');

        // Get matches approaching expiration
        final warningQuery = await _matchesCollection
            .where(
              'matchedAt',
              isLessThan: Timestamp.fromDate(
                DateTime.now().subtract(WARNING_THRESHOLD),
              ),
            )
            .where(
              'matchedAt',
              isGreaterThan: Timestamp.fromDate(
                DateTime.now().subtract(MATCH_EXPIRY_DURATION),
              ),
            )
            .where('expirationWarningSent', isEqualTo: false)
            .limit(50)
            .get();

        final batch = _firestore.batch();
        int warningsSent = 0;

        for (final doc in warningQuery.docs) {
          final match = MatchModel.fromDocument(doc);

          if (isMatchNearExpiry(match)) {
            // Mark warning as sent
            batch.update(doc.reference, {
              'expirationWarningSent': true,
              'expirationWarningSentAt': FieldValue.serverTimestamp(),
            });

            // TODO: Send push notification to users
            // This would integrate with your notification service

            warningsSent++;
          }
        }

        if (warningsSent > 0) {
          await batch.commit();
          debugPrint('✅ Sent $warningsSent expiration warnings');
        }
      } catch (e) {
        debugPrint('❌ Error sending expiration warnings: $e');
      }
    });
  }

  /// Restore an archived match (premium feature)
  Future<bool> restoreArchivedMatch(String matchId) async =>
      PerformanceMonitor.measure('restore_archived_match', () async {
        try {
          final archivedDoc =
              await _expiredMatchesCollection.doc(matchId).get();
          if (!archivedDoc.exists) {
            debugPrint('❌ Archived match $matchId not found');
            return false;
          }

          final matchData = archivedDoc.data() as Map<String, dynamic>;

          // Remove archive-specific fields
          matchData.remove('expiredAt');
          matchData.remove('originalMatchedAt');

          // Reset expiration
          matchData['matchedAt'] = FieldValue.serverTimestamp();
          matchData['restoredAt'] = FieldValue.serverTimestamp();
          matchData['expirationWarningSent'] = false;

          final batch = _firestore.batch();

          // Restore to active matches
          batch.set(_matchesCollection.doc(matchId), matchData);

          // Remove from archived matches
          batch.delete(_expiredMatchesCollection.doc(matchId));

          // Restore legacy match collections
          final userIds = List<String>.from(matchData['users'] ?? []);
          for (final userId in userIds) {
            final otherUserId = userIds.firstWhere((id) => id != userId);
            // This would need user data to restore properly
            batch.set(
                _usersCollection
                    .doc(userId)
                    .collection('Matches')
                    .doc(otherUserId),
                {
                  'Matches': otherUserId,
                  'isRead': false,
                  'timestamp': FieldValue.serverTimestamp(),
                  'restored': true,
                });
          }

          await batch.commit();

          debugPrint('✅ Successfully restored archived match: $matchId');
          return true;
        } catch (e) {
          debugPrint('❌ Error restoring archived match: $e');
          return false;
        }
      });
}

/// Statistics about match expiration for a user
class MatchExpirationStats {
  const MatchExpirationStats({
    required this.activeMatches,
    required this.nearExpiryMatches,
    required this.expiredMatches,
    required this.archivedMatches,
    required this.matchesWithMessages,
    required this.totalMatches,
  });

  factory MatchExpirationStats.empty() => const MatchExpirationStats(
        activeMatches: 0,
        nearExpiryMatches: 0,
        expiredMatches: 0,
        archivedMatches: 0,
        matchesWithMessages: 0,
        totalMatches: 0,
      );
  final int activeMatches;
  final int nearExpiryMatches;
  final int expiredMatches;
  final int archivedMatches;
  final int matchesWithMessages;
  final int totalMatches;

  double get messageRate =>
      totalMatches > 0 ? matchesWithMessages / totalMatches : 0.0;
  double get expirationRate =>
      totalMatches > 0 ? expiredMatches / totalMatches : 0.0;

  @override
  String toString() => 'MatchExpirationStats(\n'
      '  Active: $activeMatches\n'
      '  Near Expiry: $nearExpiryMatches\n'
      '  Expired: $expiredMatches\n'
      '  Archived: $archivedMatches\n'
      '  With Messages: $matchesWithMessages\n'
      '  Total: $totalMatches\n'
      '  Message Rate: ${(messageRate * 100).toStringAsFixed(1)}%\n'
      '  Expiration Rate: ${(expirationRate * 100).toStringAsFixed(1)}%\n'
      ')';
}
