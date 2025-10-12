import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service for managing user data and profiles
class UserService {
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

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
      print('Error getting user profile: $e');
      return null;
    }
  }

  /// Get multiple user profiles by IDs
  Future<List<UserProfile>> getUserProfiles(List<String> userIds) async {
    try {
      if (userIds.isEmpty) return [];

      final futures = userIds.map((id) => getUserProfile(id));
      final results = await Future.wait(futures);

      return results
          .where((profile) => profile != null)
          .cast<UserProfile>()
          .toList();
    } catch (e) {
      print('Error getting user profiles: $e');
      return [];
    }
  }

  /// Get current user profile
  Future<UserProfile?> getCurrentUserProfile() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return null;

    return await getUserProfile(currentUser.uid);
  }

  /// Search users by name
  Future<List<UserProfile>> searchUsers(String query) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('displayName', isGreaterThanOrEqualTo: query)
          .where('displayName', isLessThan: query + '\uf8ff')
          .limit(20)
          .get();

      return snapshot.docs
          .map((doc) => UserProfile.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error searching users: $e');
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
      print('Error updating user profile: $e');
      return false;
    }
  }

  /// Get user's display name
  Future<String> getUserDisplayName(String userId) async {
    try {
      final profile = await getUserProfile(userId);
      return profile?.displayName ?? 'Unknown User';
    } catch (e) {
      print('Error getting user display name: $e');
      return 'Unknown User';
    }
  }

  /// Get user's avatar URL
  Future<String?> getUserAvatarUrl(String userId) async {
    try {
      final profile = await getUserProfile(userId);
      return profile?.avatarUrl;
    } catch (e) {
      print('Error getting user avatar URL: $e');
      return null;
    }
  }

  /// Check if user exists
  Future<bool> userExists(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      return doc.exists;
    } catch (e) {
      print('Error checking if user exists: $e');
      return false;
    }
  }
}

/// User profile model
class UserProfile {
  final String id;
  final String displayName;
  final String? email;
  final String? avatarUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? preferences;

  UserProfile({
    required this.id,
    required this.displayName,
    this.email,
    this.avatarUrl,
    required this.createdAt,
    required this.updatedAt,
    this.preferences,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map, String id) {
    return UserProfile(
      id: id,
      displayName: map['displayName'] ?? 'Unknown User',
      email: map['email'],
      avatarUrl: map['avatarUrl'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      preferences: map['preferences'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'displayName': displayName,
      'email': email,
      'avatarUrl': avatarUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'preferences': preferences,
    };
  }

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
  }) {
    return UserProfile(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      preferences: preferences ?? this.preferences,
    );
  }

  @override
  String toString() {
    return 'UserProfile(id: $id, displayName: $displayName, email: $email, avatarUrl: $avatarUrl)';
  }
}
