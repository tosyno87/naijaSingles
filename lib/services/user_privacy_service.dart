import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Privacy settings for user profile visibility.
///
/// Several fields are not user-configurable: matches can always message each
/// other, activity/last-active sync is always on, and orientation is not
/// exposed via this privacy layer. [fromMap] / [toMap] / [updatePrivacySettings]
/// enforce that.
class UserPrivacySettings {
  const UserPrivacySettings({
    // Fixed policy (not loaded from Firestore)
    this.allowMessagesFromMatches = true,
    this.showOnlineStatus = true,
    this.showLastActive = true,
    this.showOrientation = false,

    // Profile visibility defaults
    this.showTribe = true,
    this.showAge = true,
    this.hideFromDiscovery = false,

    // Location — always on (Hinge-style: neighborhood + distance for matching).
    this.showLocation = true,
    this.showDistance = true,
  });

  /// Only [showTribe] and [hideFromDiscovery] are read from storage; other
  /// flags use app policy defaults above.
  factory UserPrivacySettings.fromMap(Map<String, dynamic> map) =>
      UserPrivacySettings(
        showTribe: map['showTribe'] ?? true,
        hideFromDiscovery: map['hideFromDiscovery'] ?? false,
      );

  /// Matches can always message (and community chat is separate).
  final bool allowMessagesFromMatches;

  /// Retained for backwards-compatible [toMap]; always true in practice.
  final bool showOnlineStatus;
  final bool showLastActive;

  final bool showTribe;

  /// Sexual orientation is not published via the public profile from privacy.
  final bool showOrientation;
  final bool showAge;
  final bool hideFromDiscovery;

  /// Always true — kept for backwards-compatible [toMap] / internal calls.
  final bool showLocation;
  final bool showDistance;

  Map<String, dynamic> toMap() => {
        'allowMessagesFromMatches': true,
        'showOnlineStatus': true,
        'showLastActive': true,
        'showTribe': showTribe,
        'showOrientation': false,
        'showAge': true,
        'hideFromDiscovery': hideFromDiscovery,
        'showLocation': true,
        'showDistance': true,
        'updatedAt': FieldValue.serverTimestamp(),
      };

  UserPrivacySettings copyWith({
    // Communication
    bool? allowMessagesFromMatches,

    // Activity Status
    bool? showOnlineStatus,
    bool? showLastActive,

    // Profile Visibility
    bool? showTribe,
    bool? showOrientation,
    bool? showAge,
    bool? hideFromDiscovery,

    // Location Privacy
    bool? showLocation,
    bool? showDistance,
  }) =>
      UserPrivacySettings(
        // Communication
        allowMessagesFromMatches:
            allowMessagesFromMatches ?? this.allowMessagesFromMatches,

        // Activity Status
        showOnlineStatus: showOnlineStatus ?? this.showOnlineStatus,
        showLastActive: showLastActive ?? this.showLastActive,

        // Profile Visibility
        showTribe: showTribe ?? this.showTribe,
        showOrientation: showOrientation ?? this.showOrientation,
        showAge: showAge ?? this.showAge,
        hideFromDiscovery: hideFromDiscovery ?? this.hideFromDiscovery,

        // Location Privacy
        showLocation: showLocation ?? this.showLocation,
        showDistance: showDistance ?? this.showDistance,
      );
}

