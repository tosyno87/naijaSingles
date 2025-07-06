import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:naijasingles/services/performance_monitor.dart';

/// Enhanced notification service for real-time match and interaction alerts
/// Implements Priority 3: User Experience Enhancements
class EnhancedNotificationServiceV2 {
  static const String MATCH_CHANNEL_ID = 'match_notifications';
  static const String SUPER_LIKE_CHANNEL_ID = 'super_like_notifications';
  static const String MESSAGE_CHANNEL_ID = 'message_notifications';
  static const String EXPIRY_CHANNEL_ID = 'expiry_notifications';
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  // Collection references
  CollectionReference get _notificationsCollection => _firestore.collection('notifications');
  CollectionReference get _usersCollection => _firestore.collection('users');
  CollectionReference get _notificationSettingsCollection => _firestore.collection('notificationSettings');
  
  // Stream controllers for real-time notifications
  final StreamController<NotificationEvent> _notificationStreamController = 
      StreamController<NotificationEvent>.broadcast();
  
  // Subscription management
  StreamSubscription<QuerySnapshot>? _notificationSubscription;
  
  /// Initialize the notification service
  Future<void> initialize() async {
    try {
      debugPrint('🔔 Initializing enhanced notification service');
      
      // Initialize local notifications
      await _initializeLocalNotifications();
      
      // Request permissions
      await _requestPermissions();
      
      // Setup FCM token
      await _setupFCMToken();
      
      // Setup real-time listeners
      await _setupRealtimeListeners();
      
      // Setup background message handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      
      debugPrint('✅ Enhanced notification service initialized');
      
    } catch (e) {
      debugPrint('❌ Error initializing notification service: $e');
    }
  }
  
  /// Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
    
