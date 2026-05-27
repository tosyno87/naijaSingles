import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Manages paid profile boost windows for discovery ranking.
class ProfileBoostService {
  ProfileBoostService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const Duration defaultBoostDuration = Duration(hours: 1);

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  /// Whether [userId] has an active boost right now.
  Future<bool> isBoostActive(String userId) async {
    try {
      final doc = await _users.doc(userId).get();
      if (!doc.exists) return false;
      final expiresAt = doc.data()?['boostExpiresAt'];
      if (expiresAt is! Timestamp) return false;
      return expiresAt.toDate().isAfter(DateTime.now());
    } on Object catch (e) {
      debugPrint('ProfileBoostService.isBoostActive error: $e');
      return false;
    }
  }

  /// Remaining boost time, or null if inactive.
  Future<Duration?> boostTimeRemaining(String userId) async {
    try {
      final doc = await _users.doc(userId).get();
      if (!doc.exists) return null;
      final expiresAt = doc.data()?['boostExpiresAt'];
      if (expiresAt is! Timestamp) return null;
      final remaining = expiresAt.toDate().difference(DateTime.now());
      return remaining.isNegative ? null : remaining;
    } on Object catch (e) {
      debugPrint('ProfileBoostService.boostTimeRemaining error: $e');
      return null;
    }
  }

  /// Activates boost after successful IAP consumable purchase.
  Future<void> activateBoost({
    required String userId,
    Duration duration = defaultBoostDuration,
    String? productId,
  }) async {
    final expiresAt = DateTime.now().add(duration);
    await _users.doc(userId).set(
      {
        'boostExpiresAt': Timestamp.fromDate(expiresAt),
        'boostActivatedAt': FieldValue.serverTimestamp(),
        if (productId != null) 'boostProductId': productId,
      },
      SetOptions(merge: true),
    );
    await _firestore.collection('boosts').add({
      'userId': userId,
      'expiresAt': Timestamp.fromDate(expiresAt),
      'productId': productId,
      'createdAt': FieldValue.serverTimestamp(),
    });
    debugPrint('Profile boost active for $userId until $expiresAt');
  }

  /// Sort so boosted profiles appear earlier in discovery lists.
  static List<T> sortWithBoostPriority<T>({
    required List<T> items,
    required bool Function(T item) isBoosted,
  }) {
    final boosted = <T>[];
    final normal = <T>[];
    for (final item in items) {
      if (isBoosted(item)) {
        boosted.add(item);
      } else {
        normal.add(item);
      }
    }
    return [...boosted, ...normal];
  }
}
