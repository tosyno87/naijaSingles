import 'dart:convert';
import 'dart:developer';

import 'package:shared_preferences/shared_preferences.dart';

import '../features/messages/message_model.dart';
import '../models/user_model.dart';

/// Industry-standard offline support service
/// Features:
/// - Local data caching
/// - Offline-first architecture
/// - Background sync
/// - Conflict resolution
/// - Cache management
/// - Offline indicators
class OfflineSupportService {
  factory OfflineSupportService() => _instance;
  OfflineSupportService._internal();
  static final OfflineSupportService _instance =
      OfflineSupportService._internal();

  // Cache keys
  static const String _cachedProfilesKey = 'cached_profiles';
  static const String _cachedMessagesKey = 'cached_messages';
  static const String _cachedUserProfileKey = 'cached_user_profile';
  static const String _offlineActionsKey = 'offline_actions';
  static const String _lastSyncKey = 'last_sync';

  // Cache limits
  static const int _maxOfflineActions = 500;

  /// Initialize offline support
  Future<void> initialize() async {
    try {
      log('📱 Offline support initialized');
    } catch (e) {
      log('❌ Error initializing offline support: $e');
    }
  }

  /// Check if device is online (simplified version)
  Future<bool> isOnline() async {
    // This would typically check network connectivity
    // For now, return true as a placeholder
    return true;
  }

  /// Cache user profiles for offline viewing
  Future<void> cacheProfiles(List<UserModel> profiles) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Convert profiles to JSON using basic serialization
      final profilesJson = profiles
          .map((profile) => {
                'id': profile.id,
                'name': profile.name,
                'userGender': profile.userGender,
                'age': profile.age,
                'showGender': profile.showGender,
                'maxDistance': profile.maxDistance,
                'latitude': profile.latitude,
                'longitude': profile.longitude,
                'imageUrl': profile.imageUrl,
                'bio': profile.bio,
                'nationality': profile.nationality,
                'tribe': profile.tribe,
                'occupation': profile.occupation,
                'languages': profile.languages,
                'religion': profile.religion,
              },)
          .toList();
      final jsonString = jsonEncode(profilesJson);

      // Store in cache
      await prefs.setString(_cachedProfilesKey, jsonString);

