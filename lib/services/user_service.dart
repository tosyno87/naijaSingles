import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../common/utils/app_logger.dart';

/// Service for managing user data and profiles
class UserService {
  factory UserService() => _instance;
  UserService._internal();
  static final UserService _instance = UserService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get user profile data by ID
  Future<UserProfile?> getUserProfile(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();

      if (doc.exists) {
        return UserProfile.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      AppLogger.error('Error getting user profile', error: e);
      return null;
    }
  }

  /// Get multiple user profiles by IDs
  Future<List<UserProfile>> getUserProfiles(List<String> userIds) async {
    try {
      if (userIds.isEmpty) return [];

      final futures = userIds.map(getUserProfile);
      final results = await Future.wait(futures);

      return results
          .where((profile) => profile != null)
          .cast<UserProfile>()
          .toList();
    } catch (e) {
      AppLogger.error('Error getting user profiles', error: e);
      return [];
    }
  }

  /// Get current user profile
  Future<UserProfile?> getCurrentUserProfile() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return null;

    return getUserProfile(currentUser.uid);
  }

  /// Search users by name
  Future<List<UserProfile>> searchUsers(String query) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('displayName', isGreaterThanOrEqualTo: query)
          .where('displayName', isLessThan: '$query\uf8ff')
          .limit(20)
          .get();

      return snapshot.docs
          .map((doc) => UserProfile.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      AppLogger.error('Error searching users', error: e);
      return [];
    }
  }

  /// Update user profile
  Future<bool> updateUserProfile(UserProfile profile) async {
    try {
      await _firestore
          .collection('users')
          .doc(profile.id)
          .update(profile.toMap());
      return true;
    } catch (e) {
      AppLogger.error('Error updating user profile', error: e);
      return false;
    }
  }

  /// Get user's display name
  Future<String> getUserDisplayName(String userId) async {
    try {
      final profile = await getUserProfile(userId);
      return profile?.displayName ?? 'Unknown User';
    } catch (e) {
      AppLogger.error('Error getting user display name', error: e);
      return 'Unknown User';
    }
  }

  /// Get user's avatar URL
  Future<String?> getUserAvatarUrl(String userId) async {
    try {
      final profile = await getUserProfile(userId);
      return profile?.avatarUrl;
    } catch (e) {
      AppLogger.error('Error getting user avatar URL', error: e);
      return null;
    }
  }

  /// Check if user exists
  Future<bool> userExists(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      return doc.exists;
    } catch (e) {
      AppLogger.error('Error checking if user exists', error: e);
      return false;
    }
  }
}

/// User profile model
class UserProfile {

  UserProfile({
    required this.id,
    required this.displayName,
    required this.createdAt, required this.updatedAt, this.email,
    this.avatarUrl,
    this.preferences,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map, String id) => UserProfile(
      id: id,
      displayName: map['displayName'] ?? 'Unknown User',
      email: map['email'],
      avatarUrl: map['avatarUrl'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      preferences: map['preferences'] as Map<String, dynamic>?,
    );
  final String id;
  final String displayName;
  final String? email;
  final String? avatarUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? preferences;

  Map<String, dynamic> toMap() => {
      'displayName': displayName,
      'email': email,
      'avatarUrl': avatarUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'preferences': preferences,
    };

  /// Get user's initials for avatar
  String get initials {
    if (displayName.isEmpty) return '?';
    final words = displayName.trim().split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return displayName[0].toUpperCase();
  }

  /// Get user's first name
  String get firstName {
    if (displayName.isEmpty) return 'Unknown';
    return displayName.trim().split(' ').first;
  }

  UserProfile copyWith({
    String? id,
    String? displayName,
    String? email,
    String? avatarUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? preferences,
  }) => UserProfile(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      preferences: preferences ?? this.preferences,
    );

  @override
  String toString() => 'UserProfile(id: $id, displayName: $displayName, email: $email, avatarUrl: $avatarUrl)';
}
