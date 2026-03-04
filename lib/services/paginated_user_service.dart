import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/user_model.dart';

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
    String? intentFilter, // Add intent filter parameter
  }) async {
    try {
      debugPrint('🔍 Fetching users - Page size: $pageSize');
      if (intentFilter != null) {
        debugPrint('🎯 Filtering by intent: $intentFilter');
      }

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
          debugPrint(
            '👤 Processing user: ${doc.id} - ${userData['name'] ?? 'No name'}',
          );

          // Skip excluded users
          if (excludedUserIds.contains(doc.id)) {
            debugPrint('⏭️ Skipping excluded user: ${doc.id}');
            continue;
          }

          // Create UserModel
          final user = UserModel.fromMap(userData, doc.id);
          debugPrint('✅ Created UserModel for: ${user.name}');

          // Apply intent filter if specified
          if (intentFilter != null && intentFilter.isNotEmpty) {
            final userIntent = user.lookingFor ?? 'Dating';
            if (userIntent != intentFilter) {
              debugPrint(
                '🎯 Skipping user ${user.name} - intent mismatch (user: $userIntent, filter: $intentFilter)',
              );
              continue;
            }
          }

          // Apply distance filter if location is available
          // Temporarily disable distance filter for testing
          users.add(user);
          debugPrint(
            '✅ Added user to results: ${user.name} (intent: ${user.lookingFor})',
          );
        } catch (e) {
          debugPrint('❌ Error processing user ${doc.id}: $e');
          continue;
        }
      }

      // Determine if there are more pages
      final hasMore = querySnapshot.docs.length == pageSize;
      final lastDoc =
          querySnapshot.docs.isNotEmpty ? querySnapshot.docs.last : null;

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

    debugPrint('🔍 Building query for user: ${currentUser.name}');
    debugPrint('   - showGender: ${currentUser.showGender}');
    debugPrint('   - ageRangeMin: ${currentUser.ageRangeMin}');
    debugPrint('   - ageRangeMax: ${currentUser.ageRangeMax}');

    // Temporarily disable gender filtering to test
    debugPrint('🔍 TEMPORARILY DISABLING GENDER FILTERING FOR DEBUGGING');
    debugPrint('   - Current user showGender: ${currentUser.showGender}');
    debugPrint('   - Current user gender: ${currentUser.gender}');

    // Filter by age range
    if (currentUser.ageRangeMin != null && currentUser.ageRangeMax != null) {
      query = query
          .where('age', isGreaterThanOrEqualTo: currentUser.ageRangeMin)
          .where('age', isLessThanOrEqualTo: currentUser.ageRangeMax);

      debugPrint(
        '🔍 Filtering by age: ${currentUser.ageRangeMin}-${currentUser.ageRangeMax}',
      );
    } else {
      debugPrint('🔍 No age filter applied');
    }

    // Exclude current user
    // Note: We'll handle this in post-processing to avoid complex queries

    // Order by a field that's more likely to exist
    // Try different ordering strategies
    try {
      // First try ordering by age (which should exist)
      query = query.orderBy('age', descending: false);
      debugPrint('🔍 Ordering by age');
    } catch (e) {
      debugPrint('⚠️ Age ordering failed: $e');
      // If that fails, don't order at all for now
    }

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

      debugPrint('👀 Found ${checkedUsers.docs.length} checked users');
      for (final doc in checkedUsers.docs) {
        excludedIds.add(doc.id);
        debugPrint('   - Checked: ${doc.id}');
      }

      // Get blocked users
      final blockedUsers = await _usersCollection
          .doc(currentUserId)
          .collection('blockedlist')
          .get();

      debugPrint('🚫 Found ${blockedUsers.docs.length} blocked users');
      for (final doc in blockedUsers.docs) {
        excludedIds.add(doc.id);
        debugPrint('   - Blocked: ${doc.id}');
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

  /// Refresh user data (clear cache and fetch fresh data)
  Future<PaginatedResult<UserModel>> refreshUsers(UserModel currentUser) async {
    debugPrint('🔄 Refreshing user data');
    return getUsers(currentUser: currentUser);
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
  const PaginatedResult({
    required this.items,
    required this.lastDocument,
    required this.hasMore,
    required this.totalFetched,
    this.error,
  });
  final List<T> items;
  final DocumentSnapshot? lastDocument;
  final bool hasMore;
  final int totalFetched;
  final String? error;

  bool get isSuccess => error == null;
  bool get isEmpty => items.isEmpty;
  int get length => items.length;

  @override
  String toString() =>
      'PaginatedResult(items: ${items.length}, hasMore: $hasMore, totalFetched: $totalFetched, error: $error)';
}

/// Extension methods for easier pagination handling
extension PaginatedResultExtension<T> on PaginatedResult<T> {
  /// Combine with another paginated result (for loading more pages)
  PaginatedResult<T> combineWith(PaginatedResult<T> other) =>
      PaginatedResult<T>(
        items: [...items, ...other.items],
        lastDocument: other.lastDocument,
        hasMore: other.hasMore,
        totalFetched: totalFetched + other.totalFetched,
        error: other.error,
      );
}