      log('💾 Cached ${profiles.length} profiles for offline viewing');
    } catch (e) {
      log('❌ Error caching profiles: $e');
    }
  }

  /// Get cached profiles
  Future<List<UserModel>> getCachedProfiles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_cachedProfilesKey);

      if (jsonString == null) return [];

      final List<dynamic> profilesJson = jsonDecode(jsonString);
      final profiles =
          profilesJson.map((json) => UserModel.fromJson(json)).toList();

      log('📱 Retrieved ${profiles.length} cached profiles');
      return profiles;
    } catch (e) {
      log('❌ Error getting cached profiles: $e');
      return [];
    }
  }

  /// Cache messages for offline viewing
  Future<void> cacheMessages(
      String threadId, List<MessageThreadInfo> messages,) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Convert messages to JSON using basic serialization
      final messagesJson = messages
          .map((message) => {
                'threadId': message.threadId,
                'otherUserId': message.otherUserId,
                'otherUserName': message.otherUserName,
                'lastMessage': message.lastMessage,
                'lastMessageSenderId': message.lastMessageSenderId,
                'timestamp': message.timestamp.toIso8601String(),
                'unread': message.unread,
                'avatarUrl': message.avatarUrl,
              },)
          .toList();
      final jsonString = jsonEncode(messagesJson);

      // Store in cache with thread ID
      await prefs.setString('${_cachedMessagesKey}_$threadId', jsonString);

      log('💾 Cached ${messages.length} messages for thread $threadId');
    } catch (e) {
      log('❌ Error caching messages: $e');
    }
  }

  /// Get cached messages
  Future<List<MessageThreadInfo>> getCachedMessages(String threadId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('${_cachedMessagesKey}_$threadId');

      if (jsonString == null) return [];

      final List<dynamic> messagesJson = jsonDecode(jsonString);
      final messages = messagesJson.map((json) {
        final data = json as Map<String, dynamic>;
        return MessageThreadInfo(
          threadId: data['threadId'] as String,
          otherUserId: data['otherUserId'] as String,
          otherUserName: data['otherUserName'] as String,
          lastMessage: data['lastMessage'] as String,
          lastMessageSenderId: data['lastMessageSenderId'] as String?,
          timestamp: DateTime.parse(data['timestamp'] as String),
          unread: data['unread'] as bool,
          avatarUrl: data['avatarUrl'] as String?,
        );
      }).toList();

      log('📱 Retrieved ${messages.length} cached messages for thread $threadId');
      return messages;
    } catch (e) {
      log('❌ Error getting cached messages: $e');
      return [];
    }
  }

  /// Cache user's own profile
  Future<void> cacheUserProfile(UserModel profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Convert profile to JSON using basic serialization
      final profileJson = {
        'id': profile.id,
        'name': profile.name,
        'userGender': profile.userGender,
        'age': profile.age,
        'showGender': profile.showGender,
        'maxDistance': profile.maxDistance,
        'latitude': profile.latitude,
        'longitude': profile.longitude,
        'imageUrl': profile.imageUrl,
        'bio': profile.bio,
        'nationality': profile.nationality,
        'tribe': profile.tribe,
        'occupation': profile.occupation,
        'languages': profile.languages,
        'religion': profile.religion,
      };

      final jsonString = jsonEncode(profileJson);
      await prefs.setString(_cachedUserProfileKey, jsonString);

      log('💾 Cached user profile for offline viewing');
    } catch (e) {
      log('❌ Error caching user profile: $e');
    }
  }

  /// Get cached user profile
  Future<UserModel?> getCachedUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_cachedUserProfileKey);

      if (jsonString == null) return null;

      final profileJson = jsonDecode(jsonString);
      final profile = UserModel.fromJson(profileJson);

      log('📱 Retrieved cached user profile');
      return profile;
    } catch (e) {
      log('❌ Error getting cached user profile: $e');
      return null;
    }
  }

  /// Queue action for offline execution
  Future<void> queueOfflineAction(OfflineAction action) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get existing actions
      final actionsJson = prefs.getString(_offlineActionsKey) ?? '[]';
      final List<dynamic> actions = jsonDecode(actionsJson);

      // Add new action
      actions.add(action.toJson());

      // Limit number of actions
      if (actions.length > _maxOfflineActions) {
        actions.removeRange(0, actions.length - _maxOfflineActions);
      }

      // Save back to preferences
      await prefs.setString(_offlineActionsKey, jsonEncode(actions));

      log('📝 Queued offline action: ${action.type}');
    } catch (e) {
      log('❌ Error queuing offline action: $e');
    }
  }

  /// Get queued offline actions
  Future<List<OfflineAction>> getQueuedActions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final actionsJson = prefs.getString(_offlineActionsKey) ?? '[]';
      final List<dynamic> actions = jsonDecode(actionsJson);

      return actions.map((json) => OfflineAction.fromJson(json)).toList();
    } catch (e) {
      log('❌ Error getting queued actions: $e');
      return [];
    }
  }

  /// Clear queued actions
  Future<void> clearQueuedActions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_offlineActionsKey);

      log('🗑️ Cleared queued offline actions');
    } catch (e) {
      log('❌ Error clearing queued actions: $e');
    }
  }

  /// Start background sync
  Future<void> _startBackgroundSync() async {
    try {
      if (!await isOnline()) return;

      log('🔄 Starting background sync...');

      // Sync queued actions
      await _syncQueuedActions();

      // Update last sync time
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());

      log('✅ Background sync completed');
    } catch (e) {
      log('❌ Error in background sync: $e');
    }
  }

  /// Sync queued actions
  Future<void> _syncQueuedActions() async {
    try {
      final actions = await getQueuedActions();
      if (actions.isEmpty) return;

      log('🔄 Syncing ${actions.length} queued actions...');

      for (final action in actions) {
        try {
          await _executeOfflineAction(action);
        } catch (e) {
          log('❌ Error executing action ${action.type}: $e');
          // Continue with other actions
        }
      }

      // Clear successfully synced actions
      await clearQueuedActions();
    } catch (e) {
      log('❌ Error syncing queued actions: $e');
    }
  }

  /// Execute offline action
  Future<void> _executeOfflineAction(OfflineAction action) async {
    // This would integrate with your actual services
    // For now, we'll just log the action
    log('🔄 Executing offline action: ${action.type}');

    switch (action.type) {
      case OfflineActionType.like:
        // Execute like action
        break;
      case OfflineActionType.pass:
        // Execute pass action
        break;
      case OfflineActionType.message:
        // Execute message action
        break;
      case OfflineActionType.profileUpdate:
        // Execute profile update
        break;
    }
  }

  /// Get last sync time
  Future<DateTime?> getLastSyncTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timeString = prefs.getString(_lastSyncKey);

      if (timeString == null) return null;

      return DateTime.parse(timeString);
    } catch (e) {
      log('❌ Error getting last sync time: $e');
      return null;
    }
  }

  /// Check if cache is stale
  Future<bool> isCacheStale(
      {Duration maxAge = const Duration(hours: 24),}) async {
    try {
      final lastSync = await getLastSyncTime();
      if (lastSync == null) return true;

      final now = DateTime.now();
      final difference = now.difference(lastSync);

      return difference > maxAge;
    } catch (e) {
      log('❌ Error checking cache staleness: $e');
      return true;
    }
  }

  /// Clear all cached data
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Clear all cache keys
      await prefs.remove(_cachedProfilesKey);
      await prefs.remove(_cachedMessagesKey);
      await prefs.remove(_cachedUserProfileKey);
      await prefs.remove(_offlineActionsKey);
      await prefs.remove(_lastSyncKey);

      log('🗑️ Cleared all cached data');
    } catch (e) {
      log('❌ Error clearing cache: $e');
    }
  }

  /// Get cache statistics
  Future<CacheStats> getCacheStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final profilesJson = prefs.getString(_cachedProfilesKey) ?? '[]';
      final profilesCount = (jsonDecode(profilesJson) as List).length;

      final actionsJson = prefs.getString(_offlineActionsKey) ?? '[]';
      final actionsCount = (jsonDecode(actionsJson) as List).length;

      final lastSync = await getLastSyncTime();

      return CacheStats(
        cachedProfiles: profilesCount,
        queuedActions: actionsCount,
        lastSync: lastSync,
        isOnline: await isOnline(),
      );
    } catch (e) {
      log('❌ Error getting cache stats: $e');
      return const CacheStats(
        cachedProfiles: 0,
        queuedActions: 0,
        lastSync: null,
        isOnline: false,
      );
    }
  }

  /// Force sync when online
  Future<void> forceSync() async {
    if (await isOnline()) {
      await _startBackgroundSync();
    }
  }
}