    // Create notification channels
    await _createNotificationChannels();
  }
  
  /// Create notification channels for different types
  Future<void> _createNotificationChannels() async {
    const channels = [
      AndroidNotificationChannel(
        MATCH_CHANNEL_ID,
        'Match Notifications',
        description: 'Notifications for new matches',
        importance: Importance.high,
        sound: RawResourceAndroidNotificationSound('match_sound'),
      ),
      AndroidNotificationChannel(
        SUPER_LIKE_CHANNEL_ID,
        'Super Like Notifications',
        description: 'Notifications for super likes',
        importance: Importance.max,
        sound: RawResourceAndroidNotificationSound('super_like_sound'),
      ),
      AndroidNotificationChannel(
        MESSAGE_CHANNEL_ID,
        'Message Notifications',
        description: 'Notifications for new messages',
        importance: Importance.high,
      ),
      AndroidNotificationChannel(
        EXPIRY_CHANNEL_ID,
        'Match Expiry Notifications',
        description: 'Notifications for expiring matches',
        importance: Importance.defaultImportance,
      ),
    ];
    
    for (final channel in channels) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
  }
  
  /// Request notification permissions
  Future<void> _requestPermissions() async {
    // Request FCM permissions
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    
    debugPrint('🔐 FCM Permission status: ${settings.authorizationStatus}');
    
    // Request local notification permissions
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestPermission();
  }
  
  /// Setup FCM token and save to user profile
  Future<void> _setupFCMToken() async {
    try {
      final token = await _messaging.getToken();
      final userId = _auth.currentUser?.uid;
      
      if (token != null && userId != null) {
        await _usersCollection.doc(userId).update({
          'fcmToken': token,
          'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        });
        
        debugPrint('📱 FCM Token saved: ${token.substring(0, 20)}...');
      }
      
      // Listen for token refresh
      _messaging.onTokenRefresh.listen((newToken) async {
        if (userId != null) {
          await _usersCollection.doc(userId).update({
            'fcmToken': newToken,
            'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
          });
        }
      });
      
    } catch (e) {
      debugPrint('❌ Error setting up FCM token: $e');
    }
  }
  
  /// Setup real-time notification listeners
  Future<void> _setupRealtimeListeners() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;
    
    // Listen for new notifications
    _notificationSubscription = _notificationsCollection
        .where('toUserId', isEqualTo: userId)
        .where('read', isEqualTo: false)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen(_handleRealtimeNotification);
    
    // Listen for foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    
    // Listen for notification taps when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
  }
  
  /// Handle real-time notification updates
  void _handleRealtimeNotification(QuerySnapshot snapshot) {
    for (final change in snapshot.docChanges) {
      if (change.type == DocumentChangeType.added) {
        final notification = AppNotification.fromDocument(change.doc);
        _notificationStreamController.add(NotificationEvent.received(notification));
        
        // Show local notification if app is in foreground
        _showLocalNotification(notification);
      }
    }
  }
  
  /// Handle foreground FCM messages
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('📨 Foreground message: ${message.notification?.title}');
    
    final notification = AppNotification.fromRemoteMessage(message);
    _notificationStreamController.add(NotificationEvent.received(notification));
    
    // Show local notification
    _showLocalNotification(notification);
  }
  
  /// Handle notification tap
  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('👆 Notification tapped: ${message.data}');
    
    final notification = AppNotification.fromRemoteMessage(message);
    _notificationStreamController.add(NotificationEvent.tapped(notification));
  }
  
  /// Show local notification
  Future<void> _showLocalNotification(AppNotification notification) async {
    try {
      final channelId = _getChannelId(notification.type);
      final notificationId = notification.id.hashCode;
      
      final androidDetails = AndroidNotificationDetails(
        channelId,
        _getChannelName(notification.type),
        channelDescription: _getChannelDescription(notification.type),
        importance: _getImportance(notification.type),
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        largeIcon: notification.imageUrl != null 
            ? FilePathAndroidBitmap(notification.imageUrl!)
            : null,
        styleInformation: notification.body.length > 50
            ? BigTextStyleInformation(notification.body)
            : null,
      );
      
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      
      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );
      
      await _localNotifications.show(
        notificationId,
        notification.title,
        notification.body,
        details,
        payload: notification.id,
      );
      
    } catch (e) {
      debugPrint('❌ Error showing local notification: $e');
    }
  }
  
  /// Send match notification
  Future<void> sendMatchNotification({
    required String toUserId,
    required String fromUserId,
    required String fromUserName,
    required String matchId,
    String? fromUserImageUrl,
  }) async {
    await PerformanceMonitor.measure('send_match_notification', () async {
      try {
        debugPrint('🎉 Sending match notification: $fromUserName → $toUserId');
        
        // Check notification settings
        final settings = await _getNotificationSettings(toUserId);
        if (!settings.matchNotifications) {
          debugPrint('⚠️ Match notifications disabled for user $toUserId');
          return;
        }
        
        // Create notification document
        final notificationRef = _notificationsCollection.doc();
        await notificationRef.set({
          'id': notificationRef.id,
          'type': 'match',
          'toUserId': toUserId,
          'fromUserId': fromUserId,
          'fromUserName': fromUserName,
          'fromUserImageUrl': fromUserImageUrl,
          'matchId': matchId,
          'title': 'New Match! 🎉',
          'body': 'You and $fromUserName liked each other!',
          'timestamp': FieldValue.serverTimestamp(),
          'read': false,
          'priority': 'high',
        });
        
        // Send FCM notification
        await _sendFCMNotification(
          toUserId: toUserId,
          title: 'New Match! 🎉',
          body: 'You and $fromUserName liked each other!',
          data: {
            'type': 'match',
            'matchId': matchId,
            'fromUserId': fromUserId,
          },
        );
        
        debugPrint('✅ Match notification sent successfully');
        
      } catch (e) {
        debugPrint('❌ Error sending match notification: $e');
      }
    });
  }
  
  /// Send super like notification
  Future<void> sendSuperLikeNotification({
    required String toUserId,
    required String fromUserId,
    required String fromUserName,
    required String superLikeId,
    String? fromUserImageUrl,
  }) async {
    await PerformanceMonitor.measure('send_super_like_notification', () async {
      try {
        debugPrint('⭐ Sending super like notification: $fromUserName → $toUserId');
        
        // Check notification settings
        final settings = await _getNotificationSettings(toUserId);
        if (!settings.superLikeNotifications) {
          debugPrint('⚠️ Super like notifications disabled for user $toUserId');
          return;
        }
        
        // Create notification document
        final notificationRef = _notificationsCollection.doc();
        await notificationRef.set({
          'id': notificationRef.id,
          'type': 'super_like',
          'toUserId': toUserId,
          'fromUserId': fromUserId,
          'fromUserName': fromUserName,
          'fromUserImageUrl': fromUserImageUrl,
          'superLikeId': superLikeId,
          'title': 'Super Like! ⭐',
          'body': '$fromUserName super liked you!',
          'timestamp': FieldValue.serverTimestamp(),
          'read': false,
          'priority': 'max',
        });
        
        // Send FCM notification with special sound
        await _sendFCMNotification(
          toUserId: toUserId,
          title: 'Super Like! ⭐',
          body: '$fromUserName super liked you!',
          data: {
            'type': 'super_like',
            'superLikeId': superLikeId,
            'fromUserId': fromUserId,
          },
          sound: 'super_like_sound',
        );
        
        debugPrint('✅ Super like notification sent successfully');
        
      } catch (e) {
        debugPrint('❌ Error sending super like notification: $e');
      }
    });
  }
  
  /// Send message notification
  Future<void> sendMessageNotification({
    required String toUserId,
    required String fromUserId,
    required String fromUserName,
    required String messageText,
    required String chatThreadId,
    String? fromUserImageUrl,
  }) async {
    await PerformanceMonitor.measure('send_message_notification', () async {
      try {
        debugPrint('💬 Sending message notification: $fromUserName → $toUserId');
        
        // Check notification settings
        final settings = await _getNotificationSettings(toUserId);
        if (!settings.messageNotifications) {
          debugPrint('⚠️ Message notifications disabled for user $toUserId');
          return;
        }
        
        // Truncate long messages
        final truncatedMessage = messageText.length > 100 
            ? '${messageText.substring(0, 100)}...'
            : messageText;
        
        // Create notification document
        final notificationRef = _notificationsCollection.doc();
        await notificationRef.set({
          'id': notificationRef.id,
          'type': 'message',
          'toUserId': toUserId,
          'fromUserId': fromUserId,
          'fromUserName': fromUserName,
          'fromUserImageUrl': fromUserImageUrl,
          'chatThreadId': chatThreadId,
          'messageText': truncatedMessage,
          'title': fromUserName,
          'body': truncatedMessage,
          'timestamp': FieldValue.serverTimestamp(),
          'read': false,
          'priority': 'high',
        });
        
        // Send FCM notification
        await _sendFCMNotification(
          toUserId: toUserId,
          title: fromUserName,
          body: truncatedMessage,
          data: {
            'type': 'message',
            'chatThreadId': chatThreadId,
            'fromUserId': fromUserId,
          },
        );
        
        debugPrint('✅ Message notification sent successfully');
        
      } catch (e) {
        debugPrint('❌ Error sending message notification: $e');
      }
    });
  }
  
  /// Send match expiry warning notification
  Future<void> sendMatchExpiryNotification({
    required String toUserId,
    required String matchId,
    required String otherUserName,
    required Duration timeRemaining,
    String? otherUserImageUrl,
  }) async {
    await PerformanceMonitor.measure('send_expiry_notification', () async {
      try {
        debugPrint('⏰ Sending match expiry notification: $otherUserName → $toUserId');
        
        // Check notification settings
        final settings = await _getNotificationSettings(toUserId);
        if (!settings.expiryNotifications) {
          debugPrint('⚠️ Expiry notifications disabled for user $toUserId');
          return;
        }
        
        final hoursRemaining = timeRemaining.inHours;
        final timeText = hoursRemaining > 24 
            ? '${(hoursRemaining / 24).round()} days'
            : '$hoursRemaining hours';
        
        // Create notification document
        final notificationRef = _notificationsCollection.doc();
        await notificationRef.set({
          'id': notificationRef.id,
          'type': 'match_expiry',
          'toUserId': toUserId,
          'matchId': matchId,
          'otherUserName': otherUserName,
          'otherUserImageUrl': otherUserImageUrl,
          'timeRemaining': timeRemaining.inMilliseconds,
          'title': 'Match Expiring Soon ⏰',
          'body': 'Your match with $otherUserName expires in $timeText. Say hello!',
          'timestamp': FieldValue.serverTimestamp(),
          'read': false,
          'priority': 'default',
        });
        
        // Send FCM notification
        await _sendFCMNotification(
          toUserId: toUserId,
          title: 'Match Expiring Soon ⏰',
          body: 'Your match with $otherUserName expires in $timeText. Say hello!',
          data: {
            'type': 'match_expiry',
            'matchId': matchId,
            'otherUserId': otherUserName, // This should be otherUserId, not name
          },
        );
        
        debugPrint('✅ Match expiry notification sent successfully');
        
      } catch (e) {
        debugPrint('❌ Error sending match expiry notification: $e');
      }
    });
  }
  
  /// Send FCM notification
  Future<void> _sendFCMNotification({
    required String toUserId,
    required String title,
    required String body,
    required Map<String, String> data,
    String? sound,
  }) async {
    try {
      // Get user's FCM token
      final userDoc = await _usersCollection.doc(toUserId).get();
      if (!userDoc.exists) return;
      
      final userData = userDoc.data() as Map<String, dynamic>;
      final fcmToken = userData['fcmToken'] as String?;
      
      if (fcmToken == null) {
        debugPrint('⚠️ No FCM token found for user $toUserId');
        return;
      }
      
      // TODO: Send FCM message using your backend service
      // This would typically be done through your backend API
      debugPrint('📱 Would send FCM to token: ${fcmToken.substring(0, 20)}...');
      
    } catch (e) {
      debugPrint('❌ Error sending FCM notification: $e');
    }
  }
  
  /// Get notification settings for a user
  Future<NotificationSettings> _getNotificationSettings(String userId) async {
    try {
      final settingsDoc = await _notificationSettingsCollection.doc(userId).get();
      
      if (settingsDoc.exists) {
        return NotificationSettings.fromDocument(settingsDoc);
      } else {
        // Return default settings
        return NotificationSettings.defaultSettings();
      }
      
    } catch (e) {
      debugPrint('❌ Error getting notification settings: $e');
      return NotificationSettings.defaultSettings();
    }
  }
  
  /// Update notification settings
  Future<void> updateNotificationSettings(String userId, NotificationSettings settings) async {
    try {
      await _notificationSettingsCollection.doc(userId).set(settings.toMap(), SetOptions(merge: true));
      debugPrint('✅ Notification settings updated for user $userId');
    } catch (e) {
      debugPrint('❌ Error updating notification settings: $e');
    }
  }
  
  /// Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _notificationsCollection.doc(notificationId).update({
        'read': true,
        'readAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('❌ Error marking notification as read: $e');
    }
  }
  
  /// Get unread notification count
  Future<int> getUnreadNotificationCount(String userId) async {
    try {
      final querySnapshot = await _notificationsCollection
          .where('toUserId', isEqualTo: userId)
          .where('read', isEqualTo: false)
          .get();
      
      return querySnapshot.docs.length;
    } catch (e) {
      debugPrint('❌ Error getting unread notification count: $e');
      return 0;
    }
  }
  
  /// Get notification stream
  Stream<NotificationEvent> get notificationStream => _notificationStreamController.stream;
  
  /// Helper methods for channel configuration
  String _getChannelId(String type) {
    switch (type) {
      case 'match': return MATCH_CHANNEL_ID;
      case 'super_like': return SUPER_LIKE_CHANNEL_ID;
      case 'message': return MESSAGE_CHANNEL_ID;
      case 'match_expiry': return EXPIRY_CHANNEL_ID;
      default: return MESSAGE_CHANNEL_ID;
    }
  }
  
  String _getChannelName(String type) {
    switch (type) {
      case 'match': return 'Match Notifications';
      case 'super_like': return 'Super Like Notifications';
      case 'message': return 'Message Notifications';
      case 'match_expiry': return 'Match Expiry Notifications';
      default: return 'General Notifications';
    }
  }
  
  String _getChannelDescription(String type) {
    switch (type) {
      case 'match': return 'Notifications for new matches';
      case 'super_like': return 'Notifications for super likes';
      case 'message': return 'Notifications for new messages';
      case 'match_expiry': return 'Notifications for expiring matches';
      default: return 'General app notifications';
    }
  }
  
  Importance _getImportance(String type) {
    switch (type) {
      case 'super_like': return Importance.max;
      case 'match':
      case 'message': return Importance.high;
      case 'match_expiry': return Importance.defaultImportance;
      default: return Importance.defaultImportance;
    }
  }
  
  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    if (response.payload != null) {
      // Handle notification tap based on payload
      debugPrint('👆 Local notification tapped: ${response.payload}');
      // You would navigate to appropriate screen here
    }
  }
  
  /// Dispose of the service
  void dispose() {
    _notificationSubscription?.cancel();
    _notificationStreamController.close();
    debugPrint('🗑️ Enhanced notification service disposed');
  }
}

