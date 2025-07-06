import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:naijasingles/models/user_model.dart';
import 'package:naijasingles/services/paginated_user_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Cached user service that provides intelligent caching for user data
/// Reduces Firestore reads and improves app performance
class CachedUserService {
  static const Duration CACHE_DURATION = Duration(minutes: 15);
  static const Duration PROFILE_CACHE_DURATION = Duration(hours: 1);
  static const int MAX_CACHE_SIZE = 100; // Maximum users to cache
  
  // In-memory cache
  static final Map<String, List<UserModel>> _userListCache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};
  static final Map<String, UserModel> _profileCache = {};
  static final Map<String, DateTime> _profileTimestamps = {};
  
  // Persistent cache keys
  static const String _USER_LIST_CACHE_KEY = 'cached_user_list';
  static const String _USER_LIST_TIMESTAMP_KEY = 'user_list_timestamp';
  static const String _PROFILE_CACHE_PREFIX = 'cached_profile_';
  static const String _PROFILE_TIMESTAMP_PREFIX = 'profile_timestamp_';
  
  final PaginatedUserService _paginatedUserService = PaginatedUserService();
  
  /// Get cached users or fetch from Firestore if cache is invalid
  Future<PaginatedResult<UserModel>> getCachedUsers({
    required UserModel currentUser,
    bool forceRefresh = false,
  }) async {
    try {
      final cacheKey = _generateCacheKey(currentUser);
      
      debugPrint('🗄️ Checking cache for key: $cacheKey');
      
      // Check if we should use cache
      if (!forceRefresh && await _isCacheValid(cacheKey)) {
        debugPrint('✅ Using cached user data');
        final cachedUsers = await _getCachedUserList(cacheKey);
        
        if (cachedUsers.isNotEmpty) {
          return PaginatedResult<UserModel>(
            items: cachedUsers,
            lastDocument: null, // Cache doesn't store document snapshots
            hasMore: false, // Cached data is complete for the session
            totalFetched: cachedUsers.length,
          );
        }
      }
      
      debugPrint('🔄 Cache miss or invalid - fetching fresh data');
      
      // Fetch fresh data from Firestore
      final result = await _paginatedUserService.getUsers(
        currentUser: currentUser,
        pageSize: 50, // Fetch more for caching
      );
      
      if (result.isSuccess && result.items.isNotEmpty) {
        // Cache the results
        await _cacheUserList(cacheKey, result.items);
        debugPrint('💾 Cached ${result.items.length} users');
      }
      
      return result;
      
    } catch (e) {
      debugPrint('❌ Error in getCachedUsers: $e');
      
      // Try to return stale cache as fallback
      final cacheKey = _generateCacheKey(currentUser);
      final staleCache = await _getCachedUserList(cacheKey);
      
      if (staleCache.isNotEmpty) {
        debugPrint('⚠️ Returning stale cache due to error');
        return PaginatedResult<UserModel>(
          items: staleCache,
          lastDocument: null,
          hasMore: false,
          totalFetched: staleCache.length,
        );
      }
      
      return PaginatedResult<UserModel>(
        items: [],
        lastDocument: null,
        hasMore: false,
        totalFetched: 0,
        error: e.toString(),
      );
    }
  }
  
  /// Get more users with pagination (bypasses cache for fresh data)
  Future<PaginatedResult<UserModel>> getMoreUsers({
    required UserModel currentUser,
    required PaginatedResult<UserModel> previousResult,
  }) async {
    debugPrint('📄 Loading more users (bypassing cache)');
    
    return await _paginatedUserService.getUsers(
      currentUser: currentUser,
      lastDocument: previousResult.lastDocument,
    );
  }
  
  /// Cache individual user profile
  Future<void> cacheUserProfile(UserModel user) async {
    try {
      if (user.id == null) return;
      
      // In-memory cache
      _profileCache[user.id!] = user;
      _profileTimestamps[user.id!] = DateTime.now();
      
      // Persistent cache
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        '$_PROFILE_CACHE_PREFIX${user.id}',
        jsonEncode(user.toMap()),
      );
      await prefs.setInt(
        '$_PROFILE_TIMESTAMP_PREFIX${user.id}',
        DateTime.now().millisecondsSinceEpoch,
      );
      
      debugPrint('💾 Cached profile for user: ${user.name}');
      
    } catch (e) {
      debugPrint('❌ Error caching user profile: $e');
    }
  }
  
  /// Get cached user profile
  Future<UserModel?> getCachedUserProfile(String userId) async {
    try {
      // Check in-memory cache first
      if (_profileCache.containsKey(userId) && 
          _isProfileCacheValid(userId)) {
        debugPrint('✅ Using in-memory cached profile for: $userId');
        return _profileCache[userId];
      }
      
      // Check persistent cache
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString('$_PROFILE_CACHE_PREFIX$userId');
      final timestamp = prefs.getInt('$_PROFILE_TIMESTAMP_PREFIX$userId');
      
      if (cachedData != null && timestamp != null) {
        final cacheAge = DateTime.now().millisecondsSinceEpoch - timestamp;
        
        if (cacheAge < PROFILE_CACHE_DURATION.inMilliseconds) {
          final userData = jsonDecode(cachedData) as Map<String, dynamic>;
          final user = UserModel.fromMap(userData, userId);
          
          // Update in-memory cache
          _profileCache[userId] = user;
          _profileTimestamps[userId] = DateTime.fromMillisecondsSinceEpoch(timestamp);
          
          debugPrint('✅ Using persistent cached profile for: $userId');
          return user;
        }
      }
      
      debugPrint('❌ No valid cached profile for: $userId');
      return null;
      
    } catch (e) {
      debugPrint('❌ Error getting cached user profile: $e');
      return null;
    }
  }
  
  /// Clear all caches
  Future<void> clearCache() async {
    try {
      // Clear in-memory caches
      _userListCache.clear();
      _cacheTimestamps.clear();
      _profileCache.clear();
      _profileTimestamps.clear();
      
      // Clear persistent cache
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      
      for (final key in keys) {
        if (key.startsWith(_USER_LIST_CACHE_KEY) ||
            key.startsWith(_PROFILE_CACHE_PREFIX) ||
            key.startsWith(_PROFILE_TIMESTAMP_PREFIX) ||
            key == _USER_LIST_TIMESTAMP_KEY) {
          await prefs.remove(key);
        }
      }
      
      debugPrint('🗑️ All caches cleared');
      
    } catch (e) {
      debugPrint('❌ Error clearing cache: $e');
    }
  }
  
  /// Clear expired cache entries
  Future<void> clearExpiredCache() async {
    try {
      final now = DateTime.now();
      
      // Clear expired in-memory user list cache
      final expiredKeys = <String>[];
      _cacheTimestamps.forEach((key, timestamp) {
        if (now.difference(timestamp) > CACHE_DURATION) {
          expiredKeys.add(key);
        }
      });
      
      for (final key in expiredKeys) {
        _userListCache.remove(key);
        _cacheTimestamps.remove(key);
      }
      
      // Clear expired profile cache
      final expiredProfileKeys = <String>[];
      _profileTimestamps.forEach((key, timestamp) {
        if (now.difference(timestamp) > PROFILE_CACHE_DURATION) {
          expiredProfileKeys.add(key);
        }
      });
      
      for (final key in expiredProfileKeys) {
        _profileCache.remove(key);
        _profileTimestamps.remove(key);
      }
      
      debugPrint('🧹 Cleared ${expiredKeys.length} expired user list caches and ${expiredProfileKeys.length} expired profile caches');
      
    } catch (e) {
      debugPrint('❌ Error clearing expired cache: $e');
    }
  }
  
  /// Generate cache key based on user preferences
  String _generateCacheKey(UserModel currentUser) {
    final keyComponents = [
      currentUser.id ?? 'unknown',
      currentUser.showGender ?? 'everyone',
      '${currentUser.ageRangeMin ?? 18}-${currentUser.ageRangeMax ?? 100}',
      '${currentUser.distanceRange ?? 100}km',
    ];
    
    return keyComponents.join('_');
  }
  
  /// Check if cache is valid (not expired)
  Future<bool> _isCacheValid(String cacheKey) async {
    try {
      // Check in-memory cache first
      if (_cacheTimestamps.containsKey(cacheKey)) {
        final cacheAge = DateTime.now().difference(_cacheTimestamps[cacheKey]!);
        if (cacheAge < CACHE_DURATION) {
          return true;
        }
      }
      
      // Check persistent cache
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt('${_USER_LIST_TIMESTAMP_KEY}_$cacheKey');
      
      if (timestamp != null) {
        final cacheAge = DateTime.now().millisecondsSinceEpoch - timestamp;
        return cacheAge < CACHE_DURATION.inMilliseconds;
      }
      
      return false;
      
    } catch (e) {
      debugPrint('❌ Error checking cache validity: $e');
      return false;
    }
  }
  
  /// Check if profile cache is valid
  bool _isProfileCacheValid(String userId) {
    if (!_profileTimestamps.containsKey(userId)) return false;
    
    final cacheAge = DateTime.now().difference(_profileTimestamps[userId]!);
    return cacheAge < PROFILE_CACHE_DURATION;
  }
  
  /// Get cached user list
  Future<List<UserModel>> _getCachedUserList(String cacheKey) async {
    try {
      // Check in-memory cache first
      if (_userListCache.containsKey(cacheKey)) {
        return _userListCache[cacheKey]!;
      }
      
      // Check persistent cache
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString('${_USER_LIST_CACHE_KEY}_$cacheKey');
      
      if (cachedData != null) {
        final List<dynamic> userListData = jsonDecode(cachedData);
        final users = userListData
            .map((userData) => UserModel.fromMap(
                userData as Map<String, dynamic>, 
                userData['id'] ?? ''))
            .toList();
        
        // Update in-memory cache
        _userListCache[cacheKey] = users;
        
        return users;
      }
      
      return [];
      
    } catch (e) {
      debugPrint('❌ Error getting cached user list: $e');
      return [];
    }
  }
  
  /// Cache user list
  Future<void> _cacheUserList(String cacheKey, List<UserModel> users) async {
    try {
      // Limit cache size
      final usersToCache = users.take(MAX_CACHE_SIZE).toList();
      
      // In-memory cache
      _userListCache[cacheKey] = usersToCache;
      _cacheTimestamps[cacheKey] = DateTime.now();
      
      // Persistent cache
      final prefs = await SharedPreferences.getInstance();
      final userListData = usersToCache.map((user) => user.toMap()).toList();
      
      await prefs.setString(
        '${_USER_LIST_CACHE_KEY}_$cacheKey',
        jsonEncode(userListData),
      );
      await prefs.setInt(
        '${_USER_LIST_TIMESTAMP_KEY}_$cacheKey',
        DateTime.now().millisecondsSinceEpoch,
      );
      
    } catch (e) {
      debugPrint('❌ Error caching user list: $e');
    }
  }
  
  /// Get cache statistics for debugging
  Map<String, dynamic> getCacheStats() {
    return {
      'userListCacheSize': _userListCache.length,
      'profileCacheSize': _profileCache.length,
      'oldestUserListCache': _cacheTimestamps.values.isNotEmpty 
          ? _cacheTimestamps.values.reduce((a, b) => a.isBefore(b) ? a : b).toString()
          : 'None',
      'oldestProfileCache': _profileTimestamps.values.isNotEmpty
          ? _profileTimestamps.values.reduce((a, b) => a.isBefore(b) ? a : b).toString()
          : 'None',
    };
  }
}
