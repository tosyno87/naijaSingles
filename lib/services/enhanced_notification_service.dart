import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../features/notifications/notification_model.dart';

/// Enhanced notification service with real-time capabilities
class EnhancedNotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;
  static GlobalKey<NavigatorState>? _navigatorKey;

  /// Set navigator key for navigation
  static void setNavigatorKey(GlobalKey<NavigatorState> navigatorKey) {
    _navigatorKey = navigatorKey;
  }

  /// Initialize the enhanced notification service
  static Future<void> initialize() async {
    if (_initialized) return;

    debugPrint('🔔 Initializing Enhanced Notification Service...');

    try {
      // Initialize local notifications
      await _initializeLocalNotifications();

      // Request permissions
      await _requestPermissions();

      // Setup FCM token management
      await _setupFCMToken();

      // Setup message handlers
      _setupMessageHandlers();

      _initialized = true;
      debugPrint('✅ Enhanced Notification Service initialized successfully');
    } catch (e) {
      debugPrint('❌ Error initializing notification service: $e');
    }
  }

  /// Initialize local notifications
  static Future<void> _initializeLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
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

    // Create notification channels for Android
    await _createNotificationChannels();
  }

  /// Create notification channels for different types
  static Future<void> _createNotificationChannels() async {
    const matchChannel = AndroidNotificationChannel(
      'matches',
      'Match Notifications',
      description: 'Notifications for new matches',
      importance: Importance.high,
      sound: RawResourceAndroidNotificationSound('match_sound'),
    );

    const messageChannel = AndroidNotificationChannel(
      'messages',
      'Message Notifications',
      description: 'Notifications for new messages',
      importance: Importance.high,
      sound: RawResourceAndroidNotificationSound('message_sound'),
    );

    const likeChannel = AndroidNotificationChannel(
      'likes',
      'Like Notifications',
      description: 'Notifications for profile likes',
      importance: Importance.defaultImportance,
      sound: RawResourceAndroidNotificationSound('like_sound'),
    );

    const superLikeChannel = AndroidNotificationChannel(
      'super_likes',
      'Super Like Notifications',
      description: 'Notifications for super likes',
      importance: Importance.max,
      sound: RawResourceAndroidNotificationSound('super_like_sound'),
    );

    final androidPlugin =
        _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(matchChannel);
      await androidPlugin.createNotificationChannel(messageChannel);
      await androidPlugin.createNotificationChannel(likeChannel);
      await androidPlugin.createNotificationChannel(superLikeChannel);
    }
  }

  /// Request notification permissions
  static Future<void> _requestPermissions() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    debugPrint(
        '🔔 Notification permission status: ${settings.authorizationStatus}');
  }

  /// Setup FCM token management
  static Future<void> _setupFCMToken() async {
    // Get initial token
    await _updateFCMToken();

    // Listen for token refresh
    _messaging.onTokenRefresh.listen(_updateFCMToken);
  }

  static int _retryCount = 0;
  static const int _maxRetries = 3;

  /// Update FCM token in user document
  static Future<void> _updateFCMToken([String? token]) async {
    try {
      // For iOS, we need to get APNS token first
      if (Platform.isIOS) {
        try {
          final apnsToken = await _messaging.getAPNSToken();
          if (apnsToken == null) {
            if (_retryCount < _maxRetries) {
              _retryCount++;
              debugPrint(
                  '⚠️ APNS token not available yet, retry $_retryCount/$_maxRetries');
              // Retry after a delay with exponential backoff
              Future.delayed(Duration(seconds: 2 * _retryCount),
                  () => _updateFCMToken(token));
              return;
            } else {
              debugPrint(
                  '⚠️ APNS token not available after $_maxRetries retries, skipping (this is normal in simulator)');
              _retryCount = 0; // Reset for future attempts
              // Continue without APNS token for now
            }
          } else {
            debugPrint('✅ APNS token obtained successfully');
            _retryCount = 0; // Reset on success
          }
        } catch (e) {
          debugPrint('⚠️ Error getting APNS token: $e');
          if (_retryCount < _maxRetries) {
            _retryCount++;
            Future.delayed(Duration(seconds: 2 * _retryCount),
                () => _updateFCMToken(token));
            return;
          } else {
            debugPrint(
                '⚠️ APNS token error after $_maxRetries retries, continuing without it');
            _retryCount = 0;
          }
        }
      }

      token ??= await _messaging.getToken();
      if (token == null) {
        debugPrint('⚠️ FCM token is null, skipping update');
        return;
      }

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint('⚠️ No authenticated user, skipping FCM token update');
        return;
      }

      await _firestore
          .collection('users')
          .doc(user.uid)
          .update({'pushToken': token});

      debugPrint(
          '🔑 FCM token updated successfully: ${token.substring(0, 20)}...');
      _retryCount = 0; // Reset on success
    } catch (e) {
      debugPrint('❌ Error updating FCM token: $e');
      _retryCount = 0; // Reset on error
    }
  }

  /// Setup message handlers for real-time notifications
  static void _setupMessageHandlers() {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background message taps
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageTap);

    // Handle app launch from terminated state
    _messaging.getInitialMessage().then((message) {
      if (message != null) {
        _handleMessageTap(message);
      }
    });
  }

  /// Handle foreground messages (show local notification)
  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint(
        '📱 Foreground message received: ${message.notification?.title}');

    final notification = message.notification;
    final data = message.data;

    if (notification == null) return;

    // Show local notification for foreground messages
    await _showLocalNotification(
      title: notification.title ?? 'NaijaSingles',
      body: notification.body ?? '',
      data: data,
    );
  }

  /// Handle message tap (navigate to appropriate screen)
  static Future<void> _handleMessageTap(RemoteMessage message) async {
    debugPrint('👆 Notification tapped: ${message.data}');

    final data = message.data;
    final type = data['type'];

    // Navigate based on notification type
    switch (type) {
      case 'match':
        await _navigateToMatch(data);
        break;
      case 'message':
        await _navigateToChat(data);
        break;
      case 'like':
        await _navigateToProfile(data);
        break;
      case 'super_like':
        await _navigateToProfile(data);
        break;
      default:
        debugPrint('Unknown notification type: $type');
    }
  }

  /// Show local notification
  static Future<void> _showLocalNotification({
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'general',
      'General Notifications',
      importance: Importance.high,
      priority: Priority.high,
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
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      details,
      payload: jsonEncode(data),
    );
  }

  /// Handle notification tap from local notifications
  static void _onNotificationTapped(NotificationResponse response) {
    if (response.payload == null) return;

    try {
      final data = jsonDecode(response.payload!) as Map<String, dynamic>;
      final message = RemoteMessage(data: data);
      _handleMessageTap(message);
    } catch (e) {
      debugPrint('Error handling notification tap: $e');
    }
  }

  /// Navigate to match screen
  static Future<void> _navigateToMatch(Map<String, dynamic> data) async {
    debugPrint('🎉 Navigating to match: ${data['matchedUserName']}');

    final context = _navigatorKey?.currentContext;
    if (context != null) {
      // Navigate to match confirmation screen or chat
      Navigator.pushNamed(
        context,
        '/match_confirmation',
        arguments: {
          'matchedUserId': data['matchedUserId'],
          'matchedUserName': data['matchedUserName'],
          'matchedUserPhoto': data['matchedUserPhoto'],
        },
      );
    } else {
      debugPrint('⚠️ Navigator context not available for match navigation');
    }
  }

  /// Navigate to chat screen
  static Future<void> _navigateToChat(Map<String, dynamic> data) async {
    debugPrint('💬 Navigating to chat: ${data['threadId']}');

    final context = _navigatorKey?.currentContext;
    if (context != null) {
      // Navigate to specific chat thread
      Navigator.pushNamed(
        context,
        '/chat_thread',
        arguments: {
          'threadId': data['threadId'],
          'otherUserId': data['senderId'],
          'otherUserName': data['senderName'],
          'otherUserPhoto': data['senderPhoto'],
        },
      );
    } else {
      debugPrint('⚠️ Navigator context not available for chat navigation');
    }
  }

  /// Navigate to profile screen
  static Future<void> _navigateToProfile(Map<String, dynamic> data) async {
    debugPrint(
        '👤 Navigating to profile: ${data['likerName'] ?? data['senderName']}');

    final context = _navigatorKey?.currentContext;
    if (context != null) {
      // Navigate to user profile
      Navigator.pushNamed(
        context,
        '/user_profile',
        arguments: {
          'userId': data['likerId'] ?? data['senderId'],
          'userName': data['likerName'] ?? data['senderName'],
          'userPhoto': data['likerPhoto'] ?? data['senderPhoto'],
          'isFromNotification': true,
        },
      );
    } else {
      debugPrint('⚠️ Navigator context not available for profile navigation');
    }
  }

  /// Get user's notifications from Firestore (real-time)
  static Stream<List<AppNotification>> getUserNotifications(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AppNotification.fromFirestore(doc))
            .toList());
  }

  /// Get unread notification count (real-time)
  static Stream<int> getUnreadCount(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Mark notification as read
  static Future<void> markNotificationAsRead(
      String userId, String notificationId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      debugPrint('❌ Error marking notification as read: $e');
    }
  }

  /// Mark all notifications as read
  static Future<void> markAllNotificationsAsRead(String userId) async {
    try {
      final batch = _firestore.batch();
      final notifications = await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .get();

      for (final doc in notifications.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
    } catch (e) {
      debugPrint('❌ Error marking all notifications as read: $e');
    }
  }

  /// Test notification (for debugging)
  static Future<void> sendTestNotification() async {
    await _showLocalNotification(
      title: '🧪 Test Notification',
      body: 'This is a test notification from NaijaSingles',
      data: {'type': 'test'},
    );
  }
}
