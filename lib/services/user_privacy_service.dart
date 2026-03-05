import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Privacy settings for user profile visibility
class UserPrivacySettings {
  const UserPrivacySettings({
    // Communication defaults
    this.allowMessagesFromMatches = true,

    // Activity defaults
    this.showOnlineStatus = true,
    this.showLastActive = true,

    // Profile visibility defaults
    this.showTribe = true,
    this.showOrientation = false, // More private by default
    this.showAge = true,
    this.hideFromDiscovery = false,

    // Location defaults
    this.showLocation = true,
    this.showDistance = true,
  });

  factory UserPrivacySettings.fromMap(Map<String, dynamic> map) =>
      UserPrivacySettings(
        // Communication
        allowMessagesFromMatches: map['allowMessagesFromMatches'] ?? true,

        // Activity Status
        showOnlineStatus: map['showOnlineStatus'] ?? true,
        showLastActive: map['showLastActive'] ?? true,

        // Profile Visibility
        showTribe: map['showTribe'] ?? true,
        showOrientation: map['showOrientation'] ?? false,
        showAge: map['showAge'] ?? true,
        hideFromDiscovery: map['hideFromDiscovery'] ?? false,

        // Location Privacy
        showLocation: map['showLocation'] ?? true,
        showDistance: map['showDistance'] ?? true,
      );
  // Communication Settings
  final bool allowMessagesFromMatches;

  // Activity Status
  final bool showOnlineStatus;
  final bool showLastActive;

  // Profile Visibility
  final bool showTribe;
  final bool showOrientation;
  final bool showAge;
  final bool hideFromDiscovery;

  // Location Privacy
  final bool showLocation;
  final bool showDistance;

  Map<String, dynamic> toMap() => {
        // Communication
        'allowMessagesFromMatches': allowMessagesFromMatches,

        // Activity Status
        'showOnlineStatus': showOnlineStatus,
        'showLastActive': showLastActive,

        // Profile Visibility
        'showTribe': showTribe,
        'showOrientation': showOrientation,
        'showAge': showAge,
        'hideFromDiscovery': hideFromDiscovery,

        // Location Privacy
        'showLocation': showLocation,
        'showDistance': showDistance,

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
      if (currentUserId == null) return false;

      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('private')
          .doc('privacy')
          .set(settings.toMap(), SetOptions(merge: true));

      // Update public profile based on privacy settings
      await _updatePublicProfile(settings);

      return true;
    } on Object catch (e) {
      debugPrint('Error updating privacy settings: $e');
      return false;
    }
  }

  /// Update public profile based on privacy settings
  Future<void> _updatePublicProfile(UserPrivacySettings settings) async {
    try {
      if (currentUserId == null) return;

      // Get current user data
      final userDoc =
          await _firestore.collection('users').doc(currentUserId).get();

      if (!userDoc.exists) return;

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

      if (settings.showOrientation) {
        publicData['sexualOrientation'] = userData['sexualOrientation'];
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

      if (settings.showLastActive) {
        publicData['lastActive'] = userData['lastActive'];
      }

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

  /// Get filtered user data based on privacy settings
  Future<Map<String, dynamic>?> getFilteredUserData(String userId) async {
    try {
      // Get user's privacy settings
      final privacyDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('private')
          .doc('privacy')
          .get();

      UserPrivacySettings privacy;
      if (privacyDoc.exists) {
        privacy = UserPrivacySettings.fromMap(privacyDoc.data()!);
      } else {
        privacy = const UserPrivacySettings();
      }

      // Get public profile data
      final publicDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('public')
          .doc('profile')
          .get();

      if (!publicDoc.exists) {
        // Fallback to main user document
        final userDoc = await _firestore.collection('users').doc(userId).get();

        if (userDoc.exists) {
          return _filterUserData(userDoc.data()!, privacy);
        }
        return null;
      }

      return publicDoc.data();
    } on Object catch (e) {
      debugPrint('Error getting filtered user data: $e');
      return null;
    }
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

    if (privacy.showOrientation) {
      filteredData['sexualOrientation'] = userData['sexualOrientation'];
    }

    if (privacy.showLocation) {
      filteredData['living_in'] = userData['living_in'];
      filteredData['city'] = userData['city'];
      filteredData['state'] = userData['state'];
    }

    if (privacy.showLastActive) {
      filteredData['lastActive'] = userData['lastActive'];
    }

    return filteredData;
  }

  /// Check if user allows messages from current user
  Future<bool> canSendMessage(String targetUserId) async {
    try {
      if (currentUserId == null) return false;

      // Get target user's privacy settings
      final privacyDoc = await _firestore
          .collection('users')
          .doc(targetUserId)
          .collection('private')
          .doc('privacy')
          .get();

      UserPrivacySettings privacy;
      if (privacyDoc.exists) {
        privacy = UserPrivacySettings.fromMap(privacyDoc.data()!);
      } else {
        privacy = const UserPrivacySettings();
      }

      // Check if users are matched
      // This would integrate with your existing match checking logic
      final bool areMatched =
          await _checkIfMatched(currentUserId!, targetUserId);

      if (areMatched && privacy.allowMessagesFromMatches) {
        return true;
      }

      // For now, only allow messages from matches
      // This simplifies the messaging system
      return false;
    } on Object catch (e) {
      debugPrint('Error checking message permission: $e');
      return false;
    }
  }

  /// Check if users are matched (placeholder - integrate with your match service)
  Future<bool> _checkIfMatched(String userId1, String userId2) async {
    // This should integrate with your existing match checking logic
    // For now, return false as placeholder
    return false;
  }

  /// Get privacy summary for display
  String getPrivacySummary(UserPrivacySettings settings) {
    final List<String> activeSettings = [];

    if (settings.hideFromDiscovery) {
      return 'Profile hidden from discovery';
    }

    if (!settings.showAge) activeSettings.add('Age hidden');
    if (!settings.showTribe) activeSettings.add('Tribe hidden');
    if (!settings.showOrientation) activeSettings.add('Orientation private');
    if (!settings.showLocation) activeSettings.add('Location private');
    if (!settings.allowMessagesFromMatches) {
      activeSettings.add('Messages restricted');
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