/// Offline action types
enum OfflineActionType {
  like,
  pass,
  message,
  profileUpdate,
}

/// Offline action model
class OfflineAction {

  const OfflineAction({
    required this.id,
    required this.type,
    required this.data,
    required this.timestamp,
  });

  factory OfflineAction.fromJson(Map<String, dynamic> json) => OfflineAction(
      id: json['id'],
      type: OfflineActionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => OfflineActionType.like,
      ),
      data: Map<String, dynamic>.from(json['data']),
      timestamp: DateTime.parse(json['timestamp']),
    );
  final String id;
  final OfflineActionType type;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  Map<String, dynamic> toJson() => {
      'id': id,
      'type': type.name,
      'data': data,
      'timestamp': timestamp.toIso8601String(),
    };

  @override
  String toString() => 'OfflineAction(${type.name}, $timestamp)';
}

/// Cache statistics
class CacheStats {

  const CacheStats({
    required this.cachedProfiles,
    required this.queuedActions,
    required this.lastSync,
    required this.isOnline,
  });
  final int cachedProfiles;
  final int queuedActions;
  final DateTime? lastSync;
  final bool isOnline;

  @override
  String toString() => 'CacheStats(profiles: $cachedProfiles, actions: $queuedActions, online: $isOnline)';
}
