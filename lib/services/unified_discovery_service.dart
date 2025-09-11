import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:naijasingles/models/user_model.dart';
import 'package:naijasingles/common/utils/distance.dart' as distance;
import 'package:naijasingles/services/smart_match_service.dart';
import 'package:naijasingles/services/mode_specific_filtering_service.dart';

/// Unified discovery service that consolidates all user discovery logic
/// This replaces the multiple discovery services with a single, optimized service
class UnifiedDiscoveryService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Collection references
  static CollectionReference get _usersCollection => _firestore.collection('users');
  
  /// Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;
  
  /// Get users for discovery with comprehensive filtering
  static Future<List<UserModel>> getUsersForDiscovery(
    UserModel currentUser, {
    String? intentFilter,
    bool forceRefresh = false,
  }) async {
    try {
      debugPrint('🔍 UnifiedDiscoveryService: Getting users for ${currentUser.name}');
      debugPrint('   - Intent filter: $intentFilter');
      debugPrint('   - Gender preference: ${currentUser.showGender}');
      debugPrint('   - Age range: ${currentUser.ageRangeMin}-${currentUser.ageRangeMax}');
      debugPrint('   - Max distance: ${currentUser.maxDistance}km');
      
      // Get already checked users
      final checkedUserIds = await _getCheckedUserIds(currentUser.id!);
      debugPrint('   - Already checked: ${checkedUserIds.length} users');
      
      // Build optimized query with mode-specific filtering
      Query query = _buildOptimizedQuery(currentUser, intentFilter);
      query = ModeSpecificFilteringService.applyModeSpecificFilters(
        query, 
        currentUser, 
        intentFilter ?? 'Dating'
      );
      
      // Execute query
      final querySnapshot = await query.get();
      debugPrint('   - Query returned: ${querySnapshot.docs.length} documents');
      
      // Process results
      List<UserModel> userList = [];
      
      for (var doc in querySnapshot.docs) {
        try {
          final userId = doc.id;
          
          // Skip already checked users and self
          if (checkedUserIds.contains(userId) || userId == currentUser.id) {
            continue;
          }
          
          // Create UserModel from document
          final user = UserModel.fromDocument(doc);
          
          // Apply mode-specific validation
          if (!ModeSpecificFilteringService.validateModeMatch(user, intentFilter ?? 'Dating')) {
            debugPrint('⚠️ User $userId does not match $intentFilter criteria');
            continue;
          }
          
          // Apply additional filters
          if (!_passesAdditionalFilters(user, currentUser)) {
            continue;
          }
          
          // Calculate distance if both users have coordinates
          if (user.latitude != null && user.longitude != null &&
              currentUser.latitude != null && currentUser.longitude != null) {
            final calculatedDistance = distance.calculateDistance(
              currentUser.latitude!,
              currentUser.longitude!,
              user.latitude!,
              user.longitude!,
            );
            user.distanceBW = calculatedDistance.round();
            
            // Apply distance filter
            if (calculatedDistance > (currentUser.maxDistance ?? 100)) {
              continue;
            }
          }
          
          debugPrint('✅ Adding user: ${user.name} (${user.distanceBW ?? 'unknown'}km away)');
          userList.add(user);
          
        } catch (e) {
          debugPrint('⚠️ Error processing user ${doc.id}: $e');
          continue;
        }
      }
      
      // Apply smart matching with mode-specific compatibility
      if (userList.isNotEmpty) {
        userList = await _applySmartMatching(currentUser, userList, intentFilter);
      }
      
      debugPrint('🎯 Final result: ${userList.length} discoverable users');
      return userList;
      
    } catch (e) {
      debugPrint('❌ Error in UnifiedDiscoveryService: $e');
      return [];
    }
  }
  
  /// Build optimized Firestore query
  static Query _buildOptimizedQuery(UserModel currentUser, String? intentFilter) {
    Query query = _usersCollection;
    
    // TEMPORARILY DISABLED: Gender filtering (field names might be wrong)
    debugPrint('🔍 TEMPORARILY DISABLING GENDER FILTERING - field names might be wrong');
    debugPrint('   - Current user showGender: ${currentUser.showGender}');
    debugPrint('   - Current user gender: ${currentUser.userGender}');
    debugPrint('   - Database uses "gender" field, not "userGender"');
    
    // try {
    //   if (currentUser.showGender != null && currentUser.showGender != 'everyone') {
    //     // User wants to see specific gender - handle both formats
    //     final genderVariants = _getGenderVariants(currentUser.showGender!);
    //     query = query.where('userGender', whereIn: genderVariants);
    //     debugPrint('🔍 Filtering by gender variants: $genderVariants');
    //     
    //     // Also ensure those users want to see current user's gender
    //     if (currentUser.userGender != null) {
    //       final currentUserGenderVariants = _getGenderVariants(currentUser.userGender!);
    //       query = query.where('showGender', whereIn: ['everyone', ...currentUserGenderVariants]);
    //       debugPrint('🔍 Ensuring mutual gender preference: $currentUserGenderVariants');
    //     }
    //   } else {
    //     // User wants to see everyone, but still filter by who wants to see them
    //     if (currentUser.userGender != null) {
    //       final currentUserGenderVariants = _getGenderVariants(currentUser.userGender!);
    //       query = query.where('showGender', whereIn: ['everyone', ...currentUserGenderVariants]);
    //       debugPrint('🔍 Filtering by who wants to see: $currentUserGenderVariants');
    //     } else {
    //       debugPrint('🔍 No gender filter applied (showing everyone)');
    //     }
    //   }
    // } catch (e) {
    //   debugPrint('⚠️ Gender filtering failed, continuing without it: $e');
    // }
    
    // Filter by age range - CRITICAL FOR DISCOVERY
    if (currentUser.ageRangeMin != null && currentUser.ageRangeMax != null) {
      query = query
          .where('age', isGreaterThanOrEqualTo: currentUser.ageRangeMin!)
          .where('age', isLessThanOrEqualTo: currentUser.ageRangeMax!);
      debugPrint('🔍 Filtering by age: ${currentUser.ageRangeMin}-${currentUser.ageRangeMax}');
    }
    
    // Filter by intent if specified
    if (intentFilter != null && intentFilter.isNotEmpty) {
      query = query.where('lookingFor', isEqualTo: intentFilter);
      debugPrint('🔍 Filtering by intent: $intentFilter');
    }
    
    // TEMPORARILY DISABLED: Filter out blocked users (field might not exist)
    debugPrint('🔍 TEMPORARILY DISABLING isBlocked FILTER - field might not exist');
    // query = query.where('isBlocked', isEqualTo: false);
    
    // TEMPORARILY DISABLED: Profile completeness filter (most users don't have this field)
    debugPrint('🔍 TEMPORARILY DISABLING PROFILE COMPLETENESS FILTER - most users missing this field');
    // try {
    //   query = query.where('isProfileComplete', isEqualTo: true);
    //   debugPrint('🔍 Filtering by profile completeness: true');
    // } catch (e) {
    //   debugPrint('⚠️ Profile completeness filter failed, continuing without it: $e');
    // }
    
    // TEMPORARILY DISABLED: Order by last active (field doesn't exist in most documents)
    debugPrint('🔍 TEMPORARILY DISABLING lastActive ORDERING - field missing in most documents');
    // query = query.orderBy('lastActive', descending: true);
    
    return query;
  }
  
  /// Get list of already checked user IDs
  static Future<List<String>> _getCheckedUserIds(String currentUserId) async {
    try {
      final snapshot = await _firestore
          .collection('users/$currentUserId/CheckedUser')
          .get();
      
      List<String> checkedIds = [];
      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data['LikedUser'] != null) {
          checkedIds.add(data['LikedUser']);
        }
        if (data['DislikedUser'] != null) {
          checkedIds.add(data['DislikedUser']);
        }
      }
      
      return checkedIds;
    } catch (e) {
      debugPrint('Error getting checked users: $e');
      return [];
    }
  }
  
  /// Apply additional filters that can't be done in Firestore query
  static bool _passesAdditionalFilters(UserModel user, UserModel currentUser) {
    // Skip blocked users
    if (user.isBlocked == true) {
      return false;
    }
    
    // Skip bots
    if (user.isBot == true) {
      return false;
    }
    
    // Skip users without complete profiles
    if (user.name == null || user.name!.isEmpty) {
      return false;
    }
    
    // Skip users without photos
    if (user.imageUrl == null || user.imageUrl!.isEmpty) {
      return false;
    }
    
    return true;
  }
  
  /// Record a like action
  static Future<String?> recordLike(String fromUserId, String toUserId) async {
    try {
      debugPrint('💖 Recording like: $fromUserId -> $toUserId');
      
      // Save the like
      final likeDocId = '${fromUserId}_likes_${toUserId}';
      await _firestore.collection('likes').doc(likeDocId).set({
        'from': fromUserId,
        'to': toUserId,
        'timestamp': FieldValue.serverTimestamp(),
      });
      
      // Check for mutual like
      final reverseLikeDocId = '${toUserId}_likes_${fromUserId}';
      final reverseLike = await _firestore.collection('likes').doc(reverseLikeDocId).get();
      
      if (reverseLike.exists) {
        debugPrint('🎉 Mutual like detected! Creating match...');
        
        // Create match
        final matchId = await _createMatch(fromUserId, toUserId);
        return matchId;
      } else {
        debugPrint('💔 No mutual like yet');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error recording like: $e');
      return null;
    }
  }
  
  /// Create a match between two users
  static Future<String?> _createMatch(String userAId, String userBId) async {
    try {
      // Check if match already exists
      final existingMatch = await _getExistingMatch(userAId, userBId);
      if (existingMatch != null) {
        debugPrint('Match already exists: $existingMatch');
        return existingMatch;
      }
      
      // Create new match
      final matchRef = await _firestore.collection('matches').add({
        'users': [userAId, userBId],
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessageAt': FieldValue.serverTimestamp(),
        'isActive': true,
      });
      
      // Create chat thread
      await _firestore.collection('chatThreads').doc(matchRef.id).set({
        'userIds': [userAId, userBId],
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessageAt': FieldValue.serverTimestamp(),
        'isActive': true,
      });
      
      debugPrint('✅ Match created: ${matchRef.id}');
      return matchRef.id;
    } catch (e) {
      debugPrint('❌ Error creating match: $e');
      return null;
    }
  }
  
  /// Check if match already exists
  static Future<String?> _getExistingMatch(String userAId, String userBId) async {
    try {
      final querySnapshot = await _firestore
          .collection('matches')
          .where('users', arrayContainsAny: [userAId])
          .get();
      
      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        final users = List<String>.from(data['users'] ?? []);
        
        if (users.contains(userAId) && users.contains(userBId)) {
          return doc.id;
        }
      }
      
      return null;
    } catch (e) {
      debugPrint('Error checking existing match: $e');
      return null;
    }
  }

  /// Get gender variants for better matching
  static List<String> _getGenderVariants(String gender) {
    switch (gender.toLowerCase()) {
      case 'men':
      case 'male':
        return ['men', 'male', 'Male', 'Men'];
      case 'women':
      case 'female':
        return ['women', 'female', 'Female', 'Women'];
      case 'everyone':
        return ['everyone', 'men', 'women', 'male', 'female'];
      default:
        return [gender];
    }
  }

  /// Apply smart matching with mode-specific compatibility
  static Future<List<UserModel>> _applySmartMatching(
    UserModel currentUser,
    List<UserModel> userList,
    String? intentFilter,
  ) async {
    try {
      debugPrint('🧠 Applying smart matching for ${userList.length} users');
      
      final smartMatchService = SmartMatchService();
      final mode = intentFilter ?? 'Dating';
      
      // Use SmartMatchService to get optimized ordering
      final result = await smartMatchService.getOptimizedUserList(
        currentUser: currentUser,
        mode: mode,
        pageSize: userList.length,
        forceRefresh: false,
      );
      
      if (result.isSuccess && result.users.isNotEmpty) {
        debugPrint('✅ Smart matching applied: ${result.users.length} users');
        return result.users;
      } else {
        debugPrint('⚠️ Smart matching failed, returning original list');
        return userList;
      }
    } catch (e) {
      debugPrint('❌ Error in smart matching: $e');
      return userList;
    }
  }
}
