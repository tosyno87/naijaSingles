import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../notification_model.dart';

/// Consolidated notification service with real-time capabilities
/// Replaces EnhancedNotificationService, EnhancedNotificationServiceV2, and IndustryNotificationService
class NotificationService {
  // Singleton instance for instance-based API
  factory NotificationService() => _instance;
  NotificationService._internal();
  static final NotificationService _instance = NotificationService._internal();

  // Static instances (for static API compatibility)
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;
  static GlobalKey<NavigatorState>? _navigatorKey;

  // Instance-based API (for IndustryNotificationService compatibility)
  String? _currentUserId;
  AppNotificationSettings? _settings;
  StreamSubscription<QuerySnapshot>? _notificationsSubscription;
  final StreamController<List<AppNotification>> _notificationsController =
      StreamController<List<AppNotification>>.broadcast();
  final StreamController<int> _unreadCountController =
      StreamController<int>.broadcast();

  /// Set navigator key for navigation
  static void setNavigatorKey(GlobalKey<NavigatorState> navigatorKey) {
    _navigatorKey = navigatorKey;
  }

  /// Initialize the notification service - Static API
  static Future<void> initialize() async {
    if (_initialized) return;

    debugPrint('🔔 Initializing Notification Service...');

    try {
      // Initialize local notifications
      await _initializeLocalNotifications();

      // Request permissions
      await _requestPermissions();

      // Setup FCM token management
      await _setupFCMToken();

      // Setup message handlers
      unawaited(_setupMessageHandlers());
      // Initialize instance-based API
      _instance._currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (_instance._currentUserId != null) {
        await _instance._loadUserSettings();
        _instance._startNotificationListener();
      }

      // Listen for auth changes
      FirebaseAuth.instance.authStateChanges().listen((user) {
        _instance._currentUserId = user?.uid;
        if (_instance._currentUserId != null) {
          _instance._startNotificationListener();
        } else {
          unawaited(
            _instance._notificationsSubscription?.cancel() ??
                Future<void>.value(),
          );
          _instance._notificationsController.add([]);
          _instance._unreadCountController.add(0);
        }
      });

      _initialized = true;
      debugPrint('✅ Notification Service initialized successfully');
    } on Object catch (e) {
      debugPrint('❌ Error initializing notification service: $e');
    }
  }

  /// Initialize local notifications
  static Future<void> _initializeLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();

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
    final settings = await _messaging.requestPermission();

