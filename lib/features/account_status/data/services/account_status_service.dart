import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Manages user account status transitions (active, paused, incognito).
///
/// Status values stored in Firestore `users/{uid}.accountStatus`:
///   - `active`    – default, fully discoverable
///   - `paused`    – temporarily hidden from discovery; matches & chats intact
///   - `incognito` – hidden from discovery; matches & chats still accessible
///   - `deleted`   – soft-deleted (handled by existing deletion flow)
///   - `banned`    – admin-banned (handled by moderation)
class AccountStatusService {
  AccountStatusService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  /// Valid statuses the *user* can self-assign.
  static const Set<String> userAssignableStatuses = {
    'active',
    'paused',
    'incognito',
  };

  /// Pause the account — hidden from discovery, matches/chats preserved.
  Future<void> pauseAccount({
    required String userId,
    String? reason,
  }) async {
    await _setStatus(
      userId: userId,
      status: 'paused',
      reason: reason,
    );
    debugPrint('⏸️ Account paused for user $userId');
  }

  /// Enable incognito mode — hidden from discovery, matches/chats accessible.
  Future<void> enableIncognito({
    required String userId,
    String? reason,
  }) async {
    await _setStatus(
      userId: userId,
      status: 'incognito',
      reason: reason,
    );
    debugPrint('🕵️ Incognito enabled for user $userId');
  }

  /// Reactivate the account — fully discoverable again.
  Future<void> reactivateAccount({required String userId}) async {
    await _usersCollection.doc(userId).update({
      'accountStatus': 'active',
      'deactivatedAt': FieldValue.delete(),
      'deactivationReason': FieldValue.delete(),
      'reactivatedAt': FieldValue.serverTimestamp(),
    });
    debugPrint('✅ Account reactivated for user $userId');
  }

  /// Read the current account status from Firestore.
  Future<String> getAccountStatus(String userId) async {
    final doc = await _usersCollection.doc(userId).get();
    if (!doc.exists) return 'active';
    final data = doc.data();
    return (data?['accountStatus'] as String?) ?? 'active';
  }

  /// Stream the account status for real-time UI updates.
  Stream<String> watchAccountStatus(String userId) =>
      _usersCollection.doc(userId).snapshots().map((snap) {
        if (!snap.exists) return 'active';
        final data = snap.data();
        return (data?['accountStatus'] as String?) ?? 'active';
      });

  // ─── Private helpers ──────────────────────────────────────────────

  Future<void> _setStatus({
    required String userId,
    required String status,
    String? reason,
  }) async {
    assert(
      userAssignableStatuses.contains(status),
      'Invalid status: $status',
    );

    final Map<String, dynamic> updates = {
      'accountStatus': status,
      'deactivatedAt': FieldValue.serverTimestamp(),
    };
    if (reason != null && reason.isNotEmpty) {
      updates['deactivationReason'] = reason;
    }

    await _usersCollection.doc(userId).update(updates);
  }
}