/// Service for managing user privacy settings
class UserPrivacyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  /// Get user's privacy settings
  Future<UserPrivacySettings> getPrivacySettings() async {
    try {
      if (currentUserId == null) {
        return const UserPrivacySettings();
      }

      final doc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('private')
          .doc('privacy')
          .get();

      if (doc.exists) {
        return UserPrivacySettings.fromMap(doc.data()!);
      } else {
        // Return default settings and save them
        const defaultSettings = UserPrivacySettings();
        await updatePrivacySettings(defaultSettings);
        return defaultSettings;
      }
    } on Object catch (e) {
      debugPrint('Error getting privacy settings: $e');
      return const UserPrivacySettings();
    }
  }

  /// Update user's privacy settings
  Future<bool> updatePrivacySettings(UserPrivacySettings settings) async {
    try {
      if (currentUserId == null) {
        return false;
      }

      final effective = settings.copyWith(
        showAge: true,
        showLocation: true,
        showDistance: true,
        allowMessagesFromMatches: true,
        showOnlineStatus: true,
        showLastActive: true,
        showOrientation: false,
      );

      final userRef = _firestore.collection('users').doc(currentUserId);

      await userRef
          .collection('private')
          .doc('privacy')
          .set(effective.toMap(), SetOptions(merge: true));

      // Keep the root-level discovery flag in sync so that the Firestore
      // query `where('isDiscoverable', isEqualTo: true)` in
      // DiscoveryService honours the privacy toggle.
      await userRef.update({
        'isDiscoverable': !effective.hideFromDiscovery,
      });

      await _updatePublicProfile(effective);

      return true;
    } on Object catch (e) {
      debugPrint('Error updating privacy settings: $e');
      return false;
    }
  }

  /// Update public profile based on privacy settings
  Future<void> _updatePublicProfile(UserPrivacySettings settings) async {
    try {
      if (currentUserId == null) {
        return;
      }

      // Get current user data
      final userDoc =
          await _firestore.collection('users').doc(currentUserId).get();

      if (!userDoc.exists) {
        return;
      }

      final userData = userDoc.data()!;
      final Map<String, dynamic> publicData = {};

      // Always include basic info
      publicData['name'] = userData['name'];
      publicData['bio'] = userData['bio'];
      publicData['photos'] = userData['photos'];
      publicData['interests'] = userData['interests'];
      publicData['lookingFor'] = userData['lookingFor'];
      publicData['relationshipIntent'] = userData['relationshipIntent'];

      // Conditionally include based on privacy settings
      if (settings.showAge) {
        publicData['age'] = userData['age'];
        publicData['showMyAge'] = userData['showMyAge'];
      }

      if (settings.showTribe) {
        publicData['tribe'] = userData['tribe'];
      }

      if (settings.showLocation) {
        publicData['living_in'] = userData['living_in'];
        publicData['city'] = userData['city'];
        publicData['state'] = userData['state'];
        publicData['country'] = userData['country'];

        if (settings.showDistance) {
          publicData['geoHash'] = userData['geoHash'];
          // Use default medium precision for all users
        }
      }

      publicData['lastActive'] = userData['lastActive'];

      // Merge does not remove absent keys — scrub legacy orientation from
      // `users/{id}/public/profile` if it was written by older app versions.
      publicData['sexualOrientation'] = FieldValue.delete();

      // Update the public profile
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('public')
          .doc('profile')
          .set(publicData, SetOptions(merge: true));
    } on Object catch (e) {
      debugPrint('Error updating public profile: $e');
    }
  }

  /// Get filtered user data based on privacy settings.
  ///
  /// For the current user we read `/users/{uid}/private/privacy` to apply
  /// their own privacy prefs. For **other** users the private subcollection
  /// is owner-only, so we fall back to default privacy settings (all fields
  /// visible) and read only the public profile or main document.
  Future<Map<String, dynamic>?> getFilteredUserData(String userId) async {
    try {
      final currentUid = FirebaseAuth.instance.currentUser?.uid;
      final isOwner = currentUid != null && currentUid == userId;

      UserPrivacySettings privacy;
      if (isOwner) {
        final privacyDoc = await _firestore
            .collection('users')
            .doc(userId)
            .collection('private')
            .doc('privacy')
            .get();
        privacy = privacyDoc.exists
            ? UserPrivacySettings.fromMap(privacyDoc.data()!)
            : const UserPrivacySettings();
      } else {
        privacy = const UserPrivacySettings();
      }

      // Try public profile subcollection first
      final publicDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('public')
          .doc('profile')
          .get();

      if (!publicDoc.exists) {
        final userDoc = await _firestore.collection('users').doc(userId).get();

        if (userDoc.exists) {
          return _filterUserData(userDoc.data()!, privacy);
        }
        return null;
      }

      return stripLegacySexualOrientation(publicDoc.data()!);
    } on Object catch (e) {
      debugPrint('Error getting filtered user data: $e');
      return null;
    }
  }

  /// Stale `users/{id}/public/profile` documents may still contain
  /// [sexualOrientation] from older app versions; never expose it to callers.
  static Map<String, dynamic> stripLegacySexualOrientation(
    Map<String, dynamic> data,
  ) {
    final out = Map<String, dynamic>.from(data);
    out.remove('sexualOrientation');
    return out;
  }

  /// Apply default privacy filtering to already-fetched user data.
  ///
  /// Unlike [_filterUserData] (which builds a whitelist of display fields),
  /// this preserves all operational fields (lat/lng, geoHash, photos, etc.)
  /// needed for discovery while masking display-sensitive fields according
  /// to default privacy settings. We cannot read another user's private
  /// privacy document from the client, so defaults are applied.
  Map<String, dynamic> filterForDiscovery(Map<String, dynamic> rawData) {
    final data = Map<String, dynamic>.from(rawData);
    const privacy = UserPrivacySettings();

    // Age and location are always visible for discovery (app policy).
    if (!privacy.showTribe) {
      data.remove('tribe');
    }
    data.remove('sexualOrientation');

    return data;
  }

  /// Filter user data based on privacy settings
  Map<String, dynamic> _filterUserData(
    Map<String, dynamic> userData,
    UserPrivacySettings privacy,
  ) {
    final Map<String, dynamic> filteredData = {
      'name': userData['name'],
      'bio': userData['bio'],
      'photos': userData['photos'],
      'interests': userData['interests'],
      'lookingFor': userData['lookingFor'],
      'relationshipIntent': userData['relationshipIntent'],
    };

    if (privacy.showAge) {
      filteredData['age'] = userData['age'];
    }

    if (privacy.showTribe) {
      filteredData['tribe'] = userData['tribe'];
    }

    if (privacy.showLocation) {
      filteredData['living_in'] = userData['living_in'];
      filteredData['city'] = userData['city'];
      filteredData['state'] = userData['state'];
    }

    filteredData['lastActive'] = userData['lastActive'];

    return filteredData;
  }

  /// Whether the current user may message [targetUserId] (mutual match).
  Future<bool> canSendMessage(String targetUserId) async {
    try {
      if (currentUserId == null) {
        return false;
      }
      return _checkIfMatched(currentUserId!, targetUserId);
    } on Object catch (e) {
      debugPrint('Error checking message permission: $e');
      return false;
    }
  }

  /// Check whether two users have a mutual match in the `matches` collection.
  Future<bool> _checkIfMatched(String userId1, String userId2) async {
    final snapshot = await _firestore
        .collection('matches')
        .where('users', arrayContains: userId1)
        .get();

    for (final doc in snapshot.docs) {
      final users = List<String>.from(
        (doc.data()['users'] as List<dynamic>?) ?? <String>[],
      );
      if (users.contains(userId2)) {
        return true;
      }
    }
    return false;
  }

  /// Get privacy summary for display
  String getPrivacySummary(UserPrivacySettings settings) {
    final List<String> activeSettings = [];

    if (settings.hideFromDiscovery) {
      return 'Profile hidden from discovery';
    }

    if (!settings.showTribe) {
      activeSettings.add('Tribe hidden');
    }

    if (activeSettings.isEmpty) {
      return 'All profile information visible';
    } else if (activeSettings.length == 1) {
      return activeSettings.first;
    } else if (activeSettings.length <= 3) {
      return activeSettings.join(', ');
    } else {
      return '${activeSettings.length} privacy settings active';
    }
  }
}