    debugPrint(
      '🔔 Notification permission status: ${settings.authorizationStatus}',
    );
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
                '⚠️ APNS token not available yet, retry $_retryCount/$_maxRetries',
              );
              // Retry after a delay with exponential backoff
              Future.delayed(
                Duration(seconds: 2 * _retryCount),
                () => _updateFCMToken(token),
              );
              return;
            } else {
              debugPrint(
                '⚠️ APNS token not available after $_maxRetries retries, skipping (this is normal in simulator)',
              );
              _retryCount = 0; // Reset for future attempts
              // Continue without APNS token for now
            }
          } else {
            debugPrint('✅ APNS token obtained successfully');
            _retryCount = 0; // Reset on success
          }
        } on Object catch (e) {
          debugPrint('⚠️ Error getting APNS token: $e');
          if (_retryCount < _maxRetries) {
            _retryCount++;
            Future.delayed(
              Duration(seconds: 2 * _retryCount),
              () => _updateFCMToken(token),
            );
            return;
          } else {
            debugPrint(
              '⚠️ APNS token error after $_maxRetries retries, continuing without it',
            );
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
        '🔑 FCM token updated successfully: ${token.substring(0, 20)}...',
      );
      _retryCount = 0; // Reset on success
    } on Object catch (e) {
      debugPrint('❌ Error updating FCM token: $e');
      _retryCount = 0; // Reset on error
    }
  }

  /// Setup message handlers for real-time notifications
  static Future<void> _setupMessageHandlers() async {
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageTap);

    final message = await _messaging.getInitialMessage();
    if (message != null) {
      await _handleMessageTap(message);
    }
  }

  /// Handle foreground messages (show local notification)
  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint(
      '📱 Foreground message received: ${message.notification?.title}',
    );

    final notification = message.notification;
    final data = message.data;

    if (notification == null) return;

    // Show local notification for foreground messages
    await _showLocalNotification(
      title: notification.title ?? 'Afropeep',
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
      case 'superLike':
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
      unawaited(_handleMessageTap(message));
    } on Object catch (e) {
      debugPrint('Error handling notification tap: $e');
    }
  }

  /// Navigate to match screen
  static Future<void> _navigateToMatch(Map<String, dynamic> data) async {
    debugPrint('🎉 Navigating to match: ${data['matchedUserName']}');

    final context = _navigatorKey?.currentContext;
    if (context != null) {
      // Navigate to match confirmation screen or chat
      await Navigator.pushNamed(
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
      await Navigator.pushNamed(
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
      '👤 Navigating to profile: ${data['likerName'] ?? data['senderName']}',
    );

    final context = _navigatorKey?.currentContext;
    if (context != null) {
      // Navigate to user profile
      await Navigator.pushNamed(
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

  /// Get user's notifications from Firestore (real-time) - Static API
  static Stream<List<AppNotification>> getUserNotifications(String userId) =>
      _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .orderBy('timestamp', descending: true)
          .limit(50)
          .snapshots()
          .map(
            (snapshot) =>
                snapshot.docs.map(AppNotification.fromFirestore).toList(),
          );

  /// Get unread notification count (real-time) - Static API
  static Stream<int> getUnreadCount(String userId) => _firestore
      .collection('users')
      .doc(userId)
      .collection('notifications')
      .where('isRead', isEqualTo: false)
      .snapshots()
      .map((snapshot) => snapshot.docs.length);

  /// Start listening to notifications (instance-based API)
  void _startNotificationListener() {
    if (_currentUserId == null) return;

    unawaited(_notificationsSubscription?.cancel() ?? Future<void>.value());
    _notificationsSubscription = _firestore
        .collection('notifications')
        .where('userId', isEqualTo: _currentUserId)
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .listen(
      (snapshot) {
        final notifications =
            snapshot.docs.map(AppNotification.fromFirestore).toList();
        _notificationsController.add(notifications);

        final unreadCount = notifications.where((n) => !n.isRead).length;
        _unreadCountController.add(unreadCount);
      },
      onError: (Object error) {
        debugPrint(
          '⚠️ Notification listener error (index may be missing): $error',
        );
        _notificationsController.add([]);
        _unreadCountController.add(0);
      },
    );
  }

  /// Stream of notifications (instance-based API)
  Stream<List<AppNotification>> get notificationsStream =>
      _notificationsController.stream;

  /// Stream of unread count (instance-based API)
  Stream<int> get unreadCountStream => _unreadCountController.stream;

  /// Mark notification as read - Static API
  static Future<void> markNotificationAsRead(
    String userId,
    String notificationId,
  ) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } on Object catch (e) {
      debugPrint('❌ Error marking notification as read: $e');
    }
  }

  /// Mark notification as read - Instance API
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } on Object catch (e) {
      debugPrint('❌ Error marking notification as read: $e');
    }
  }

  /// Mark all notifications as read - Static API
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
    } on Object catch (e) {
      debugPrint('❌ Error marking all notifications as read: $e');
    }
  }

  /// Mark all notifications as read - Instance API
  Future<void> markAllAsRead() async {
    if (_currentUserId == null) return;

    try {
      final batch = _firestore.batch();
      final query = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: _currentUserId)
          .where('isRead', isEqualTo: false)
          .get();

      for (final doc in query.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
    } on Object catch (e) {
      debugPrint('❌ Error marking all notifications as read: $e');
    }
  }

  /// Delete notification - Instance API
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();
    } on Object catch (e) {
      debugPrint('❌ Error deleting notification: $e');
    }
  }

  /// Load user notification settings
  Future<void> _loadUserSettings() async {
    if (_currentUserId == null) return;

    try {
      final doc = await _firestore
          .collection('notification_settings')
          .doc(_currentUserId)
          .get();

      if (doc.exists) {
        _settings = AppNotificationSettings.fromFirestore(doc);
      } else {
        _settings = AppNotificationSettings.defaultSettings();
        await _saveUserSettings();
      }
    } on Object catch (e) {
      debugPrint('Error loading notification settings: $e');
      _settings = AppNotificationSettings.defaultSettings();
    }
  }

  /// Save user notification settings
  Future<void> _saveUserSettings() async {
    if (_currentUserId == null || _settings == null) return;

    try {
      await _firestore
          .collection('notification_settings')
          .doc(_currentUserId)
          .set(_settings!.toFirestore());
    } on Object catch (e) {
      debugPrint('Error saving notification settings: $e');
    }
  }

  /// Update notification settings - Instance API
  Future<void> updateSettings(AppNotificationSettings settings) async {
    _settings = settings;
    await _saveUserSettings();
  }

  /// Test notification (for debugging)
  static Future<void> sendTestNotification() async {
    await _showLocalNotification(
      title: '🧪 Test Notification',
      body: 'This is a test notification from Afropeep',
      data: {'type': 'test'},
    );
  }
}