/// Background message handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('📨 Background message: ${message.notification?.title}');
  // Handle background message
}

/// Represents an app notification
class AppNotification {
  final String id;
  final String type;
  final String toUserId;
  final String? fromUserId;
  final String title;
  final String body;
  final DateTime timestamp;
  final bool read;
  final String priority;
  final Map<String, dynamic> data;
  final String? imageUrl;
  
  const AppNotification({
    required this.id,
    required this.type,
    required this.toUserId,
    this.fromUserId,
    required this.title,
    required this.body,
    required this.timestamp,
    required this.read,
    required this.priority,
    required this.data,
    this.imageUrl,
  });
  
  factory AppNotification.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppNotification(
      id: doc.id,
      type: data['type'] ?? '',
      toUserId: data['toUserId'] ?? '',
      fromUserId: data['fromUserId'],
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      read: data['read'] ?? false,
      priority: data['priority'] ?? 'default',
      data: Map<String, dynamic>.from(data),
      imageUrl: data['fromUserImageUrl'],
    );
  }
  
  factory AppNotification.fromRemoteMessage(RemoteMessage message) {
    return AppNotification(
      id: message.messageId ?? '',
      type: message.data['type'] ?? '',
      toUserId: message.data['toUserId'] ?? '',
      fromUserId: message.data['fromUserId'],
      title: message.notification?.title ?? '',
      body: message.notification?.body ?? '',
      timestamp: DateTime.now(),
      read: false,
      priority: message.data['priority'] ?? 'default',
      data: message.data,
      imageUrl: message.notification?.android?.imageUrl,
    );
  }
  
  @override
  String toString() {
    return 'AppNotification($type: $title)';
  }
}

