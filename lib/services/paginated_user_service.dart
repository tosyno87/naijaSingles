import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:naijasingles/models/user_model.dart';
import 'package:naijasingles/common/utils/distance.dart' as distance;

/// Paginated user service for efficient user loading and discovery
class PaginatedUserService {
  static const int PAGE_SIZE = 20;
  static const int MAX_DISTANCE_KM = 100;
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;
  
  // Collection references
  CollectionReference get _usersCollection => _firestore.collection('users');
  
  /// Get paginated users for discovery/swiping
  /// Returns a PaginatedResult containing users and pagination info
  Future<PaginatedResult<UserModel>> getUsers({
    required UserModel currentUser,
    DocumentSnapshot? lastDocument,
    int pageSize = PAGE_SIZE,
  }) async {
    try {
      debugPrint('🔍 Fetching users - Page size: $pageSize');
      
      // Build the base query
      Query query = _buildUserQuery(currentUser);
      
      // Add pagination
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
        debugPrint('📄 Starting after document: ${lastDocument.id}');
      }
      
      // Execute query with limit
      final querySnapshot = await query.limit(pageSize).get();
      
      debugPrint('📊 Query returned ${querySnapshot.docs.length} users');
      
      // Convert to UserModel list
      final users = <UserModel>[];
      final excludedUserIds = await _getExcludedUserIds(currentUser.id!);
      
      for (final doc in querySnapshot.docs) {
        try {
          final userData = doc.data() as Map<String, dynamic>;
          
          // Skip excluded users
          if (excludedUserIds.contains(doc.id)) {
            debugPrint('⏭️ Skipping excluded user: ${doc.id}');
            continue;
          }
          
          // Create UserModel
          final user = UserModel.fromMap(userData, doc.id);
          
          // Apply distance filter if location is available
          if (await _isWithinDistance(currentUser, user)) {
            users.add(user);
          } else {
            debugPrint('📍 User ${user.name} is too far away');
          }
        } catch (e) {
          debugPrint('❌ Error processing user ${doc.id}: $e');
          continue;
        }
      }
      
      // Determine if there are more pages
      final hasMore = querySnapshot.docs.length == pageSize;
      final lastDoc = querySnapshot.docs.isNotEmpty ? querySnapshot.docs.last : null;
      
      debugPrint('✅ Returning ${users.length} users, hasMore: $hasMore');
      
      return PaginatedResult<UserModel>(
        items: users,
        lastDocument: lastDoc,
        hasMore: hasMore,
        totalFetched: users.length,
      );
      
    } catch (e) {
      debugPrint('❌ Error fetching paginated users: $e');
      return PaginatedResult<UserModel>(
        items: [],
        lastDocument: null,
        hasMore: false,
        totalFetched: 0,
        error: e.toString(),
      );
    }
  }
  
  /// Build optimized query for user discovery
  Query _buildUserQuery(UserModel currentUser) {
    Query query = _usersCollection;
    
    // Filter by gender preference
    if (currentUser.showGender != null && currentUser.showGender != 'everyone') {
      query = query.where('gender', isEqualTo: currentUser.showGender);
      debugPrint('🔍 Filtering by gender: ${currentUser.showGender}');
    }
    
    // Filter by age range
    if (currentUser.ageRangeMin != null && currentUser.ageRangeMax != null) {
      final minBirthYear = DateTime.now().year - currentUser.ageRangeMax!;
      final maxBirthYear = DateTime.now().year - currentUser.ageRangeMin!;
      
      query = query
          .where('age', isGreaterThanOrEqualTo: currentUser.ageRangeMin)
          .where('age', isLessThanOrEqualTo: currentUser.ageRangeMax);
      
      debugPrint('🔍 Filtering by age: ${currentUser.ageRangeMin}-${currentUser.ageRangeMax}');
    }
    
    // Exclude current user
    // Note: We'll handle this in post-processing to avoid complex queries
    
    // Order by last active (most recent first)
    query = query.orderBy('lastSeen', descending: true);
    
    return query;
  }
  
  /// Get list of user IDs to exclude (already swiped, blocked, etc.)
  Future<Set<String>> _getExcludedUserIds(String currentUserId) async {
    final excludedIds = <String>{};
    
    try {
      // Add current user ID
      excludedIds.add(currentUserId);
      
      // Get already checked users (swiped left or right)
      final checkedUsers = await _usersCollection
          .doc(currentUserId)
          .collection('CheckedUser')
          .get();
      
      for (final doc in checkedUsers.docs) {
        excludedIds.add(doc.id);
      }
      
      // Get blocked users
      final blockedUsers = await _usersCollection
          .doc(currentUserId)
          .collection('blockedlist')
          .get();
      
      for (final doc in blockedUsers.docs) {
        excludedIds.add(doc.id);
      }
      
      // Get users who blocked current user (if possible to query efficiently)
      // Note: This might require a separate collection for performance
      
      debugPrint('🚫 Excluding ${excludedIds.length} users');
      return excludedIds;
      
    } catch (e) {
      debugPrint('❌ Error getting excluded user IDs: $e');
      return {currentUserId}; // At minimum, exclude current user
    }
  }
  
  /// Check if user is within distance range
  Future<bool> _isWithinDistance(UserModel currentUser, UserModel targetUser) async {
    try {
      // Skip distance check if location data is missing
      if (currentUser.coordinates == null || 
          targetUser.coordinates == null ||
          currentUser.coordinates!.isEmpty ||
          targetUser.coordinates!.isEmpty) {
        debugPrint('📍 Skipping distance check - missing location data');
        return true; // Include user if location data is unavailable
      }
      
      final currentLat = currentUser.coordinates!['latitude'] as double?;
      final currentLng = currentUser.coordinates!['longitude'] as double?;
      final targetLat = targetUser.coordinates!['latitude'] as double?;
      final targetLng = targetUser.coordinates!['longitude'] as double?;
      
      if (currentLat == null || currentLng == null || 
          targetLat == null || targetLng == null) {
        return true; // Include if coordinates are invalid
      }
      
      // Calculate distance
      final distanceKm = distance.calculateDistance(
        currentLat, currentLng, targetLat, targetLng
      );
      
      // Use user's distance preference or default
      final maxDistance = currentUser.distanceRange ?? MAX_DISTANCE_KM;
      
      debugPrint('📍 Distance to ${targetUser.name}: ${distanceKm.toStringAsFixed(1)}km (max: ${maxDistance}km)');
      
      return distanceKm <= maxDistance;
      
    } catch (e) {
      debugPrint('❌ Error calculating distance: $e');
      return true; // Include user if distance calculation fails
    }
  }
  
  /// Refresh user data (clear cache and fetch fresh data)
  Future<PaginatedResult<UserModel>> refreshUsers(UserModel currentUser) async {
    debugPrint('🔄 Refreshing user data');
    return await getUsers(currentUser: currentUser);
  }
  
  /// Get total count of available users (for UI display)
  Future<int> getTotalUserCount(UserModel currentUser) async {
    try {
      final query = _buildUserQuery(currentUser);
      final snapshot = await query.get();
      
      // Subtract excluded users
      final excludedIds = await _getExcludedUserIds(currentUser.id!);
      final availableCount = snapshot.docs.length - excludedIds.length;
      
      return availableCount > 0 ? availableCount : 0;
      
    } catch (e) {
      debugPrint('❌ Error getting total user count: $e');
      return 0;
    }
  }
  
  /// Check if more users are available for loading
  Future<bool> hasMoreUsers({
    required UserModel currentUser,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      if (lastDocument == null) return true;
      
      final query = _buildUserQuery(currentUser)
          .startAfterDocument(lastDocument)
          .limit(1);
          
      final snapshot = await query.get();
      return snapshot.docs.isNotEmpty;
      
    } catch (e) {
      debugPrint('❌ Error checking for more users: $e');
      return false;
    }
  }
}

/// Result class for paginated data
class PaginatedResult<T> {
  final List<T> items;
  final DocumentSnapshot? lastDocument;
  final bool hasMore;
  final int totalFetched;
  final String? error;
  
  const PaginatedResult({
    required this.items,
    required this.lastDocument,
    required this.hasMore,
    required this.totalFetched,
    this.error,
  });
  
  bool get isSuccess => error == null;
  bool get isEmpty => items.isEmpty;
  int get length => items.length;
  
  @override
  String toString() {
    return 'PaginatedResult(items: ${items.length}, hasMore: $hasMore, totalFetched: $totalFetched, error: $error)';
  }
}

/// Extension methods for easier pagination handling
extension PaginatedResultExtension<T> on PaginatedResult<T> {
  /// Combine with another paginated result (for loading more pages)
  PaginatedResult<T> combineWith(PaginatedResult<T> other) {
    return PaginatedResult<T>(
      items: [...items, ...other.items],
      lastDocument: other.lastDocument,
      hasMore: other.hasMore,
      totalFetched: totalFetched + other.totalFetched,
      error: other.error,
    );
  }
}