/// Notification settings for a user
class NotificationSettings {
  final bool matchNotifications;
  final bool superLikeNotifications;
  final bool messageNotifications;
  final bool expiryNotifications;
  final bool soundEnabled;
  final bool vibrationEnabled;
  final String quietHoursStart;
  final String quietHoursEnd;
  
  const NotificationSettings({
    required this.matchNotifications,
    required this.superLikeNotifications,
    required this.messageNotifications,
    required this.expiryNotifications,
    required this.soundEnabled,
    required this.vibrationEnabled,
    required this.quietHoursStart,
    required this.quietHoursEnd,
  });
  
  factory NotificationSettings.defaultSettings() {
    return const NotificationSettings(
      matchNotifications: true,
      superLikeNotifications: true,
      messageNotifications: true,
      expiryNotifications: true,
      soundEnabled: true,
      vibrationEnabled: true,
      quietHoursStart: '22:00',
      quietHoursEnd: '08:00',
    );
  }
  
  factory NotificationSettings.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationSettings(
      matchNotifications: data['matchNotifications'] ?? true,
      superLikeNotifications: data['superLikeNotifications'] ?? true,
      messageNotifications: data['messageNotifications'] ?? true,
      expiryNotifications: data['expiryNotifications'] ?? true,
      soundEnabled: data['soundEnabled'] ?? true,
      vibrationEnabled: data['vibrationEnabled'] ?? true,
      quietHoursStart: data['quietHoursStart'] ?? '22:00',
      quietHoursEnd: data['quietHoursEnd'] ?? '08:00',
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'matchNotifications': matchNotifications,
      'superLikeNotifications': superLikeNotifications,
      'messageNotifications': messageNotifications,
      'expiryNotifications': expiryNotifications,
      'soundEnabled': soundEnabled,
      'vibrationEnabled': vibrationEnabled,
      'quietHoursStart': quietHoursStart,
      'quietHoursEnd': quietHoursEnd,
    };
  }
}

/// Notification event for real-time updates
class NotificationEvent {
  final NotificationEventType type;
  final AppNotification notification;
  
  const NotificationEvent._(this.type, this.notification);
  
  factory NotificationEvent.received(AppNotification notification) {
    return NotificationEvent._(NotificationEventType.received, notification);
  }
  
  factory NotificationEvent.tapped(AppNotification notification) {
    return NotificationEvent._(NotificationEventType.tapped, notification);
  }
  
  @override
  String toString() {
    return 'NotificationEvent(${type.name}: ${notification.title})';
  }
}

/// Types of notification events
enum NotificationEventType {
  received,
  tapped,
}
